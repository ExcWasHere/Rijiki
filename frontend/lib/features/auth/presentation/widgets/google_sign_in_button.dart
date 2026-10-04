import 'package:flutter/material.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/auth/presentation/widgets/google_logo.dart';

const Color _googleSurface = Color(0xFFFFFFFF);
const Color _googleStroke = Color(0xFF747775);
const Color _googleText = Color(0xFF1F1F1F);

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return OutlinedButton(
      onPressed: enabled ? (isLoading ? () {} : onPressed) : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: _googleSurface,
        foregroundColor: _googleText,
        disabledBackgroundColor: _googleSurface,
        disabledForegroundColor: _googleText.withValues(alpha: 0.38),
        side: BorderSide(
          color: enabled ? _googleStroke : _googleStroke.withValues(alpha: 0.38),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: AppSpacing.iconMd,
              height: AppSpacing.iconMd,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _googleText,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: enabled ? 1 : 0.38,
                  child: const GoogleLogo(size: 20),
                ),
                const SizedBox(width: AppSpacing.md - AppSpacing.xs),
                Text(
                  AppStrings.continueWithGoogle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: enabled
                            ? _googleText
                            : _googleText.withValues(alpha: 0.38),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
    );
  }
}
