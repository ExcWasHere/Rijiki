import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/scan/presentation/controllers/scan_controller.dart';
import 'package:rijiki/features/scan/presentation/scan_navigation.dart';
import 'package:rijiki/shared/widgets/error_state.dart';

class ScanAnalyzingPage extends ConsumerStatefulWidget {
  const ScanAnalyzingPage({super.key});

  @override
  ConsumerState<ScanAnalyzingPage> createState() => _ScanAnalyzingPageState();
}

class _ScanAnalyzingPageState extends ConsumerState<ScanAnalyzingPage>
    with SingleTickerProviderStateMixin {
  static const List<String> _steps = [
    'Mengenali tipe sepatu',
    'Mengenali material',
    'Memeriksa kondisi',
    'Menyusun rekomendasi',
  ];

  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  Timer? _stepTimer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() => _step = math.min(_step + 1, _steps.length - 1));
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scanControllerProvider, (previous, next) {
      if (next.status == ScanStatus.success) {
        context.pushReplacement(RoutePaths.customerScanResult);
      }
    });

    final state = ref.watch(scanControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final isFailure = state.status == ScanStatus.failure;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: isFailure
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ErrorState(
                        message:
                            state.errorMessage ?? 'Analisis gagal. Coba lagi.',
                        onRetry: () => ref
                            .read(scanControllerProvider.notifier)
                            .retry(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () =>
                            context.pushReplacement(RoutePaths.customerScan),
                        child: const Text('Foto ulang'),
                      ),
                      TextButton(
                        onPressed: context.closeScan,
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const Spacer(),
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _Photo(path: state.imagePath),
                            ColoredBox(
                              color: Colors.black.withValues(alpha: 0.12),
                            ),
                            AnimatedBuilder(
                              animation: _sweep,
                              builder: (context, _) => Align(
                                alignment: Alignment(0, -1 + 2 * _sweep.value),
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.8,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Menganalisis sepatumu', style: textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Biasanya cuma butuh beberapa detik.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (var i = 0; i < _steps.length; i++)
                      _StepRow(
                        label: _steps[i],
                        done: i < _step,
                        active: i == _step,
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: context.closeScan,
                      child: const Text('Batal'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.outline.withValues(alpha: 0.2),
      child: const Icon(Icons.image_outlined, color: AppColors.onSurfaceVariant),
    );
    if (path == null) return placeholder;
    return Image.file(
      File(path!),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Widget leading;
    if (done) {
      leading = const Icon(
        Icons.check_circle_rounded,
        size: 20,
        color: AppColors.success,
      );
    } else if (active) {
      leading = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: AppColors.primaryDark,
        ),
      );
    } else {
      leading = Icon(
        Icons.circle_outlined,
        size: 20,
        color: AppColors.outline.withValues(alpha: 0.6),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 24, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: done || active
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
