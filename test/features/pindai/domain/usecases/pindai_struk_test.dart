import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/network/gemini_client.dart';
import 'package:insap/features/pindai/data/datasources/kuota_local_datasource.dart';
import 'package:insap/features/pindai/data/datasources/pindai_remote_datasource.dart';
import 'package:insap/features/pindai/data/models/hasil_pindai_model.dart';
import 'package:insap/features/pindai/data/repositories/pindai_repository_impl.dart';
import 'package:insap/features/pindai/domain/usecases/pindai_struk.dart';

class _FakePindaiRemoteDataSource implements PindaiRemoteDataSource {
  bool pindaiDipanggil = false;
  String? imagePathTerpanggil;
  List<String>? kategoriTerpanggil;
  HasilPindaiModel? hasilKembalian;
  Exception? errorToThrow;

  @override
  Future<HasilPindaiModel> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
  }) async {
    pindaiDipanggil = true;
    imagePathTerpanggil = imagePath;
    kategoriTerpanggil = daftarKategori;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return hasilKembalian ??
        const HasilPindaiModel(
          adalahStruk: true,
          total: 50000,
          keyakinan: 0.9,
        );
  }
}

class _FakeKuotaLocalDataSource implements KuotaLocalDataSource {
  int sisaKuota = 10;
  bool potongKuotaDipanggil = false;
  bool resetKuotaDipanggil = false;

  @override
  Future<int> ambilSisaKuota({DateTime? waktuSekarang}) async {
    return sisaKuota;
  }

  @override
  Future<void> potongKuota() async {
    potongKuotaDipanggil = true;
    if (sisaKuota > 0) {
      sisaKuota--;
    }
  }

  @override
  Future<void> resetKuotaKeAwal({DateTime? waktuSekarang}) async {
    resetKuotaDipanggil = true;
    sisaKuota = 10;
  }
}

void main() {
  late _FakePindaiRemoteDataSource fakeRemote;
  late _FakeKuotaLocalDataSource fakeLocal;
  late PindaiRepositoryImpl repository;
  late PindaiStruk useCase;

  setUp(() {
    fakeRemote = _FakePindaiRemoteDataSource();
    fakeLocal = _FakeKuotaLocalDataSource();
    repository = PindaiRepositoryImpl(
      remoteDataSource: fakeRemote,
      localDataSource: fakeLocal,
    );
    useCase = PindaiStruk(repository);
  });

  group('PindaiStruk & Aturan Penanganan Kontrak Gemini', () {
    test('1. Balasan bukan JSON valid: pesan galat tampil, kuota tidak dipotong', () async {
      fakeRemote.errorToThrow =
          const GeminiException('Gagal membaca struk, coba lagi');

      expect(
        () => useCase(
          imagePath: '/path/struk.jpg',
          daftarKategori: ['makan', 'transport'],
        ),
        throwsA(isA<GeminiException>().having(
          (e) => e.pesan,
          'pesan',
          contains('Gagal membaca struk'),
        )),
      );

      expect(fakeLocal.potongKuotaDipanggil, isFalse);
    });

    test('2. adalahStruk bernilai false: bukan struk, kuota tidak dipotong', () async {
      fakeRemote.hasilKembalian = const HasilPindaiModel(
        adalahStruk: false,
        namaToko: null,
        tanggal: null,
        total: null,
        kategoriUsulan: null,
        keyakinan: 0.0,
      );

      final result = await useCase(
        imagePath: '/path/kucing.jpg',
        daftarKategori: ['makan'],
      );

      expect(result.adalahStruk, isFalse);
      expect(fakeLocal.potongKuotaDipanggil, isFalse);
      expect(fakeLocal.sisaKuota, 10);
    });

    test('3. keyakinan di bawah 0.5: draf tetap terbuka, kuota dipotong', () async {
      fakeRemote.hasilKembalian = const HasilPindaiModel(
        adalahStruk: true,
        namaToko: 'Warung Bu Sri',
        tanggal: '2026-10-14',
        total: 18000,
        kategoriUsulan: 'makan',
        keyakinan: 0.35, // keyakinan rendah
      );

      final result = await useCase(
        imagePath: '/path/struk_buram.jpg',
        daftarKategori: ['makan'],
      );

      expect(result.adalahStruk, isTrue);
      expect(result.keyakinan, 0.35);
      expect(fakeLocal.potongKuotaDipanggil, isTrue);
      expect(fakeLocal.sisaKuota, 9);
    });

    test('4. total bernilai null: draf terbuka dengan nominal kosong, kuota dipotong', () async {
      fakeRemote.hasilKembalian = const HasilPindaiModel(
        adalahStruk: true,
        namaToko: 'Toko Buku',
        tanggal: '2026-10-14',
        total: null, // total tidak terbaca
        kategoriUsulan: 'lainnya',
        keyakinan: 0.75,
      );

      final result = await useCase(
        imagePath: '/path/struk_robek.jpg',
        daftarKategori: ['lainnya'],
      );

      expect(result.adalahStruk, isTrue);
      expect(result.total, isNull);
      expect(fakeLocal.potongKuotaDipanggil, isTrue);
      expect(fakeLocal.sisaKuota, 9);
    });

    test('5. Balasan lengkap: draf terbuka sempurna, kuota dipotong', () async {
      fakeRemote.hasilKembalian = const HasilPindaiModel(
        adalahStruk: true,
        namaToko: 'Indomaret Sempaja',
        tanggal: '2026-09-01',
        total: 47500,
        kategoriUsulan: 'makan',
        keyakinan: 0.92,
      );

      final result = await useCase(
        imagePath: '/path/struk_lengkap.jpg',
        daftarKategori: ['makan', 'transport'],
      );

      expect(result.adalahStruk, isTrue);
      expect(result.total, 47500);
      expect(fakeLocal.potongKuotaDipanggil, isTrue);
      expect(fakeLocal.sisaKuota, 9);
    });

    test('6. Batas waktu lewat 15 detik: batalkan dengan galat timeout, kuota aman', () async {
      fakeRemote.errorToThrow = const GeminiException(
        'Waktu tunggu pemindaian habis (melebihi 15 detik)',
        408,
      );

      expect(
        () => useCase(
          imagePath: '/path/struk.jpg',
          daftarKategori: ['makan'],
        ),
        throwsA(isA<GeminiException>().having(
          (e) => e.statusCode,
          'statusCode',
          408,
        )),
      );

      expect(fakeLocal.potongKuotaDipanggil, isFalse);
      expect(fakeLocal.sisaKuota, 10);
    });

    test('7. Kuota habis: tolak pemindaian sebelum panggilan API dilakukan', () async {
      fakeLocal.sisaKuota = 0;

      expect(
        () => useCase(
          imagePath: '/path/struk.jpg',
          daftarKategori: ['makan'],
        ),
        throwsA(isA<GeminiException>().having(
          (e) => e.pesan,
          'pesan',
          contains('sudah habis'),
        )),
      );

      expect(fakeRemote.pindaiDipanggil, isFalse);
      expect(fakeLocal.potongKuotaDipanggil, isFalse);
    });
  });
}
