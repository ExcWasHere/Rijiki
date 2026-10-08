import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/scan/domain/scan_repository.dart';
import 'package:rijiki/features/scan/domain/scan_result.dart';

enum ScanStatus { idle, analyzing, success, failure }

@immutable
class ScanState {
  const ScanState({
    this.status = ScanStatus.idle,
    this.imagePath,
    this.result,
    this.errorMessage,
  });

  const ScanState.analyzing(String path)
    : this(status: ScanStatus.analyzing, imagePath: path);

  const ScanState.success(String path, ScanResult scanResult)
    : this(status: ScanStatus.success, imagePath: path, result: scanResult);

  const ScanState.failure(String path, String message)
    : this(status: ScanStatus.failure, imagePath: path, errorMessage: message);

  final ScanStatus status;
  final String? imagePath;
  final ScanResult? result;
  final String? errorMessage;
}

class ScanController extends Notifier<ScanState> {
  bool _disposed = false;

  @override
  ScanState build() {
    ref.onDispose(() => _disposed = true);
    return const ScanState();
  }

  Future<void> analyze(String imagePath) async {
    state = ScanState.analyzing(imagePath);
    try {
      final result = await ref.read(scanRepositoryProvider).analyze(imagePath);
      if (_disposed) return;
      state = ScanState.success(imagePath, result);
    } on ScanException catch (e) {
      if (_disposed) return;
      state = ScanState.failure(imagePath, e.message);
    } catch (_) {
      if (_disposed) return;
      state = ScanState.failure(
        imagePath,
        'Analisis gagal. Periksa koneksi lalu coba lagi.',
      );
    }
  }

  Future<void> retry() async {
    final path = state.imagePath;
    if (path == null) return;
    await analyze(path);
  }
}

final scanControllerProvider =
    NotifierProvider.autoDispose<ScanController, ScanState>(
      ScanController.new,
    );
