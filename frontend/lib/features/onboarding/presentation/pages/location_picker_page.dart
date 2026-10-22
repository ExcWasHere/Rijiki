import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rijiki/core/location/location_service.dart';
import 'package:rijiki/core/location/service_area.dart';
import 'package:rijiki/core/map/map_config.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class PickedLocation {
  const PickedLocation({required this.point, this.address});

  final LatLng point;
  final String? address;
}

class LocationPickerPage extends ConsumerStatefulWidget {
  const LocationPickerPage({super.key, this.initialPoint});

  final LatLng? initialPoint;

  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  static const double _zoom = 17;

  final MapController _controller = MapController();
  Timer? _debounce;
  int _requestId = 0;

  late LatLng _center = widget.initialPoint ?? MapConfig.outlet;
  bool _ready = false;
  bool _resolving = false;
  bool _locating = false;
  String? _address;

  @override
  void initState() {
    super.initState();
    if (widget.initialPoint == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToMyLocation());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _scheduleResolve() {
    _debounce?.cancel();
    if (!_resolving) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_resolving) setState(() => _resolving = true);
      });
    }
    _debounce = Timer(const Duration(milliseconds: 600), _resolve);
  }

  Future<void> _resolve() async {
    final id = ++_requestId;
    final point = _center;

    if (!ServiceArea.contains(point)) {
      if (!mounted) return;
      setState(() {
        _address = null;
        _resolving = false;
      });
      return;
    }

    final address = await ref.read(locationServiceProvider).addressOf(point);
    if (!mounted || id != _requestId) return;
    setState(() {
      _address = address;
      _resolving = false;
    });
  }

  Future<void> _goToMyLocation({bool silent = true}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final point = await ref.read(locationServiceProvider).currentPoint();
      if (!mounted) return;
      if (!ServiceArea.contains(point)) {
        if (!silent) _showMessage(ServiceArea.outOfAreaMessage);
        return;
      }
      if (_ready) {
        _controller.move(point, _zoom);
      } else {
        _center = point;
      }
    } on LocationException catch (e) {
      if (!mounted || silent) return;
      final message = switch (e.issue) {
        LocationIssue.serviceDisabled => 'GPS belum menyala.',
        LocationIssue.denied => 'Izin lokasi ditolak.',
        LocationIssue.deniedForever =>
          'Izin lokasi diblokir. Aktifkan lewat pengaturan aplikasi.',
        LocationIssue.unavailable => 'Lokasi belum bisa dibaca. Coba lagi.',
      };
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    if (!ServiceArea.contains(_center)) {
      _showMessage(ServiceArea.outOfAreaMessage);
      return;
    }
    Navigator.of(context).pop(
      PickedLocation(point: _center, address: _resolving ? null : _address),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final inArea = ServiceArea.contains(_center);

    final addressText = !inArea
        ? ServiceArea.outOfAreaMessage
        : _resolving
        ? 'Mencari alamat...'
        : (_address ??
              'Alamat tidak terbaca. Setelah memilih titik, ketik alamatmu sendiri.');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pilih lokasi')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _controller,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: _zoom,
                      minZoom: 5,
                      maxZoom: MapConfig.maxZoom,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () {
                        _ready = true;
                        _scheduleResolve();
                      },
                      onPositionChanged: (camera, hasGesture) {
                        _center = camera.center;
                        _scheduleResolve();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapConfig.tileUrlTemplate,
                        userAgentPackageName: MapConfig.userAgentPackageName,
                        maxNativeZoom: MapConfig.maxNativeZoom,
                      ),
                      SimpleAttributionWidget(
                        source: const Text(
                          'OpenStreetMap contributors',
                          style: TextStyle(fontSize: 10),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 44,
                        color: AppColors.rijikiOrange,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Geser peta sampai pin tepat di lokasimu',
                          style: textTheme.labelMedium,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.lg,
                  bottom: AppSpacing.md,
                  child: FloatingActionButton.small(
                    heroTag: 'picker-locate',
                    backgroundColor: Colors.white,
                    onPressed: _locating
                        ? null
                        : () => _goToMyLocation(silent: false),
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.rijikiBlue,
                          ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.outline.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        inArea
                            ? Icons.location_on_outlined
                            : Icons.error_outline_rounded,
                        size: 20,
                        color: inArea
                            ? AppColors.rijikiBlue
                            : AppColors.rijikiOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          addressText,
                          style: textTheme.bodyMedium?.copyWith(
                            color: !inArea
                                ? AppColors.rijikiOrange
                                : (_address == null && !_resolving
                                      ? AppColors.onSurfaceVariant
                                      : AppColors.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: inArea ? _confirm : null,
                    child: const Text('Konfirmasi lokasi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
