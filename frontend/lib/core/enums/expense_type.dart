enum ExpenseType {
  material('material'),
  equipment('equipment'),
  externalService('external_service'),
  other('other');

  const ExpenseType(this.value);

  final String value;

  static ExpenseType? tryParse(String value) {
    for (final type in ExpenseType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
