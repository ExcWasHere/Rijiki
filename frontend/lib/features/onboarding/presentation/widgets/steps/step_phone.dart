import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/background_decorations.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/typewriter_chat_bubble.dart';

class StepPhone extends ConsumerWidget {
  const StepPhone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final keyboardOffset = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        // 1. Top-Right Cyan Circle flush to screen edge
        const Positioned(
          right: -30,
          top: -20,
          child: CyanCircleDecoration(
            width: 140,
            height: 140,
          ),
        ),

        // 2. Left Orange Blob flush to physical left edge (left: 0)
        const Positioned(
          left: 0,
          top: 220,
          child: LeftOrangeBlobDecoration(
            width: 170,
            height: 270,
          ),
        ),

        // 3. Decorative Cyan Triangles on bottom right
        Positioned(
          right: 20,
          bottom: 30,
          child: Column(
            children: [
              Row(
                children: [
                  _buildTriangleIcon(16, 0.4),
                  const SizedBox(width: 8),
                  _buildTriangleIcon(24, 0.5),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildTriangleIcon(20, 0.4),
                  const SizedBox(width: 6),
                  _buildTriangleIcon(18, 0.5),
                ],
              ),
            ],
          ),
        ),

        // Main Foreground Content
        SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                // Inline Header Branding
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Rijiki ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: 'x ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rijikiOrange,
                        ),
                      ),
                      TextSpan(
                        text: 'TaTuTi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Titip Kontak\nDulu, Ya!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 42),

                // Typewriter animated chat bubble
                const TypewriterChatBubble(
                  text:
                      'Boleh dong tau nomor HP-mu, biar Rijiki gampang nyapa atau ngabarin kamu nanti!',
                ),
                const SizedBox(height: 350),

                // Phone Input field with +62 badge
                Transform.translate(
                  offset: Offset(0, -keyboardOffset),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  child: Row(
                    children: [
                      // +62 Country Code Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.rijikiBlue,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '+62',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      // Text input
                      Expanded(
                        child: TextFormField(
                          initialValue: state.phone,
                          keyboardType: TextInputType.phone,
                          onChanged: controller.updatePhone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                          decoration: const InputDecoration(
                            hintText: '8123456789',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFA0A0A0),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFFCCCCCC),
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              borderSide: BorderSide(
                                color: AppColors.rijikiBlue,
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriangleIcon(double size, double opacity) {
    return Icon(
      Icons.change_history_rounded,
      size: size,
      color: const Color(0xFFAEE1E1).withValues(alpha: opacity),
    );
  }
}
