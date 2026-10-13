import 'package:flutter/material.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';

@immutable
class FailureView {
  const FailureView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

abstract final class FailurePresenter {
  static FailureView describe(
    Object? error, {
    String fallbackTitle = AppStrings.splashErrorTitle,
  }) {
    if (error is Failure) {
      switch (error.code) {
        case AppException.offlineCode:
          return const FailureView(
            icon: Icons.wifi_off_rounded,
            title: AppStrings.errOfflineTitle,
            message: AppStrings.errOffline,
          );
        case AppException.timeoutCode:
          return const FailureView(
            icon: Icons.timer_off_rounded,
            title: AppStrings.errTimeoutTitle,
            message: AppStrings.errTimeout,
          );
      }

      switch (error.type) {
        case FailureType.network:
          return const FailureView(
            icon: Icons.cloud_off_rounded,
            title: AppStrings.errUnreachableTitle,
            message: AppStrings.errNetwork,
          );
        case FailureType.server:
          return const FailureView(
            icon: Icons.dns_rounded,
            title: AppStrings.errServerTitle,
            message: AppStrings.errServer,
          );
        default:
          return FailureView(
            icon: Icons.error_outline_rounded,
            title: fallbackTitle,
            message: error.message.isEmpty ? AppStrings.errUnknown : error.message,
          );
      }
    }

    return FailureView(
      icon: Icons.error_outline_rounded,
      title: fallbackTitle,
      message: AppStrings.errUnknown,
    );
  }
}
