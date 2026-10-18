import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/network/gemini_client.dart';
import 'package:insap/features/pindai/domain/entities/hasil_pindai_entity.dart';
import 'package:insap/features/pindai/domain/repositories/pindai_repository.dart';
import 'package:insap/features/pindai/domain/usecases/ambil_kuota_pindai.dart';
import 'package:insap/features/pindai/domain/usecases/pindai_struk.dart';
import 'package:insap/features/pindai/presentation/cubit/pindai_cubit.dart';
import 'package:insap/features/pindai/presentation/cubit/pindai_state.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/tambah_transaksi.dart';

class _FakePindaiRepository implements PindaiRepository {
  int kuota = 10;
  HasilPindaiEntity? hasilKembalian;
  Exception? errorToThrow;
  CancelToken? capturedCancelToken;

  @override
  Future<HasilPindaiEntity> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
    Map<String, int>? petaKategoriId,
    CancelToken? cancelToken,
  }) async {
    capturedCancelToken = cancelToken;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return hasilKembalian ??
        const HasilPindaiEntity(
          adalahStruk: true,
          namaToko: 'Indomaret Sempaja',
          tanggal: '2026-10-14',
          total: 45000,
          kategoriUsulan: 'makan',
          keyakinan: 0.95,
        );
  }

  @override
  Future<int> ambilSisaKuota() async => kuota;

  @override
  Future<void> potongKuota() async {
    if (kuota > 0) kuota--;
  }
}

class _FakeTransaksiRepository implements TransaksiRepository {
  TransaksiEntity? transaksiTersimpan;
  bool shouldThrow = false;

  @override
  Future<int> simpan(TransaksiEntity transaksi) async {
    if (shouldThrow) {
      throw Exception('Database disk error');
    }
    transaksiTersimpan = transaksi;
    return 1;
  }

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async => const [];

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async {
    if (shouldThrow) {
      throw Exception('Database disk error');
    }
    return List.generate(daftarTransaksi.length, (i) => i + 1);
  }
}

void main() {
  late _FakePindaiRepository fakePindaiRepo;
  late _FakeTransaksiRepository fakeTransaksiRepo;
  late PindaiStruk pindaiStruk;
  late AmbilKuotaPindai ambilKuotaPindai;
  late TambahTransaksi tambahTransaksi;
  late PindaiCubit cubit;

  setUp(() {
    fakePindaiRepo = _FakePindaiRepository();
    fakeTransaksiRepo = _FakeTransaksiRepository();
    pindaiStruk = PindaiStruk(fakePindaiRepo);
    ambilKuotaPindai = AmbilKuotaPindai(fakePindaiRepo);
    tambahTransaksi = TambahTransaksi(fakeTransaksiRepo);

    cubit = PindaiCubit(
      pindaiStruk: pindaiStruk,
      ambilKuotaPindai: ambilKuotaPindai,
      tambahTransaksi: tambahTransaksi,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('PindaiCubit', () {
    test('state awal adalah PindaiState dengan status awal dan kuota awal dinamis 0 (No 12)', () {
      expect(cubit.state.status, PindaiStatus.awal);
      expect(cubit.state.sisaKuota, 0);
      expect(cubit.state.hasilPindai, isNull);
    });

    test('inisialisasi memperbarui sisa kuota dari usecase', () async {
      fakePindaiRepo.kuota = 7;

      await cubit.inisialisasi();

      expect(cubit.state.sisaKuota, 7);
    });

    test('prosesPindai berhasil dengan keyakinan tinggi', () async {
      fakePindaiRepo.hasilKembalian = const HasilPindaiEntity(
        adalahStruk: true,
        namaToko: 'Indomaret Sempaja',
        tanggal: '2026-10-14',
        total: 45000,
        kategoriUsulan: 'makan',
        keyakinan: 0.95,
      );

      await cubit.prosesPindai(
        imagePath: '/tmp/struk.png',
        daftarKategori: ['makan', 'transport'],
      );

      expect(cubit.state.status, PindaiStatus.butuhKonfirmasi);
      expect(cubit.state.perluPeringatanKeyakinan, isFalse);
      expect(cubit.state.hasilPindai?.namaToko, 'Indomaret Sempaja');
      expect(cubit.state.hasilPindai?.total, 45000);
      expect(cubit.state.imagePath, '/tmp/struk.png');
      expect(cubit.state.tawarkanCatatManual, isFalse);
    });

    test('prosesPindai berhasil dengan keyakinan rendah (< 0.5) memunculkan peringatan', () async {
      fakePindaiRepo.hasilKembalian = const HasilPindaiEntity(
        adalahStruk: true,
        namaToko: 'Warung Tegal',
        tanggal: '2026-10-14',
        total: 15000,
        kategoriUsulan: 'makan',
        keyakinan: 0.35,
      );

      await cubit.prosesPindai(
        imagePath: '/tmp/struk_buram.png',
        daftarKategori: ['makan'],
      );

      expect(cubit.state.status, PindaiStatus.butuhKonfirmasi);
      expect(cubit.state.perluPeringatanKeyakinan, isTrue);
      expect(cubit.state.hasilPindai?.namaToko, 'Warung Tegal');
    });

    test('prosesPindai bukan struk (adalahStruk == false) mengubah status menjadi gagal', () async {
      fakePindaiRepo.hasilKembalian = const HasilPindaiEntity(
        adalahStruk: false,
        namaToko: null,
        tanggal: null,
        total: null,
        kategoriUsulan: null,
        keyakinan: 0.0,
      );

      await cubit.prosesPindai(
        imagePath: '/tmp/kucing.png',
        daftarKategori: ['makan'],
      );

      expect(cubit.state.status, PindaiStatus.gagal);
      expect(cubit.state.pesanGalat, 'Ini sepertinya bukan struk belanja');
      expect(cubit.state.tawarkanCatatManual, isFalse);
    });

    test(
      'prosesPindai batas waktu habis (408) menawarkan pencatatan manual',
      () async {
        fakePindaiRepo.errorToThrow = const GeminiException(
          'Waktu tunggu pemindaian habis (melebihi 15 detik)',
          408,
        );

        await cubit.prosesPindai(
          imagePath: '/tmp/struk.png',
          daftarKategori: ['makan'],
        );

        expect(cubit.state.status, PindaiStatus.gagal);
        expect(cubit.state.pesanGalat, contains('melebihi 15 detik'));
        expect(cubit.state.tawarkanCatatManual, isTrue);
      },
    );

    test(
      'prosesPindai server sibuk (503) menawarkan pencatatan manual',
      () async {
        fakePindaiRepo.errorToThrow = const GeminiException(
          'Layanan sedang sibuk, coba beberapa saat lagi',
          503,
        );

        await cubit.prosesPindai(
          imagePath: '/tmp/struk.png',
          daftarKategori: ['makan'],
        );

        expect(cubit.state.status, PindaiStatus.gagal);
        expect(cubit.state.tawarkanCatatManual, isTrue);
      },
    );

    test(
      'prosesPindai kuota habis (429) tidak menawarkan pencatatan manual',
      () async {
        fakePindaiRepo.errorToThrow = const GeminiException(
          'Kuota pemindaian pekan ini sudah habis (maksimal 10x per pekan). Coba lagi pekan depan.',
          429,
        );

        await cubit.prosesPindai(
          imagePath: '/tmp/struk.png',
          daftarKategori: ['makan'],
        );

        expect(cubit.state.status, PindaiStatus.gagal);
        expect(cubit.state.pesanGalat, contains('sudah habis'));
        expect(cubit.state.tawarkanCatatManual, isFalse);
      },
    );

    test(
      'prosesPindai galat tak terduga mengubah status menjadi gagal',
      () async {
        fakePindaiRepo.errorToThrow = Exception('Koneksi terputus tiba-tiba');

        await cubit.prosesPindai(
          imagePath: '/tmp/struk.png',
          daftarKategori: ['makan'],
        );

        expect(cubit.state.status, PindaiStatus.gagal);
        expect(cubit.state.pesanGalat, contains('Terjadi galat tak terduga'));
      },
    );

    test(
      'simpanTransaksi berhasil menyimpan data dengan sumber pindai',
      () async {
        final hasil = await cubit.simpanTransaksi(
          jumlah: 45000,
          kategoriId: 1,
          tanggal: '2026-10-14',
          catatan: 'Belanja mingguan',
          namaToko: 'Indomaret Sempaja',
        );

        expect(hasil, isTrue);
        expect(cubit.state.status, PindaiStatus.tersimpan);
        expect(fakeTransaksiRepo.transaksiTersimpan, isNotNull);
        expect(fakeTransaksiRepo.transaksiTersimpan?.jumlah, 45000);
        expect(fakeTransaksiRepo.transaksiTersimpan?.kategoriId, 1);
        expect(fakeTransaksiRepo.transaksiTersimpan?.tanggal, '2026-10-14');
        expect(
          fakeTransaksiRepo.transaksiTersimpan?.namaToko,
          'Indomaret Sempaja',
        );
        expect(
          fakeTransaksiRepo.transaksiTersimpan?.catatan,
          'Belanja mingguan',
        );
        expect(fakeTransaksiRepo.transaksiTersimpan?.sumber, 'pindai');
      },
    );

    test('simpanTransaksi gagal mengubah status menjadi gagal dan mengembalikan false', () async {
      fakeTransaksiRepo.shouldThrow = true;

      final hasil = await cubit.simpanTransaksi(
        jumlah: 20000,
        kategoriId: 2,
        tanggal: '2026-10-14',
      );

      expect(hasil, isFalse);
      expect(cubit.state.status, PindaiStatus.gagal);
      expect(cubit.state.pesanGalat, contains('Gagal menyimpan transaksi'));
    });

    test(
      'reset mengembalikan status ke awal namun mempertahankan kuota',
      () async {
        fakePindaiRepo.kuota = 5;
        await cubit.inisialisasi();
        cubit.emit(cubit.state.copyWith(status: PindaiStatus.butuhKonfirmasi));

        cubit.reset();

        expect(cubit.state.status, PindaiStatus.awal);
        expect(cubit.state.sisaKuota, 5);
        expect(cubit.state.hasilPindai, isNull);
      },
    );

    test('batalkanPindai membatalkan CancelToken dan mereset state (No 5 & No 38)', () async {
      fakePindaiRepo.kuota = 8;
      await cubit.inisialisasi();

      final future = cubit.prosesPindai(
        imagePath: '/tmp/struk.png',
        daftarKategori: ['makan'],
      );

      expect(cubit.state.status, PindaiStatus.memuat);
      expect(fakePindaiRepo.capturedCancelToken, isNotNull);
      expect(fakePindaiRepo.capturedCancelToken!.isCancelled, isFalse);

      cubit.batalkanPindai();

      expect(fakePindaiRepo.capturedCancelToken!.isCancelled, isTrue);
      expect(cubit.state.status, PindaiStatus.awal);
      expect(cubit.state.sisaKuota, 8);

      await future;
      // Memastikan kuota tidak berkurang dan state tetap awal
      expect(cubit.state.status, PindaiStatus.awal);
      expect(cubit.state.sisaKuota, 8);
    });

    test('prosesPindai dengan statusCode 400 (kunci belum aktif No 33) menawarkan catat manual', () async {
      fakePindaiRepo.errorToThrow = const GeminiException(
        'Pindai struk belum aktif di versi ini',
        400,
      );

      await cubit.prosesPindai(
        imagePath: '/tmp/struk.png',
        daftarKategori: ['makan'],
      );

      expect(cubit.state.status, PindaiStatus.gagal);
      expect(cubit.state.pesanGalat, 'Pindai struk belum aktif di versi ini');
      expect(cubit.state.tawarkanCatatManual, isTrue);
    });

    test('prosesPindai dengan statusCode 408 (timeout 15 detik No 6) menawarkan catat manual', () async {
      fakePindaiRepo.errorToThrow = const GeminiException(
        'Waktu tunggu pemindaian habis (melebihi 15 detik)',
        408,
      );

      await cubit.prosesPindai(
        imagePath: '/tmp/struk.png',
        daftarKategori: ['makan'],
      );

      expect(cubit.state.status, PindaiStatus.gagal);
      expect(cubit.state.pesanGalat, contains('melebihi 15 detik'));
      expect(cubit.state.tawarkanCatatManual, isTrue);
    });

    test('menutup cubit saat memuat membatalkan CancelToken dan tidak crash emit (No 38)', () async {
      fakePindaiRepo.kuota = 6;
      await cubit.inisialisasi();

      final future = cubit.prosesPindai(
        imagePath: '/tmp/struk.png',
        daftarKategori: ['makan'],
      );

      expect(fakePindaiRepo.capturedCancelToken, isNotNull);

      await cubit.close();

      expect(fakePindaiRepo.capturedCancelToken!.isCancelled, isTrue);
      // Menunggu future selesai, tidak boleh ada exception emit after close
      await future;
    });
  });
}
