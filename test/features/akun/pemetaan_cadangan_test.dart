import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/akun/domain/entities/cadangan_info.dart';

void main() {
  group('Pemetaan Cadangan Firestore', () {
    test('pemetaan transaksi lokal ke map dokumen awan dan sebaliknya', () {
      final dataTransaksiLokal = <String, dynamic>{
        'id': 101,
        'jumlah': 45000,
        'kategori_id': 2,
        'tanggal': '2026-10-14',
        'catatan': 'Makan siang ayam geprek',
        'tipe_kebutuhan': 'butuh',
        'sumber': 'manual',
        'nama_toko': 'Geprek Bensu',
        'dibuat_pada': '2026-10-14T12:00:00.000',
      };

      // Map awan menyimpan seluruh field dari tabel lokal
      final mapAwan = Map<String, dynamic>.from(dataTransaksiLokal);

      expect(mapAwan['id'], equals(101));
      expect(mapAwan['jumlah'], equals(45000));
      expect(mapAwan['kategori_id'], equals(2));
      expect(mapAwan['tanggal'], equals('2026-10-14'));
      expect(mapAwan['catatan'], equals('Makan siang ayam geprek'));
      expect(mapAwan['tipe_kebutuhan'], equals('butuh'));
      expect(mapAwan['sumber'], equals('manual'));
      expect(mapAwan['nama_toko'], equals('Geprek Bensu'));
      expect(mapAwan['dibuat_pada'], equals('2026-10-14T12:00:00.000'));

      // Pemulihan kembali ke map lokal
      final dipulihkan = Map<String, dynamic>.from(mapAwan);
      expect(dipulihkan, equals(dataTransaksiLokal));
    });

    test('pemetaan kategori lokal ke map dokumen awan dan sebaliknya', () {
      final dataKategoriLokal = <String, dynamic>{
        'id': 1,
        'nama': 'Makan & Minum',
        'ikon': 'restaurant',
        'warna': '#FF5722',
        'kelompok_kakeibo': 'esensial',
        'bawaan': 1,
        'urutan': 1,
      };

      final mapAwan = Map<String, dynamic>.from(dataKategoriLokal);
      expect(mapAwan['nama'], equals('Makan & Minum'));
      expect(mapAwan['kelompok_kakeibo'], equals('esensial'));
      expect(mapAwan['bawaan'], equals(1));

      final dipulihkan = Map<String, dynamic>.from(mapAwan);
      expect(dipulihkan, equals(dataKategoriLokal));
    });

    test('pemetaan refleksi mingguan ke map dokumen awan dan sebaliknya', () {
      final dataRefleksiLokal = <String, dynamic>{
        'id': 1,
        'tahun': 2026,
        'minggu_ke': 41,
        'target_pengeluaran': 350000,
        'realisasi': 320000,
        'catatan_refleksi': 'Pekan ini berhasil hemat jajan.',
        'dibuat_pada': '2026-10-14T08:00:00.000',
      };

      final mapAwan = Map<String, dynamic>.from(dataRefleksiLokal);
      expect(mapAwan['tahun'], equals(2026));
      expect(mapAwan['minggu_ke'], equals(41));
      expect(mapAwan['target_pengeluaran'], equals(350000));
      expect(mapAwan['realisasi'], equals(320000));

      final dipulihkan = Map<String, dynamic>.from(mapAwan);
      expect(dipulihkan, equals(dataRefleksiLokal));
    });

    test('entitas CadanganInfo memuat default dan nilai waktu yang tepat', () {
      const infoDefault = CadanganInfo();
      expect(infoDefault.waktuCadanganTerakhir, isNull);
      expect(infoDefault.jumlahTransaksi, equals(0));
      expect(infoDefault.jumlahKategori, equals(0));
      expect(infoDefault.jumlahRefleksi, equals(0));

      final waktu = DateTime(2026, 10, 14, 15, 30);
      final infoLengkap = CadanganInfo(
        waktuCadanganTerakhir: waktu,
        jumlahTransaksi: 25,
        jumlahKategori: 5,
        jumlahRefleksi: 2,
      );

      expect(infoLengkap.waktuCadanganTerakhir, equals(waktu));
      expect(infoLengkap.jumlahTransaksi, equals(25));
      expect(infoLengkap.jumlahKategori, equals(5));
      expect(infoLengkap.jumlahRefleksi, equals(2));
    });
  });
}
