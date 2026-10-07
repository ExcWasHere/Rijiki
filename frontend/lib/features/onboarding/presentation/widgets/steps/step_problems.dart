import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/problem_card_tile.dart';

class StepProblems extends ConsumerWidget {
  const StepProblems({super.key});

  static const List<String> problemsList = [
    'Kotor',
    'Bau tidak sedap',
    'Noda',
    'Jamur',
    'Perlu perawatan khusus',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Apa masalah pada\nsepatu kamu?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih satu atau lebih yang sesuai.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 28),
          ...problemsList.map(
            (problem) => ProblemCardTile(
              label: problem,
              isSelected: state.selectedProblems.contains(problem),
              onTap: () => controller.toggleProblem(problem),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
