import 'package:flutter/foundation.dart';
enum DocumentationType { before, after, proofOfDelivery }

@immutable
class OrderDocumentation {
  const OrderDocumentation({
    required this.id,
    required this.type,
    this.orderItemId,
    this.photoUrl,
  });

  final String id;
  final DocumentationType type;
  final String? orderItemId;
  final String? photoUrl;
}
