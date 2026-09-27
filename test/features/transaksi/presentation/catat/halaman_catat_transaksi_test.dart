import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:insap/core/di/injection_container.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/tambah_transaksi.dart';
import 'package:insap/features/transaksi/presentation/catat/cubit/catat_transaksi_cubit.dart';
import 'package:insap/features/transaksi/presentation/catat/pages/halaman_catat_transaksi.dart';

// repo palsu tanpa library tambahan
class _FakeKategoriRepository implements KategoriRepository {
  @override
  Future<List<KategoriEntity>> ambilSemua() async => const [
        KategoriEntity(
          id: 1,
          nama: 'makan',
          ikon: 'restaurant',
          warna: '#E8734A',
          kelompokKakeibo: 'esensial',
          bawaan: 1,
          urutan: 1,
        ),
      ];
}

class _FakeTransaksiRepository implements TransaksiRepository {
  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async =>
      const [];

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;
}

void main() {
  setUp(() {
    final getIt = GetIt.instance;
    getIt.reset();

    final fakeKatRepo = _FakeKategoriRepository();
    final fakeTransRepo = _FakeTransaksiRepository();

    getIt.registerLazySingleton<KategoriRepository>(() => fakeKatRepo);
    getIt.registerLazySingleton(() => AmbilKategori(getIt()));
    getIt.registerFactory(() => KategoriCubit(ambilKategori: getIt()));

    getIt.registerLazySingleton<TransaksiRepository>(() => fakeTransRepo);
    getIt.registerLazySingleton(() => TambahTransaksi(getIt()));
    getIt.registerLazySingleton(() => AmbilRingkasanPekan(getIt()));
    getIt.registerFactory(
        () => CatatTransaksiCubit(tambahTransaksi: getIt()));
    getIt.registerFactory(
        () => BerandaCubit(ambilRingkasanPekan: getIt()));
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets(
    'menekan simpan dengan nominal kosong menampilkan pesan validasi',
    (tester) async {
      // pakai layar tinggi biar form cukup tanpa scroll
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => sl<KategoriCubit>()..muat(),
            ),
            BlocProvider(
              create: (_) => sl<BerandaCubit>()..muatRingkasan(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HalamanCatatTransaksi(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // cari dan tekan tombol simpan tanpa mengisi nominal.
      // pakai textContaining karena teks tombol diawali emoji
      final tombol = find.textContaining('Simpan Transaksi');
      expect(tombol, findsOneWidget);
      await tester.tap(tombol);
      await tester.pumpAndSettle();

      // pesan validasi muncul di TextFormField
      expect(find.text('Nominal wajib diisi.'), findsOneWidget);
    },
  );
}
