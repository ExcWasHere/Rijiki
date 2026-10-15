import 'package:flutter/material.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';

class AnimatedRupiah extends StatelessWidget {
  const AnimatedRupiah({
    super.key,
    required this.value,
    this.style,
    this.compact = false,
  });

  final double value;
  final TextStyle? style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => Text(
        compact
            ? RupiahFormatter.compact(animated)
            : RupiahFormatter.full(animated),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
