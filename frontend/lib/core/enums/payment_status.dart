enum PaymentStatus {
  pending,
  paid,
  failed,
  expired;

  static PaymentStatus fromJson(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw ArgumentError('PaymentStatus tidak dikenal: $value'),
    );
  }

  String toJson() => name;
}
