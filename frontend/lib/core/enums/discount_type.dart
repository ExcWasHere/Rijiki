enum DiscountType {
  percentage,
  fixed;

  static DiscountType fromJson(String value) {
    return DiscountType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError('DiscountType tidak dikenal: $value'),
    );
  }

  String toJson() => name;
}
