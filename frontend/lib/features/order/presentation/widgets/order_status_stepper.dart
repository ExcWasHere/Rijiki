import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';

enum _StepState { done, current, pending, cancelled }

class _Step {
  const _Step(this.status, this.state, this.at, this.note);

  final OrderStatus status;
  final _StepState state;
  final DateTime? at;
  final String? note;
}

class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({super.key, required this.order});

  final CustomerOrder order;

  static const List<OrderStatus> _flow = [
    OrderStatus.order,
    OrderStatus.pickup,
    OrderStatus.waiting,
    OrderStatus.cleaning,
    OrderStatus.delivery,
    OrderStatus.completed,
  ];

  List<_Step> _buildSteps() {
    if (order.status == OrderStatus.cancelled) {
      final reached = <OrderStatus>[];
      for (final entry in order.statusHistory) {
        if (entry.status != OrderStatus.cancelled &&
            !reached.contains(entry.status)) {
          reached.add(entry.status);
        }
      }
      final cancelledEntry = order.statusHistory
          .where((entry) => entry.status == OrderStatus.cancelled)
          .firstOrNull;
      return [
        for (final status in reached)
          _Step(status, _StepState.done, order.timeOf(status), null),
        _Step(
          OrderStatus.cancelled,
          _StepState.cancelled,
          cancelledEntry?.changedAt,
          cancelledEntry?.note,
        ),
      ];
    }

    final current = order.status.progressStep;
    return [
      for (var i = 0; i < _flow.length; i++)
        _Step(
          _flow[i],
          i < current || (i == current && order.status == OrderStatus.completed)
              ? _StepState.done
              : i == current
              ? _StepState.current
              : _StepState.pending,
          order.timeOf(_flow[i]),
          null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final _Step step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPending = step.state == _StepState.pending;
    final isCurrent = step.state == _StepState.current;
    final lineColor = step.state == _StepState.done
        ? AppColors.primaryDark
        : AppColors.outline.withValues(alpha: 0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                _Node(step: step),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22, top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.status.label,
                    style: textTheme.titleSmall?.copyWith(
                      color: isPending
                          ? AppColors.onSurfaceVariant
                          : AppColors.onSurface,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (step.at != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.dateTime(step.at!),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (isCurrent) ...[
                    const SizedBox(height: 4),
                    Text(step.status.hint, style: textTheme.bodyMedium),
                  ],
                  if (step.note != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.note!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.step});

  final _Step step;

  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    switch (step.state) {
      case _StepState.done:
        final isFinal = step.status == OrderStatus.completed;
        return _circle(
          color: isFinal ? AppColors.success : AppColors.primaryDark,
          child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
        );
      case _StepState.cancelled:
        return _circle(
          color: AppColors.error,
          child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
        );
      case _StepState.current:
        return _PulsingNode(icon: step.status.icon);
      case _StepState.pending:
        return Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
          ),
          child: Icon(
            step.status.icon,
            size: 16,
            color: AppColors.outline.withValues(alpha: 0.8),
          ),
        );
    }
  }

  Widget _circle({required Color color, required Widget child}) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
  }
}

class _PulsingNode extends StatefulWidget {
  const _PulsingNode({required this.icon});

  final IconData icon;

  @override
  State<_PulsingNode> createState() => _PulsingNodeState();
}

class _PulsingNodeState extends State<_PulsingNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _Node._size,
      height: _Node._size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: 1 + 0.55 * t,
                child: Opacity(
                  opacity: 0.35 * (1 - t),
                  child: Container(
                    width: _Node._size,
                    height: _Node._size,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Container(
                width: _Node._size,
                height: _Node._size,
                decoration: const BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 17, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}
