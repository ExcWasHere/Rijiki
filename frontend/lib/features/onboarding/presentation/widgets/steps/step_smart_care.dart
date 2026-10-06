import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/constants/asset_paths.dart';

class StepSmartCare extends StatelessWidget {
  const StepSmartCare({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Illustration matching design (Shoe + Phone UI)
        Container(
          height: 220,
          width: double.infinity,
          alignment: Alignment.center,
          child: Image.asset(
            AssetPaths.onboardingshoeCare,
            width: 420,
            height: 420,
            fit: BoxFit.contain,
          ),
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Solusi & Perawatan Sepatu Terbaik',
            // 'Smart Shoe Care\n& Treatment\nRecommendation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Text(
            'Jaga sepatu kesayanganmu selalu dalam kondisi prima dengan perawatan yang paling pas.',
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
