import 'package:rijiki/features/scan/domain/scan_result.dart';

class ScanException implements Exception {
  const ScanException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ScanRepository {
  Future<ScanResult> analyze(String imagePath);
}
