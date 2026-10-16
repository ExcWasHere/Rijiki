import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/scan/presentation/controllers/scan_controller.dart';
import 'package:rijiki/features/scan/presentation/scan_navigation.dart';
import 'package:rijiki/features/scan/presentation/widgets/scan_frame_overlay.dart';
import 'package:rijiki/features/scan/presentation/widgets/scan_tips_sheet.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage>
    with WidgetsBindingObserver {
  CameraController? _camera;
  String? _cameraError;
  bool _torchOn = false;
  bool _busy = false;
  bool _initializing = false;

  bool get _cameraReady => _camera?.value.isInitialized ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final camera = _camera;
      if (camera == null) return;
      setState(() => _camera = null);
      camera.dispose();
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_initializing) return;
    _initializing = true;
    if (mounted) setState(() => _cameraError = null);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setCameraError('Kamera tidak ditemukan di perangkat ini.');
        return;
      }
      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _torchOn = false;
      });
    } on CameraException catch (e) {
      _setCameraError(
        e.code.startsWith('CameraAccess')
            ? 'Izin kamera belum diberikan.'
            : 'Kamera gagal dibuka (${e.code}).',
      );
    } finally {
      _initializing = false;
    }
  }

  void _setCameraError(String message) {
    if (!mounted) return;
    setState(() => _cameraError = message);
  }

  Future<void> _toggleTorch() async {
    final camera = _camera;
    if (camera == null) return;
    final next = !_torchOn;
    try {
      await camera.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = next);
    } on CameraException {
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || !_cameraReady || _busy) return;
    if (camera.value.isTakingPicture) return;

    setState(() => _busy = true);
    try {
      final file = await camera.takePicture();
      if (!mounted) return;
      _startAnalysis(file.path);
    } on CameraException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil foto. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;
    _startAnalysis(picked.path);
  }

  void _startAnalysis(String path) {
    unawaited(ref.read(scanControllerProvider.notifier).analyze(path));
    context.pushReplacement(RoutePaths.customerScanAnalyzing);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scanControllerProvider, (_, _) {});

    final camera = _camera;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (camera != null && _cameraReady) ...[
            _CameraPreviewCover(controller: camera),
            const ScanFrameOverlay(),
          ] else
            _CameraUnavailable(error: _cameraError, onRetry: _initCamera),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Tutup',
                        onPressed: context.closeScan,
                      ),
                      const Spacer(),
                      if (_cameraReady) ...[
                        _RoundIconButton(
                          icon: _torchOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          tooltip: 'Lampu',
                          onPressed: _toggleTorch,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      _RoundIconButton(
                        icon: Icons.help_outline_rounded,
                        tooltip: 'Tips foto',
                        onPressed: () => showScanTipsSheet(context),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: _GalleryButton(onPressed: _pickFromGallery),
                        ),
                      ),
                      _ShutterButton(
                        enabled: _cameraReady && !_busy,
                        onPressed: _capture,
                      ),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewCover extends StatelessWidget {
  const _CameraPreviewCover({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    if (size == null) return const SizedBox.shrink();
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (error == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 44,
              color: Colors.white70,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Kamera belum bisa dipakai',
              style: textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              '$error Kamu tetap bisa memilih foto dari galeri.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              ),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: Colors.white54),
              ),
              child: const Icon(Icons.photo_library_rounded, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Galeri',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.enabled
            ? () {
                HapticFeedback.mediumImpact();
                widget.onPressed();
              }
            : null,
        child: Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: AnimatedScale(
            scale: _pressed ? 0.86 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
