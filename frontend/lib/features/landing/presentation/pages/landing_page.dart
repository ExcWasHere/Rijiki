import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/landing/presentation/widgets/steps/step_delivery.dart';
import 'package:rijiki/features/landing/presentation/widgets/steps/step_smart_care.dart';
import 'package:rijiki/features/landing/presentation/widgets/steps/step_welcome.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  static const int _lastPage = 2;
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_currentPage < _lastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    // TODO: sesuaikan dengan API tokenStorage kamu
    await ref.read(tokenStorageProvider).setLandingSeen(true);
    if (mounted) context.go(RoutePaths.login); // sesuaikan route auth
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _lastPage;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLast ? null : _finish,
                child: Text(isLast ? '' : 'Lewati'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: StepWelcome(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: StepSmartCare(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: StepDelivery(),
                  ),
                ],
              ),
            ),
            _Dots(count: _lastPage + 1, current: _currentPage),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? 'MULAI' : 'NEXT'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 14 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2EB5F5) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}