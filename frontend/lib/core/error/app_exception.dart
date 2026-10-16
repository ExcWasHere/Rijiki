class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  static const String networkCode = 'network_error';
  static const String offlineCode = 'offline_error';
  static const String timeoutCode = 'timeout_error';

  static const Set<String> _networkCodes = {
    networkCode,
    offlineCode,
    timeoutCode,
  };

  final String code;
  final String message;
  final int? statusCode;

  bool get isNetwork => _networkCodes.contains(code);

  @override
  String toString() => 'AppException($statusCode, $code, $message)';
}
