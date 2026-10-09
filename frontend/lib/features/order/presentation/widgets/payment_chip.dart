import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/shared/widgets/status_chip.dart';

class PaymentChip extends StatelessWidget {
  const PaymentChip({super.key, required this.paid});

  final bool paid;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: paid ? 'Lunas' : 'Belum dibayar',
      color: paid ? AppColors.success : AppColors.warning,
    );
  }
}
