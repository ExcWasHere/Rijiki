import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

abstract final class RijikiContact {
  static const String whatsapp = '081330506652';
  static const String email = 'excellchristian12@gmail.com';
  static const String instagram = '@_exczxz';
  static const String operatingHours = '07:00 - 19:00';
}

Future<void> showContactSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (_) => const _ContactSheet(),
  );
}

class _ContactSheet extends StatelessWidget {
  const _ContactSheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hubungi Rijiki', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ketuk kontak untuk menyalinnya.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _ContactTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'WhatsApp',
              value: RijikiContact.whatsapp,
            ),
            const _ContactTile(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: RijikiContact.email,
            ),
            const _ContactTile(
              icon: Icons.camera_alt_outlined,
              label: 'Instagram',
              value: RijikiContact.instagram,
            ),
            const _ContactTile(
              icon: Icons.schedule_rounded,
              label: 'Jam operasional',
              value: RijikiContact.operatingHours,
              copyable: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('$label disalin')));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
      title: Text(label),
      subtitle: Text(value),
      trailing: copyable
          ? const Icon(Icons.copy_rounded, size: AppSpacing.iconSm)
          : null,
      onTap: copyable ? () => _copy(context) : null,
    );
  }
}