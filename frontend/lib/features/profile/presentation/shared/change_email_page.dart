import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rijiki/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:rijiki/features/auth/presentation/widgets/otp_input_field.dart';
import 'package:rijiki/shared/widgets/app_button.dart';
import 'package:rijiki/shared/widgets/app_text_field.dart';

/// Halaman "Ganti email" yang dipakai semua role.
/// Langkah 1: email baru + kata sandi. Langkah 2: kode OTP ke email baru.
class ChangeEmailPage extends ConsumerStatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  ConsumerState<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends ConsumerState<ChangeEmailPage> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  Timer? _timer;
  int _secondsLeft = 0;
  bool _codeSent = false;
  String _pendingEmail = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.invalidate(authControllerProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = AppConstants.otpResendCooldown.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft = _secondsLeft > 0 ? _secondsLeft - 1 : 0);
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (ref.read(authControllerProvider).isLoading) return;
    FocusScope.of(context).unfocus();

    final newEmail = _email.text.trim();
    final ok = await ref
        .read(authControllerProvider.notifier)
        .requestEmailChange(newEmail: newEmail, password: _password.text);
    if (!mounted || !ok) return;

    setState(() {
      _codeSent = true;
      _pendingEmail = newEmail;
    });
    _code.clear();
    _startTimer();
  }

  Future<void> _resend() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .requestEmailChange(newEmail: _pendingEmail, password: _password.text);
    if (ok && mounted) _startTimer();
  }

  Future<void> _confirm() async {
    if (_code.text.length != AppConstants.otpLength) return;
    if (ref.read(authControllerProvider).isLoading) return;
    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(authControllerProvider.notifier)
        .confirmEmailChange(newEmail: _pendingEmail, code: _code.text);
    if (!mounted) return;
    if (!ok) {
      _code.clear();
      return;
    }
    _toast('Email berhasil diganti.');
    context.pop();
  }

  void _backToForm() {
    _timer?.cancel();
    _code.clear();
    ref.invalidate(authControllerProvider);
    setState(() {
      _codeSent = false;
      _secondsLeft = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;
    final currentEmail = ref.watch(sessionProvider)?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ganti email')),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (!isLoading && state.hasError) ...[
                AuthErrorBanner(message: Failure.messageOf(state.error!)),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_codeSent)
                _buildCodeStep(isLoading, state.hasError)
              else
                _buildFormStep(isLoading, currentEmail),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormStep(bool isLoading, String currentEmail) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Email saat ini: $currentEmail',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _email,
            label: 'Email baru',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            enabled: !isLoading,
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return 'Email baru wajib diisi.';
              if (!_emailRegex.hasMatch(text)) return 'Format email tidak valid.';
              if (text.toLowerCase() == currentEmail.toLowerCase()) {
                return 'Email baru sama dengan email saat ini.';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _password,
            label: 'Kata sandi',
            hint: 'Untuk memastikan ini benar-benar kamu',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            enabled: !isLoading,
            onFieldSubmitted: (_) => _sendCode(),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Kata sandi wajib diisi.'
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Kirim kode verifikasi',
            isLoading: isLoading,
            onPressed: _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep(bool isLoading, bool hasError) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Masukkan kode ${AppConstants.otpLength} digit yang dikirim ke $_pendingEmail.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        OtpInputField(
          controller: _code,
          enabled: !isLoading,
          hasError: !isLoading && hasError,
          onCompleted: (_) => _confirm(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: AppStrings.verifyButton,
          isLoading: isLoading,
          onPressed: _confirm,
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
          onPressed: isLoading ? null : _backToForm,
          child: const Text('Pakai email lain'),
        ),
      ],
    );
  }
}