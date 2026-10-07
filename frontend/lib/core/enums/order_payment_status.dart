enum OrderPaymentStatus {
  unpaid,
  paid;

  static OrderPaymentStatus fromJson(String value) {
    return OrderPaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () =>
          throw ArgumentError('OrderPaymentStatus tidak dikenal: $value'),
    );
  }

  String toJson() => name;
}
