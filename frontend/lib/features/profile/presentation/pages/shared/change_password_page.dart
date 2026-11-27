import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rijiki/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:rijiki/shared/widgets/app_button.dart';
import 'package:rijiki/shared/widgets/app_text_field.dart';

/// Halaman "Ganti kata sandi" yang dipakai semua role.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  static const int _minLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Buang sisa error dari halaman lain.
    Future.microtask(() {
      if (mounted) ref.invalidate(authControllerProvider);
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (ref.read(authControllerProvider).isLoading) return;
    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(authControllerProvider.notifier)
        .changePassword(currentPassword: _current.text, newPassword: _new.text);
    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Kata sandi berhasil diganti.')),
      );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ganti kata sandi')),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (!isLoading && state.hasError) ...[
                  AuthErrorBanner(message: Failure.messageOf(state.error!)),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  controller: _current,
                  label: 'Kata sandi saat ini',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  enabled: !isLoading,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Kata sandi saat ini wajib diisi.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _new,
                  label: 'Kata sandi baru',
                  hint: 'Minimal $_minLength karakter',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !isLoading,
                  validator: (value) {
                    final text = value ?? '';
                    if (text.isEmpty) return 'Kata sandi baru wajib diisi.';
                    if (text.length < _minLength) {
                      return 'Minimal $_minLength karakter.';
                    }
                    if (text == _current.text) {
                      return 'Kata sandi baru harus berbeda dari yang lama.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _confirm,
                  label: 'Ulangi kata sandi baru',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !isLoading,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) => value != _new.text
                      ? 'Kata sandi tidak sama.'
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    top: AppSpacing.sm,
                  ),
                  child: Text(
                    'Setelah diganti, kamu tetap masuk di perangkat ini.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Simpan kata sandi',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}