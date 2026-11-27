import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:rijiki/core/map/map_config.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/order/domain/courier_tracking.dart';

List<Widget> buildCourierMapLayers(
  CourierTracking tracking, {
  double routeWidth = 5,
}) {
  return [
    TileLayer(
      urlTemplate: MapConfig.tileUrlTemplate,
      userAgentPackageName: MapConfig.userAgentPackageName,
      maxNativeZoom: MapConfig.maxNativeZoom,
    ),
    PolylineLayer(
      polylines: [
        Polyline(
          points: tracking.route,
          strokeWidth: routeWidth,
          color: AppColors.primaryDark,
        ),
      ],
    ),
    MarkerLayer(
      markers: [
        Marker(
          point: tracking.destination,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_on_rounded,
            size: 40,
            color: AppColors.rijikiOrange,
          ),
        ),
        Marker(
          point: tracking.position,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryDark, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: tracking.heading * math.pi / 180,
              child: const Icon(
                Icons.navigation_rounded,
                size: 20,
                color: AppColors.rijikiBlue,
              ),
            ),
          ),
        ),
      ],
    ),
    SimpleAttributionWidget(
      source: const Text(
        'OpenStreetMap contributors',
        style: TextStyle(fontSize: 10),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.7),
    ),
  ];
}
