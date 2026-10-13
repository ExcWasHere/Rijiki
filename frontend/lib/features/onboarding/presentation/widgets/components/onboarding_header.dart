import 'package:flutter/material.dart';

class OnboardingHeader extends StatelessWidget {
  final int currentPage;

  const OnboardingHeader({
    super.key,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
