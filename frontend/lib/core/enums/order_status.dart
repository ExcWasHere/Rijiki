enum OrderStatus {
  order,
  pickup,
  waiting,
  cleaning,
  delivery,
  completed,
  cancelled;

  static OrderStatus fromJson(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw ArgumentError('OrderStatus tidak dikenal: $value'),
    );
  }

  String toJson() => name;
  bool get isActive =>
      this != OrderStatus.completed && this != OrderStatus.cancelled;
}
