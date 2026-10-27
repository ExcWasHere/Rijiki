import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';

@immutable
class StaffCapabilities {
  const StaffCapabilities({
    this.nextStatus,
    this.canClaim = false,
    this.canAdvance = false,
    this.canAssign = false,
    this.canCancel = false,
    this.canCorrect = false,
    this.canUpload = const {},
  });

  final OrderStatus? nextStatus;
  final bool canClaim;
  final bool canAdvance;
  final bool canAssign;
  final bool canCancel;
  final bool canCorrect;
  final Set<DocumentationType> canUpload;

  bool canUploadType(DocumentationType type) => canUpload.contains(type);

  bool get hasAnyAction =>
      canClaim || canAdvance || canAssign || canCancel || canCorrect;
}
