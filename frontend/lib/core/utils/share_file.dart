import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Menyimpan berkas ke folder sementara aplikasi lalu membuka lembar bagikan
/// sistem, dari situ pengguna bisa menyimpan ke Files/Drive atau mengirimnya.
Future<void> shareBytesAsFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final path = '${Directory.systemTemp.path}/$fileName';
  await File(path).writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: mimeType, name: fileName)],
      subject: fileName,
    ),
  );
}
