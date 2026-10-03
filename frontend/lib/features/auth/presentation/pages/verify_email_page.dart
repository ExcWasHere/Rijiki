import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rijiki/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:rijiki/features/auth/presentation/widgets/auth_header.dart';
import 'package:rijiki/features/auth/presentation/widgets/otp_input_field.dart';
import 'package:rijiki/shared/widgets/app_button.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final _codeController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = AppConstants.otpResendCooldown.inSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft = _secondsLeft > 0 ? _secondsLeft - 1 : 0);
    });
  }

  Future<void> _verify() async {
    if (_codeController.text.length != AppConstants.otpLength) return;
    if (ref.read(authControllerProvider).isLoading) return;
    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyEmail(email: widget.email, code: _codeController.text);
    if (!ok && mounted) _codeController.clear();
  }

  Future<void> _resend() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resendVerification(email: widget.email);

    if (ok && mounted) {
      setState(() => _secondsLeft = AppConstants.otpResendCooldown.inSeconds);
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              AuthHeader(
                title: AppStrings.verifyTitle,
                subtitle: '${AppStrings.verifySubtitle} ${widget.email}',
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!isLoading && state.hasError) ...[
                AuthErrorBanner(message: Failure.messageOf(state.error!)),
                const SizedBox(height: AppSpacing.md),
              ],
              OtpInputField(
                controller: _codeController,
                enabled: !isLoading,
                hasError: !isLoading && state.hasError,
                onCompleted: (_) => _verify(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: AppStrings.verifyButton,
                isLoading: isLoading,
                onPressed: _verify,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: _secondsLeft > 0
                    ? Text(AppStrings.resendCountdown(_secondsLeft))
                    : TextButton(
                        onPressed: isLoading ? null : _resend,
                        child: const Text(AppStrings.resendButton),
                      ),
              ),
              TextButton(
                onPressed: isLoading ? null : () => context.go(RoutePaths.register),
                child: const Text(AppStrings.changeEmail),
              ),
            ],
          ),
        ),
      ),
    );
  }
}