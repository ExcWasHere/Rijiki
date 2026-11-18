import 'package:flutter_test/flutter_test.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';

void main() {
  group('RupiahFormatter', () {
    test('grouped memberi pemisah ribuan tanpa awalan Rp', () {
      expect(RupiahFormatter.grouped(0), '0');
      expect(RupiahFormatter.grouped(950), '950');
      expect(RupiahFormatter.grouped(25000), '25.000');
      expect(RupiahFormatter.grouped(1250000), '1.250.000');
      expect(RupiahFormatter.grouped(-5000), '-5.000');
    });

    test('full menambahkan Rp dengan spasi', () {
      expect(RupiahFormatter.full(25000), 'Rp 25.000');
      expect(RupiahFormatter.full(0), 'Rp 0');
    });

    test('compact meringkas untuk grafik', () {
      expect(RupiahFormatter.compact(500), 'Rp 500');
      expect(RupiahFormatter.compact(25000), 'Rp 25 rb');
      expect(RupiahFormatter.compact(1500000), 'Rp 1,5 jt');
      expect(RupiahFormatter.compact(2000000000), 'Rp 2 M');
    });
  });

  group('DateFormatter', () {
    test('shortDate dan range', () {
      expect(DateFormatter.shortDate(DateTime(2026, 11, 18)), '18 Nov 2026');
      expect(
        DateFormatter.range(DateTime(2026, 11, 1), DateTime(2026, 11, 30)),
        '1 Nov - 30 Nov 2026',
      );
      expect(
        DateFormatter.range(DateTime(2026, 12, 28), DateTime(2027, 1, 3)),
        '28 Des 2026 - 3 Jan 2027',
      );
    });

    test('groupLabel membedakan hari ini, kemarin, dan tanggal lain', () {
      final now = DateTime(2026, 11, 18, 9);
      expect(DateFormatter.groupLabel(DateTime(2026, 11, 18), now: now), 'Hari ini');
      expect(DateFormatter.groupLabel(DateTime(2026, 11, 17), now: now), 'Kemarin');
      expect(
        DateFormatter.groupLabel(DateTime(2026, 11, 10), now: now),
        '10 Nov 2026',
      );
    });
  });
}
