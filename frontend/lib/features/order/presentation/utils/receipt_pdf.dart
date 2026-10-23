import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:share_plus/share_plus.dart';

// TODO(PRD #53): tujuan QR code (tautan unduh aplikasi / halaman landing)
const String kReceiptQrUrl = 'https://rijiki.example.com/app';
abstract final class ReceiptPdf {
  static const String _logoAsset = 'assets/images/logo_rijiki_icon.png';

  static String fileName(CustomerOrder order) =>
      'Struk-${order.orderNumber}.pdf';

  static Future<Uint8List> build({
    required CustomerOrder order,
    required String customerName,
    required String customerPhone,
    String qrUrl = kReceiptQrUrl,
  }) async {
    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load(_logoAsset);
      logo = pw.MemoryImage(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
    }

    final price = order.price;

    final base = pw.TextStyle(fontSize: 8.5);
    final muted = pw.TextStyle(fontSize: 8, color: PdfColors.grey700);
    final bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    final note = pw.TextStyle(
      fontSize: 7.5,
      fontStyle: pw.FontStyle.italic,
      color: PdfColors.grey700,
    );

    pw.Widget divider() => pw.Divider(
      height: 14,
      thickness: 0.6,
      color: PdfColors.grey500,
    );

    pw.Widget line(
      String label,
      String value, {
      pw.TextStyle? valueStyle,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 60, child: pw.Text(label, style: muted)),
            pw.Expanded(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: valueStyle ?? base,
              ),
            ),
          ],
        ),
      );
    }

    final doc = pw.Document(
      title: 'Struk ${order.orderNumber}',
      author: 'Rijiki Shoe Care',
      creator: 'Aplikasi Rijiki',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 6 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null) ...[
                    pw.Image(logo, width: 26, height: 26),
                    pw.SizedBox(width: 8),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RIJIKI SHOE CARE',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text('Struk digital', style: muted),
                      ],
                    ),
                  ),
                  if (order.isPaid)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.green800,
                          width: 1.2,
                        ),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        'LUNAS',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ),
                ],
              ),
              divider(),
              line('No. order', order.orderNumber, valueStyle: bold),
              line('Tanggal', DateFormatter.dateTime(order.createdAt)),
              line('Pemesan', customerName),
              line('No HP', customerPhone),
              if (order.workerName != null)
                line('Ditangani', order.workerName!),
              divider(),
              for (final item in order.items) ...[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            item.quantity > 1
                                ? '${item.shoeName} x${item.quantity}'
                                : item.shoeName,
                            style: bold,
                          ),
                          pw.Text(
                            item.quantity > 1
                                ? '${item.serviceName} - ${RupiahFormatter.full(item.price)}'
                                : item.serviceName,
                            style: muted,
                          ),
                          if (item.notes != null && item.notes!.trim().isNotEmpty)
                            pw.Text('Catatan: ${item.notes}', style: note),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(RupiahFormatter.full(item.lineTotal), style: bold),
                  ],
                ),
                pw.SizedBox(height: 5),
              ],
              divider(),
              line('Subtotal', RupiahFormatter.full(price.subtotal)),
              if (price.discount > 0)
                line(
                  order.promoCode == null
                      ? 'Diskon'
                      : 'Diskon (${order.promoCode})',
                  '-${RupiahFormatter.full(price.discount)}',
                ),
              line('Ongkir', RupiahFormatter.full(price.shipping)),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    RupiahFormatter.full(price.total),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              line('Metode bayar', 'QRIS'),
              line('Status bayar', order.isPaid ? 'Lunas' : 'Belum dibayar'),
              divider(),
              pw.Text(
                'Terima kasih sudah mempercayakan sepatumu kepada Rijiki.\n'
                'Simpan struk ini sebagai bukti pembayaran.',
                textAlign: pw.TextAlign.center,
                style: muted,
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrUrl,
                  width: 80,
                  height: 80,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Pesan, lacak order, dan kumpulkan poin di aplikasi Rijiki.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                qrUrl,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<void> share({
    required CustomerOrder order,
    required String customerName,
    required String customerPhone,
    Rect? sharePositionOrigin,
  }) async {
    final bytes = await build(
      order: order,
      customerName: customerName,
      customerPhone: customerPhone,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
        fileNameOverrides: [fileName(order)],
        text: 'Struk Rijiki ${order.orderNumber}',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
