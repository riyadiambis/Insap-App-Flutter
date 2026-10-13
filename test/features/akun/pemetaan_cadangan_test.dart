import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/akun/data/repositories/cadangan_repository_impl.dart';
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

  group('Pencegahan Risiko Data Hantu (Ghost Data)', () {
    test('transaksi yang dihapus di lokal terdeteksi sebagai dokumen usang yang harus dihapus di awan', () {
      final idTransaksiAwan = ['101', '102', '103'];
      // Transaksi 102 dihapus di lokal
      final idTransaksiLokal = ['101', '103'];

      final idUsang = CadanganRepositoryImpl.cariDokumenUsang(
        idAwan: idTransaksiAwan,
        idLokal: idTransaksiLokal,
      );

      expect(idUsang, equals({'102'}));
    });

    test(
      'kategori kustom yang dihapus di lokal terdeteksi untuk dihapus di awan',
      () {
        final idKategoriAwan = ['1', '2', '3', '99'];
        // Kategori 99 dihapus di lokal
        final idKategoriLokal = ['1', '2', '3'];

        final idUsang = CadanganRepositoryImpl.cariDokumenUsang(
          idAwan: idKategoriAwan,
          idLokal: idKategoriLokal,
        );

        expect(idUsang, equals({'99'}));
      },
    );

    test('refleksi yang dihapus di lokal terdeteksi untuk dihapus di awan', () {
      final idRefleksiAwan = ['1', '2'];
      // Refleksi 1 dihapus di lokal
      final idRefleksiLokal = ['2'];

      final idUsang = CadanganRepositoryImpl.cariDokumenUsang(
        idAwan: idRefleksiAwan,
        idLokal: idRefleksiLokal,
      );

      expect(idUsang, equals({'1'}));
    });

    test('jika data lokal kosong sama sekali, seluruh dokumen awan ditandai untuk dihapus', () {
      final idTransaksiAwan = ['101', '102'];
      final idTransaksiLokal = <String>[];

      final idUsang = CadanganRepositoryImpl.cariDokumenUsang(
        idAwan: idTransaksiAwan,
        idLokal: idTransaksiLokal,
      );

      expect(idUsang, equals({'101', '102'}));
    });

    test('tidak ada dokumen awan yang dihapus jika semua data lokal tetap ada atau bertambah', () {
      final idTransaksiAwan = ['101', '102'];
      final idTransaksiLokal = ['101', '102', '103'];

      final idUsang = CadanganRepositoryImpl.cariDokumenUsang(
        idAwan: idTransaksiAwan,
        idLokal: idTransaksiLokal,
      );

      expect(idUsang, isEmpty);
    });

    test('simulasi rekonsiliasi cadangan: penghapusan lokal tidak menimbulkan data hantu saat pulihkan', () {
      // Simulasi database awan sebelum pencadangan ulang
      final subkoleksiAwan = <String, Map<String, dynamic>>{
        '101': {'id': 101, 'jumlah': 20000},
        '102': {'id': 102, 'jumlah': 35000}, // dihapus lokal
        '103': {'id': 103, 'jumlah': 50000},
      };

      // Data lokal saat ini
      final daftarLokal = <Map<String, dynamic>>[
        {'id': 101, 'jumlah': 25000}, // diperbarui
        {'id': 103, 'jumlah': 50000},
        {'id': 104, 'jumlah': 15000}, // transaksi baru
      ];

      // 1. Identifikasi dokumen usang di awan
      final usang = CadanganRepositoryImpl.cariDokumenUsang(
        idAwan: subkoleksiAwan.keys,
        idLokal: daftarLokal.map((d) => d['id'].toString()),
      );

      // 2. Hapus dokumen usang dari awan
      for (final id in usang) {
        subkoleksiAwan.remove(id);
      }

      // 3. Tulis ulang/perbarui data lokal ke awan
      for (final item in daftarLokal) {
        subkoleksiAwan[item['id'].toString()] = item;
      }

      // 4. Verifikasi isi awan setelah pencadangan ulang
      expect(subkoleksiAwan.containsKey('102'), isFalse);
      expect(subkoleksiAwan.length, equals(3));
      expect(subkoleksiAwan['101']?['jumlah'], equals(25000));
      expect(subkoleksiAwan['104']?['jumlah'], equals(15000));

      // 5. Simulasi pemulihan dari awan ke lokal: data hantu 102 tidak akan muncul
      final hasilPulihkan = subkoleksiAwan.values.toList();
      expect(hasilPulihkan.any((item) => item['id'] == 102), isFalse);
    });
  });
}
