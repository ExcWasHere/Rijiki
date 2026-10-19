import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.value, this.size = 16});

  final double value;
  final double size;

  static const Color _gold = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    final rounded = (value * 2).round() / 2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rounded >= i
                ? Icons.star_rounded
                : (rounded >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            size: size,
            color: _gold,
          ),
      ],
    );
  }
}
