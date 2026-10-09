import 'dart:ui' show FontFeature;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';

class PaymentCountdown extends StatefulWidget {
  const PaymentCountdown({
    super.key,
    required this.expiresAt,
    required this.lifetime,
    required this.onExpired,
  });

  final DateTime expiresAt;
  final Duration lifetime;
  final VoidCallback onExpired;

  @override
  State<PaymentCountdown> createState() => _PaymentCountdownState();
}

class _PaymentCountdownState extends State<PaymentCountdown> {
  Timer? _timer;
  late Duration _remaining = _computeRemaining();
  bool _expiredNotified = false;

  Duration _computeRemaining() {
    final value = widget.expiresAt.difference(DateTime.now());
    return value.isNegative ? Duration.zero : value;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _remaining = _computeRemaining());
    if (_remaining == Duration.zero && !_expiredNotified) {
      _expiredNotified = true;
      widget.onExpired();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _label {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = widget.lifetime.inSeconds;
    final progress = total == 0 ? 0.0 : _remaining.inSeconds / total;
    final isLow = _remaining.inSeconds <= 60;
    final color = isLow ? AppColors.error : AppColors.primaryDark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Selesaikan pembayaran dalam',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              _label,
              style: textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0).toDouble(),
          minHeight: 6,
          color: color,
          backgroundColor: AppColors.outline.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
