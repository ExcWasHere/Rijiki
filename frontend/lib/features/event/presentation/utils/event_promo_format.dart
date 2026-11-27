import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/event/domain/event_promo.dart';

/// Tanpa spasi setelah "Rp" agar label promo tetap ringkas.
String formatRupiahInt(int value) => 'Rp${RupiahFormatter.grouped(value)}';

extension EventPromoFormat on EventPromo {
  /// Contoh: "Diskon 20%", "Diskon Rp10.000", "Diskon ongkir 50%".
  String get discountLabel {
    final value = isPercentage ? '$discountValue%' : formatRupiahInt(discountValue);
    return '${appliesToShipping ? 'Diskon ongkir' : 'Diskon'} $value';
  }

  /// Syarat promo untuk ditampilkan di detail. Selalu berisi minimal satu
  /// baris supaya sheet detail tidak pernah kosong.
  List<String> get conditions {
    final min = minSubtotal;
    final max = maxDiscountAmount;
    final quota = quotaLeft;
    final perCustomer = usageLimitPerCustomer;
    return [
      appliesToShipping
          ? 'Berlaku untuk biaya ongkir'
          : (serviceNames.isEmpty
                ? 'Berlaku untuk semua layanan'
                : 'Berlaku untuk layanan: ${serviceNames.join(', ')}'),
      if (min != null && min > 0) 'Min. belanja ${formatRupiahInt(min)}',
      if (isPercentage && max != null && max > 0)
        'Maks. potongan ${formatRupiahInt(max)}',
      if (firstOrderOnly) 'Khusus order pertama',
      if (perCustomer != null) 'Maks. $perCustomer kali per akun',
      if (quota != null) 'Sisa kuota $quota',
    ];
  }

  /// Alasan promo tidak bisa dipakai; null bila masih tersedia.
  String? get unavailableReason {
    if (available) return null;
    if (!isActive) return 'Promo sedang tidak aktif.';
    if (quotaLeft != null && quotaLeft! <= 0) return 'Kuota promo sudah habis.';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
      return 'Promo belum dimulai.';
    }
    if (today.isAfter(DateTime(endDate.year, endDate.month, endDate.day))) {
      return 'Promo sudah berakhir.';
    }
    return 'Promo sedang tidak tersedia.';
  }
}
