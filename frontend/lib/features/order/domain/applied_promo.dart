import 'package:flutter/foundation.dart';

/// Promo yang dipakai order atau kutipan harga. Satu order maksimal memakai
/// 1 promo layanan dan 1 promo ongkir.
@immutable
class AppliedPromo {
  const AppliedPromo({
    required this.code,
    required this.appliesToShipping,
    required this.discount,
    this.description,
  });

  /// Batas gabung promo per order.
  static const int maxPerOrder = 2;

  final String code;

  /// true = memotong ongkir, false = memotong harga layanan.
  final bool appliesToShipping;
  final int discount;

  /// Judul promo dan nilai potongannya; hanya ada di kutipan harga.
  final String? description;

  /// Label baris rincian harga, mis. "Diskon layanan (HEMAT10)".
  String get label =>
      '${appliesToShipping ? 'Diskon ongkir' : 'Diskon layanan'} ($code)';

  factory AppliedPromo.fromJson(Map<String, dynamic> json) {
    return AppliedPromo(
      code: json['code'] as String? ?? '-',
      appliesToShipping: json['applies_to'] == 'shipping',
      discount: (json['discount_amount'] as num? ?? 0).round(),
      description: json['description'] as String?,
    );
  }

  static List<AppliedPromo> listFromJson(Object? raw) => [
    if (raw is List)
      for (final item in raw)
        if (item is Map<String, dynamic>) AppliedPromo.fromJson(item),
  ];
}
