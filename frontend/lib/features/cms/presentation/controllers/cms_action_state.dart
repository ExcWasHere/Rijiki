import 'package:flutter/foundation.dart';

@immutable
class CmsActionState {
  const CmsActionState({
    this.busyId,
    this.busyValue,
    this.saving = false,
    this.errorMessage,
  });

  final String? busyId;
  final bool? busyValue;
  final bool saving;
  final String? errorMessage;
}
