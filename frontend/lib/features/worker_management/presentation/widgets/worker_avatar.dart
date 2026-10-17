import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/worker_management/presentation/utils/worker_format.dart';

class WorkerAvatar extends StatelessWidget {
  const WorkerAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 24,
  });

  final String name;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final initials = Text(
      initialsOf(name),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: radius * 0.7,
      ),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryDark,
      foregroundImage: (url != null && url.startsWith('http'))
          ? NetworkImage(url)
          : null,
      child: initials,
    );
  }
}
