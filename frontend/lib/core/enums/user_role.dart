/// 1:1 dengan enum user_role di database (PRD Bagian 28).
enum UserRole {
  customer,
  worker,
  owner;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.customer,
    );
  }
}
