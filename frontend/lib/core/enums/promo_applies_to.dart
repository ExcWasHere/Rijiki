enum PromoAppliesTo {
  subtotal,
  shipping;

  static PromoAppliesTo fromJson(String? value) {
    return PromoAppliesTo.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PromoAppliesTo.subtotal,
    );
  }

  String toJson() => name;
}
