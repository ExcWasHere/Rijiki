import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rijiki/features/rating/domain/managed_rating.dart';

/// Menyimpan rekap ke folder sementara aplikasi lalu membuka lembar bagikan
/// sistem, dari situ owner bisa menyimpan ke Files/Drive atau mengirimnya.
Future<void> shareRecapFile(RecapFile file) async {
  final path = '${Directory.systemTemp.path}/${file.fileName}';
  await File(path).writeAsBytes(file.bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'application/zip', name: file.fileName)],
      subject: file.fileName,
    ),
  );
}
