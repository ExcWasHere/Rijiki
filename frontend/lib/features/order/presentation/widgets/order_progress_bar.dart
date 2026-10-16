import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';

class OrderProgressBar extends StatelessWidget {
  const OrderProgressBar({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final step = status.progressStep;
    const count = OrderStatusUi.progressStepCount;

    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(right: i == count - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: i <= step
                    ? status.color
                    : AppColors.outline.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}
