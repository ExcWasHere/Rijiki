import 'package:rijiki/core/utils/share_file.dart';
import 'package:rijiki/features/rating/domain/managed_rating.dart';

/// Membuka lembar bagikan sistem untuk rekap testimoni (ZIP).
Future<void> shareRecapFile(RecapFile file) {
  return shareBytesAsFile(
    bytes: file.bytes,
    fileName: file.fileName,
    mimeType: 'application/zip',
  );
}
