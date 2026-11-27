import 'package:flutter/foundation.dart';

enum DocumentationType {
  before('before'),
  after('after'),
  proofOfDelivery('proof_of_delivery');

  const DocumentationType(this.json);
  final String json;

  static DocumentationType fromJson(String? value) {
    for (final type in DocumentationType.values) {
      if (type.json == value) return type;
    }
    return DocumentationType.before;
  }
}

@immutable
class OrderDocumentation {
  const OrderDocumentation({
    required this.id,
    required this.type,
    this.orderItemId,
    this.photoUrl,
    this.imageKey,
  });

  final String id;
  final DocumentationType type;
  final String? orderItemId;
  final String? photoUrl;
  final String? imageKey;
}
