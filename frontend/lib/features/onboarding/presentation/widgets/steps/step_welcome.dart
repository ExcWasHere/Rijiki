import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/constants/asset_paths.dart';

class StepWelcome extends StatelessWidget {
  const StepWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Illustration placeholder matching design
        Container(
          height: 220,
          width: double.infinity,
          alignment: Alignment.center,
          child: Image.asset(
            AssetPaths.onboardingWelcome,
            width: 320,
            height: 320,
            fit: BoxFit.contain,
          ),
        ),
        const Spacer(),
        const Text(
          'Sepatu Fresh,\nGaya Makin Kece.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Perawatan sepatu profesional untuk menjaga sepatu kesayanganmu tetap bersih, segar, dan siap dipakai kapan saja.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
