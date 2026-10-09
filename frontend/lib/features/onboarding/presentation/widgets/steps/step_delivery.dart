import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/constants/asset_paths.dart';

class StepDelivery extends StatelessWidget {
  const StepDelivery({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Illustration matching design (Delivery + Map Location Pin + Package Box)
        Container(
          height: 220,
          width: double.infinity,
          alignment: Alignment.center,
          child: Image.asset(
            AssetPaths.onboardingDelivery,
            width: 420,
            height: 520,
            fit: BoxFit.contain,
          ),
        ),
        const Spacer(),
        const Text(
          'Bersih, Wangi, Langsung Diantar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Text(
            'Nikmati kemudahan terima beres, sepatu bersihmu akan langsung diantar sampai depan pintu rumah.',
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
