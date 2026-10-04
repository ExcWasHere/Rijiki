class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  static const String networkCode = 'network_error';
  final String code;
  final String message;
  final int? statusCode;

  bool get isNetwork => code == networkCode;

  @override
  String toString() => 'AppException($statusCode, $code, $message)';
}
