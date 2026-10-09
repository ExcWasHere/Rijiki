import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/background_decorations.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/typewriter_chat_bubble.dart';

class StepName extends ConsumerWidget {
  const StepName({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final keyboardOffset = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        // 1. Top-Left Cyan Circle cut off at top-left corner
        const Positioned(
          left: -35,
          top: -35,
          child: CyanCircleDecoration(width: 160, height: 160),
        ),

        // 2. Left Orange Blob flush to physical left edge (left: 0)
        const Positioned(
          left: 0,
          top: 220,
          child: LeftOrangeBlobDecoration(width: 170, height: 270),
        ),

        // 3. Bottom-Right Cyan Circle behind text field flush to right edge
        const Positioned(
          right: -40,
          bottom: 110,
          child: CyanCircleDecoration(width: 170, height: 170),
        ),

        // Main Foreground Content Layout
        SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                // Inline Header Branding matching Figma
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
                  'Kenalan\ndulu yuk!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                const Text(
                  'Agar Rijiki bisa bantu kamu lebih baik.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 42),

                // Typewriter animated chat bubble
                const TypewriterChatBubble(
                  text: 'Hai sobat rijiki, kamu biasa dipanggil siapa?',
                ),
                const SizedBox(height: 320),

                // Rounded Pill Name Input Field
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
                    child: TextFormField(
                      initialValue: state.name,
                      onChanged: controller.updateName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ketikkan nama',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFA0A0A0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Color(0xFFCCCCCC),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: AppColors.rijikiBlue,
                            width: 1.8,
                          ),
                        ),
                      ),
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
}
