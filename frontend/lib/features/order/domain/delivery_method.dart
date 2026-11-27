enum DeliveryMethod {
  delivery,
  selfPickup;

  static DeliveryMethod fromJson(String? value) {
    return value == 'self_pickup' ? DeliveryMethod.selfPickup : DeliveryMethod.delivery;
  }

  String get label => switch (this) {
    DeliveryMethod.delivery => 'Diantar ke alamat customer',
    DeliveryMethod.selfPickup => 'Diambil sendiri di outlet',
  };
}
