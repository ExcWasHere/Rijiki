import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rijiki/core/constants/asset_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';

class TypewriterChatBubble extends StatefulWidget {
  final String text;
  final Duration typingSpeed;

  const TypewriterChatBubble({
    super.key,
    required this.text,
    this.typingSpeed = const Duration(milliseconds: 40),
  });

  @override
  State<TypewriterChatBubble> createState() => _TypewriterChatBubbleState();
}

class _TypewriterChatBubbleState extends State<TypewriterChatBubble> {
  String _displayedText = '';
  Timer? _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant TypewriterChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    setState(() {
      _displayedText = '';
      _charIndex = 0;
    });

    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (_charIndex < widget.text.length) {
        if (mounted) {
          setState(() {
            _charIndex++;
            _displayedText = widget.text.substring(0, _charIndex);
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.rijikiBlue.withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _displayedText,
              maxLines: 3,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                height: 1.35,
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.rijikiBlue.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Image.asset(
                AssetPaths.rijikiLogo,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.dry_cleaning_rounded,
                  size: 20,
                  color: AppColors.rijikiBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
