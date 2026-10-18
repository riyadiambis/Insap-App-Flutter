import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/pindai/domain/entities/hasil_pindai_entity.dart';
import 'package:insap/features/pindai/domain/repositories/pindai_repository.dart';
import 'package:insap/features/pindai/domain/usecases/ambil_kuota_pindai.dart';
import 'package:insap/features/pindai/domain/usecases/pindai_struk.dart';
import 'package:insap/features/pindai/presentation/cubit/pindai_cubit.dart';
import 'package:insap/features/pindai/presentation/pages/halaman_konfirmasi_draf.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_riwayat.dart';
import 'package:insap/features/transaksi/domain/usecases/hapus_transaksi.dart';
import 'package:insap/features/transaksi/domain/usecases/tambah_transaksi.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';

class _FakeKategoriRepository implements KategoriRepository {
  @override
  Future<List<KategoriEntity>> ambilSemua() async => const [
    KategoriEntity(
      id: 1,
      nama: 'Makan',
      ikon: 'restaurant',
      warna: '#E8734A',
      kelompokKakeibo: 'esensial',
      bawaan: 1,
      urutan: 1,
    ),
    KategoriEntity(
      id: 2,
      nama: 'Transport',
      ikon: 'directions_car',
      warna: '#4A90E2',
      kelompokKakeibo: 'esensial',
      bawaan: 1,
      urutan: 2,
    ),
  ];
}

class _FakeTransaksiRepository implements TransaksiRepository {
  TransaksiEntity? transaksiTersimpan;

  @override
  Future<int> simpan(TransaksiEntity transaksi) async {
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
}

class _FakePindaiRepository implements PindaiRepository {
  @override
  Future<HasilPindaiEntity> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
    CancelToken? cancelToken,
  }) async => const HasilPindaiEntity(adalahStruk: true, keyakinan: 0.9);

  @override
  Future<int> ambilSisaKuota() async => 10;

  @override
  Future<void> potongKuota() async {}
}

void main() {
  late _FakeKategoriRepository fakeKatRepo;
  late _FakeTransaksiRepository fakeTransRepo;
  late _FakePindaiRepository fakePindaiRepo;
  late KategoriCubit kategoriCubit;
  late PindaiCubit pindaiCubit;
  late BerandaCubit berandaCubit;
  late RiwayatCubit riwayatCubit;

  setUp(() {
    GetIt.instance.reset();
    fakeKatRepo = _FakeKategoriRepository();
    fakeTransRepo = _FakeTransaksiRepository();
    fakePindaiRepo = _FakePindaiRepository();

    kategoriCubit = KategoriCubit(ambilKategori: AmbilKategori(fakeKatRepo));
    pindaiCubit = PindaiCubit(
      pindaiStruk: PindaiStruk(fakePindaiRepo),
      ambilKuotaPindai: AmbilKuotaPindai(fakePindaiRepo),
      tambahTransaksi: TambahTransaksi(fakeTransRepo),
    );
    berandaCubit = BerandaCubit(
      ambilRingkasanPekan: AmbilRingkasanPekan(fakeTransRepo),
    );
    riwayatCubit = RiwayatCubit(
      ambilRiwayat: AmbilRiwayat(fakeTransRepo),
      hapusTransaksi: HapusTransaksi(fakeTransRepo),
      tambahTransaksi: TambahTransaksi(fakeTransRepo),
    );
  });

  tearDown(() {
    kategoriCubit.close();
    pindaiCubit.close();
    berandaCubit.close();
    riwayatCubit.close();
    GetIt.instance.reset();
  });

  Widget bangunAplikasiUji(HasilPindaiEntity hasil) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<KategoriCubit>.value(value: kategoriCubit..muat()),
        BlocProvider<PindaiCubit>.value(value: pindaiCubit),
        BlocProvider<BerandaCubit>.value(value: berandaCubit),
        BlocProvider<RiwayatCubit>.value(value: riwayatCubit),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: HalamanKonfirmasiDraf(hasilPindai: hasil),
      ),
    );
  }

  group('HalamanKonfirmasiDraf', () {
    testWidgets('menampilkan kolom formulir dengan data ekstraksi AI', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const tHasil = HasilPindaiEntity(
        adalahStruk: true,
        namaToko: 'Indomaret Point',
        tanggal: '2026-10-14',
        total: 54000,
        kategoriUsulan: 'makan',
        keyakinan: 0.88,
      );

      await tester.pumpWidget(bangunAplikasiUji(tHasil));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Draf Struk'), findsOneWidget);
      expect(find.text('54000'), findsOneWidget);
      expect(find.text('Indomaret Point'), findsOneWidget);
      expect(find.text('2026-10-14'), findsOneWidget);
      expect(find.text('Simpan ke Transaksi'), findsOneWidget);
      // Keyakinan >= 0.5 tidak memunculkan peringatan
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('menampilkan peringatan jika keyakinan < 0.5', (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const tHasil = HasilPindaiEntity(
        adalahStruk: true,
        namaToko: 'Warung Bu Sri',
        tanggal: '2026-10-14',
        total: 23000,
        kategoriUsulan: 'makan',
        keyakinan: 0.40,
      );

      await tester.pumpWidget(bangunAplikasiUji(tHasil));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.textContaining('Hasil bacaan kurang yakin (40%)'),
        findsOneWidget,
      );
    });

    testWidgets(
      'menyimpan draf transaksi dengan sumber pindai saat tombol ditekan',
      (tester) async {
        tester.view.physicalSize = const Size(460, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const tHasil = HasilPindaiEntity(
          adalahStruk: true,
          namaToko: 'SPBU Shell',
          tanggal: '2026-10-14',
          total: 100000,
          kategoriUsulan: 'transport',
          keyakinan: 0.90,
        );

        await tester.pumpWidget(bangunAplikasiUji(tHasil));
        await tester.pumpAndSettle();

        final tombolSimpan = find.text('Simpan ke Transaksi');
        expect(tombolSimpan, findsOneWidget);

        await tester.tap(tombolSimpan);
        await tester.pumpAndSettle();

        expect(fakeTransRepo.transaksiTersimpan, isNotNull);
        expect(fakeTransRepo.transaksiTersimpan?.jumlah, 100000);
        expect(fakeTransRepo.transaksiTersimpan?.namaToko, 'SPBU Shell');
        expect(fakeTransRepo.transaksiTersimpan?.sumber, 'pindai');
      },
    );
  });
}
