import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/shared/widgets/app_card.dart';

class StateCard extends StatelessWidget {
  const StateCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}
