import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/pindai/presentation/utils/cocokkan_kategori.dart';

void main() {
  group('cocokkanKategori (No 14, audit ISSUE-28 bagian 3e)', () {
    const daftarKategori = [
      'makan',
      'transport',
      'kos',
      'kuliah',
      'jajan daring',
      'nongkrong',
      'top up',
      'darurat',
      'lainnya',
    ];

    test('cocok persis huruf kecil', () {
      expect(cocokkanKategori('makan', daftarKategori), 'makan');
      expect(cocokkanKategori('transport', daftarKategori), 'transport');
      expect(cocokkanKategori('kos', daftarKategori), 'kos');
      expect(cocokkanKategori('top up', daftarKategori), 'top up');
    });

    test('cocok persis dengan spasi luar dan huruf besar (case-insensitive + trim)', () {
      expect(cocokkanKategori('  Makan  ', daftarKategori), 'makan');
      expect(cocokkanKategori('KOS', daftarKategori), 'kos');
      expect(cocokkanKategori('  Top Up ', daftarKategori), 'top up');
    });

    test('kosmetik tidak boleh mencocokkan kos, harus fallback ke lainnya (No 14)', () {
      // Pada audit ISSUE-28, "kosmetik" salah dicocokkan ke "kos" karena substring
      expect(cocokkanKategori('kosmetik', daftarKategori), 'lainnya');
    });

    test('topup tanpa spasi tidak boleh mencocokkan top up atau jatuh ke makan (No 14)', () {
      expect(cocokkanKategori('topup', daftarKategori), 'lainnya');
    });

    test('belanja dan minimarket jatuh ke lainnya, bukan ke kategori pertama makan (No 14)', () {
      expect(cocokkanKategori('belanja', daftarKategori), 'lainnya');
      expect(cocokkanKategori('minimarket', daftarKategori), 'lainnya');
    });

    test('null atau string kosong jatuh ke lainnya (No 14)', () {
      expect(cocokkanKategori(null, daftarKategori), 'lainnya');
      expect(cocokkanKategori('', daftarKategori), 'lainnya');
      expect(cocokkanKategori('   ', daftarKategori), 'lainnya');
    });

    test('kategori tidak dikenal jatuh ke lainnya', () {
      expect(cocokkanKategori('elektronik', daftarKategori), 'lainnya');
      expect(cocokkanKategori('asuransi', daftarKategori), 'lainnya');
    });
  });
}
