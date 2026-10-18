import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/network/gemini_client.dart';
import 'package:insap/features/pindai/data/models/hasil_pindai_model.dart';
import 'package:insap/features/pindai/domain/entities/hasil_pindai_entity.dart';

void main() {
  group('HasilPindaiModel', () {
    test('adalah subclass dari HasilPindaiEntity', () {
      const model = HasilPindaiModel(
        adalahStruk: true,
        namaToko: 'Indomaret Sempaja',
        tanggal: '2026-09-01',
        total: 47500,
        kategoriUsulan: 'makan',
        keyakinan: 0.92,
      );

      expect(model, isA<HasilPindaiEntity>());
    });

    test('fromJson berhasil memetakan JSON valid sesuai GEMINI-CONTRACT.md', () {
      final json = {
        'adalah_struk': true,
        'nama_toko': 'Indomaret Sempaja',
        'tanggal': '2026-09-01',
        'total': 47500,
        'kategori_usulan': 'makan',
        'keyakinan': 0.92,
      };

      final result = HasilPindaiModel.fromJson(json);

      expect(result.adalahStruk, isTrue);
      expect(result.namaToko, 'Indomaret Sempaja');
      expect(result.tanggal, '2026-09-01');
      expect(result.total, 47500);
      expect(result.kategoriUsulan, 'makan');
      expect(result.keyakinan, 0.92);
      expect(result.barang.length, 1);
      expect(result.barang.first.nama, 'Total struk');
      expect(result.barang.first.harga, 47500);
    });

    test('fromJson berhasil memetakan JSON bukan struk', () {
      final json = {
        'adalah_struk': false,
        'nama_toko': null,
        'tanggal': null,
        'total': null,
        'kategori_usulan': null,
        'keyakinan': 0.0,
      };

      final result = HasilPindaiModel.fromJson(json);

      expect(result.adalahStruk, isFalse);
      expect(result.namaToko, isNull);
      expect(result.tanggal, isNull);
      expect(result.total, isNull);
      expect(result.kategoriUsulan, isNull);
      expect(result.keyakinan, 0.0);
      expect(result.barang, isEmpty);
    });

    test('fromJson melempar GeminiException bila adalah_struk hilang dari JSON (No 15)', () {
      final Map<String, dynamic> json = {};

      expect(
        () => HasilPindaiModel.fromJson(json),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.pesan,
            'pesan',
            'Gagal membaca struk, coba lagi',
          ),
        ),
      );
    });

    test('fromJson melempar GeminiException bila adalah_struk bukan boolean (No 15)', () {
      final json = {
        'adalah_struk': 'true', // string bukan boolean
        'nama_toko': 'Kopi Kenangan',
        'tanggal': '2026-10-14',
        'total': 28500,
        'kategori_usulan': 'makan',
        'keyakinan': 0.88,
      };

      expect(
        () => HasilPindaiModel.fromJson(json),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.pesan,
            'pesan',
            'Gagal membaca struk, coba lagi',
          ),
        ),
      );
    });

    test('fromJson menangani total sebagai tipe num/double', () {
      final json = {
        'adalah_struk': true,
        'nama_toko': 'Indomaret Sempaja',
        'tanggal': '2026-09-01',
        'total': 47500.0,
        'kategori_usulan': 'makan',
        'keyakinan': 0.92,
      };

      final result = HasilPindaiModel.fromJson(json);

      expect(result.total, 47500);
    });

    test('fromJson menangani total sebagai string angka berformat', () {
      final json = {
        'adalah_struk': true,
        'nama_toko': 'Indomaret Sempaja',
        'tanggal': '2026-09-01',
        'total': 'Rp 47.500',
        'kategori_usulan': 'makan',
        'keyakinan': 0.92,
      };

      final result = HasilPindaiModel.fromJson(json);

      expect(result.total, 47500);
    });

    test('toJson mengembalikan Map yang sesuai', () {
      const model = HasilPindaiModel(
        adalahStruk: true,
        namaToko: 'Indomaret Sempaja',
        tanggal: '2026-09-01',
        total: 47500,
        kategoriUsulan: 'makan',
        keyakinan: 0.92,
      );

      final map = model.toJson();

      expect(map['adalah_struk'], isTrue);
      expect(map['nama_toko'], 'Indomaret Sempaja');
      expect(map['tanggal'], '2026-09-01');
      expect(map['total'], 47500);
      expect(map['kategori_usulan'], 'makan');
      expect(map['keyakinan'], 0.92);
    });

    // --- Uji Tahap 2B: Parser dan data per barang ---

    test('Tahap 2B: barang null atau kosong menghasilkan 1 baris "Total struk"', () {
      final json = {
        'adalah_struk': true,
        'nama_toko': 'Warung Bu Siti',
        'tanggal': '2026-10-18',
        'total': 35000,
        'kategori_usulan': 'makan',
        'keyakinan': 0.85,
        'barang': [],
      };

      final result = HasilPindaiModel.fromJson(json, daftarKategori: ['makan']);

      expect(result.barang.length, 1);
      final item = result.barang.first;
      expect(item.nama, 'Total struk');
      expect(item.harga, 35000);
      expect(item.kategoriId, 1);
      expect(item.dicentang, isTrue);
      expect(item.adalahSelisih, isFalse);
    });

    test('Tahap 2B: total null tapi barang ada -> total dihitung dari jumlah harga barang (fold)', () {
      final json = {
        'adalah_struk': true,
        'nama_toko': 'Minimarket XYZ',
        'tanggal': '2026-10-18',
        'total': null,
        'kategori_usulan': 'makan',
        'keyakinan': 0.85,
        'barang': [
          {'nama': 'Roti', 'harga': 12000, 'kategori': 'makan'},
          {'nama': 'Susu', 'harga': 8000, 'kategori': 'makan'},
        ],
      };

      final result = HasilPindaiModel.fromJson(json, daftarKategori: ['makan']);

      expect(result.total, 20000);
      expect(result.totalDihitungDariBarang, isTrue);
      expect(result.barang.length, 2);
    });

    test('Tahap 2B: kategori tak dikenal otomatis diarahkan ke "lainnya"', () {
      final json = {
        'adalah_struk': true,
        'total': 15000,
        'kategori_usulan': 'kategori_aneh',
        'keyakinan': 0.8,
        'barang': [
          {'nama': 'Barang Aneh', 'harga': 15000, 'kategori': 'kosmetik'},
        ],
      };

      final result = HasilPindaiModel.fromJson(
        json,
        daftarKategori: ['makan', 'transport', 'lainnya'],
      );

      expect(result.barang.first.kategoriId, 9); // ID untuk lainnya
    });

    test('Tahap 2B: selisih positif (pajak/layanan) ditambahkan sebagai baris selisih di kelompok terbesar', () {
      final json = {
        'adalah_struk': true,
        'total': 50000, // Total struk 50.000
        'keyakinan': 0.9,
        'barang': [
          {'nama': 'Nasi Goreng', 'harga': 30000, 'kategori': 'makan'},
          {'nama': 'Bensin', 'harga': 15000, 'kategori': 'transport'},
        ], // Jumlah barang = 45.000, selisih = 5.000
      };

      final result = HasilPindaiModel.fromJson(
        json,
        daftarKategori: ['makan', 'transport', 'lainnya'],
      );

      expect(result.barang.length, 3);
      final selisihItem = result.barang.last;
      expect(selisihItem.nama, 'Pajak/diskon/pembulatan');
      expect(selisihItem.harga, 5000);
      expect(selisihItem.adalahSelisih, isTrue);
      expect(selisihItem.kategoriId, 1); // makan (30.000) > transport (15.000)
    });

    test('Tahap 2B: selisih negatif (diskon) ditambahkan sebagai baris selisih negatif di kelompok terbesar', () {
      final json = {
        'adalah_struk': true,
        'total': 38000, // Total struk 38.000 (diskon 5.000)
        'keyakinan': 0.9,
        'barang': [
          {'nama': 'Kaos Kaki', 'harga': 25000, 'kategori': 'jajan daring'},
          {'nama': 'Buku Tulis', 'harga': 18000, 'kategori': 'kuliah'},
        ], // Jumlah barang = 43.000, selisih = -5.000
      };

      final result = HasilPindaiModel.fromJson(
        json,
        daftarKategori: ['jajan daring', 'kuliah', 'lainnya'],
      );

      expect(result.barang.length, 3);
      final selisihItem = result.barang.last;
      expect(selisihItem.nama, 'Pajak/diskon/pembulatan');
      expect(selisihItem.harga, -5000);
      expect(selisihItem.adalahSelisih, isTrue);
      expect(selisihItem.kategoriId, 5); // jajan daring (25.000) > kuliah (18.000)
    });
  });
}
