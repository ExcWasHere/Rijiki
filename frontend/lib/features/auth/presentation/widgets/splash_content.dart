import 'package:flutter/material.dart';
import '/../core/constants/app_constants.dart';
import '/../core/constants/app_strings.dart';
import '/../core/constants/asset_paths.dart';
import '/../core/theme/app_colors.dart';

class SplashContent extends StatefulWidget {
  const SplashContent({super.key});

  @override
  State<SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<SplashContent>
    with SingleTickerProviderStateMixin {
  static const _letters = ['R', 'I', 'J', 'I', 'K', 'I'];

  late final AnimationController _controller;
  late final Animation<double> _iconAnim;
  late final List<Animation<double>> _letterAnims;
  late final Animation<double> _taglineAnim;

  Animation<double> _stage(double start, double end, {Curve curve = Curves.easeOutCubic}) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: curve),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.splashStageDuration,
    )..forward();

    _iconAnim = _stage(0.0, 0.28, curve: Curves.easeOutBack);

    const letterStart = 0.30;
    const letterStep = 0.09;
    _letterAnims = List.generate(_letters.length, (i) {
      final start = letterStart + i * letterStep;
      return _stage(start, start + 0.22, curve: Curves.easeOutBack);
    });

    final lastLetterEnd = letterStart + (_letters.length - 1) * letterStep + 0.22;
    _taglineAnim = _stage(lastLetterEnd, (lastLetterEnd + 0.18).clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _iconAnim,
              child: ScaleTransition(
                scale: _iconAnim,
                child: Image.asset(
                  AssetPaths.rijikiIcon,
                  width: 84,
                  height: 84,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.home_rounded,
                    size: 72,
                    color: AppColors.rijikiBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_letters.length, (i) {
                return FadeTransition(
                  opacity: _letterAnims[i],
                  child: ScaleTransition(
                    scale: _letterAnims[i],
                    child: Text(
                      _letters[i],
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.rijikiOrange,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 2),
            FadeTransition(
              opacity: _taglineAnim,
              child: Text(
                AppStrings.appTagline,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .5,
                  color: AppColors.rijikiBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}