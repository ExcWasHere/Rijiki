enum EventType {
  promo,
  collaboration,
  announcement;

  static EventType fromJson(String value) {
    return EventType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError('EventType tidak dikenal: $value'),
    );
  }

  String toJson() => name;
}
