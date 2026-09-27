import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/utils/iso_week.dart';

void main() {
  group('isoWeekNumber', () {
    test('1 Januari 2027 (hari Jumat) masuk pekan 53 tahun 2026', () {
      final date = DateTime(2027, 1, 1);
      final week = isoWeekNumber(date);
      expect(week, 53);
    });

    test('Transaksi Senin 00:00 masuk pekan yang benar (awal pekan)', () {
      // 2026-09-21 is Monday.
      final date = DateTime(2026, 9, 21, 0, 0);
      final week = isoWeekNumber(date);
      // Week 39
      expect(week, 39);
    });

    test('Minggu 23:59 masih di pekan yang sama (akhir pekan)', () {
      // 2026-09-27 is Sunday.
      final date = DateTime(2026, 9, 27, 23, 59);
      final week = isoWeekNumber(date);
      // Week 39
      expect(week, 39);
    });
  });

  group('rentangMingguIso', () {
    test('Mengembalikan Senin dan Minggu yang benar untuk hari apa saja dalam sepekan', () {
      // Wednesday, 2026-09-23
      final date = DateTime(2026, 9, 23, 12, 0);
      final rentang = rentangMingguIso(date);
      
      expect(rentang.awal.year, 2026);
      expect(rentang.awal.month, 9);
      expect(rentang.awal.day, 21); // Monday
      expect(rentang.awal.hour, 0);
      expect(rentang.awal.minute, 0);

      expect(rentang.akhir.year, 2026);
      expect(rentang.akhir.month, 9);
      expect(rentang.akhir.day, 27); // Sunday
      expect(rentang.akhir.hour, 23);
      expect(rentang.akhir.minute, 59);
    });
  });
}
