import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:insap/core/di/injection_container.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_detail_transaksi.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'package:insap/features/transaksi/domain/usecases/hapus_transaksi.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/detail_transaksi_cubit.dart';
import 'package:insap/features/transaksi/presentation/riwayat/pages/halaman_detail_transaksi.dart';

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
  TransaksiEntity? detailTransaksi;
  int idTerhapus = 0;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => detailTransaksi;

  @override
  Future<int> hapus(int id) async {
    idTerhapus = id;
    return 1;
  }

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async =>
      const [];

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;
}

void main() {
  late _FakeKategoriRepository fakeKatRepo;
  late _FakeTransaksiRepository fakeTransRepo;

  setUp(() {
    final getIt = GetIt.instance;
    getIt.reset();

    fakeKatRepo = _FakeKategoriRepository();
    fakeTransRepo = _FakeTransaksiRepository();

    getIt.registerLazySingleton<KategoriRepository>(() => fakeKatRepo);
    getIt.registerLazySingleton(() => AmbilKategori(getIt()));
    getIt.registerFactory(() => KategoriCubit(ambilKategori: getIt()));

    getIt.registerLazySingleton<TransaksiRepository>(() => fakeTransRepo);
    getIt.registerLazySingleton(() => AmbilDetailTransaksi(getIt()));
    getIt.registerLazySingleton(() => HapusTransaksi(getIt()));
    getIt.registerLazySingleton(() => AmbilRingkasanPekan(getIt()));

    getIt.registerFactory(() => DetailTransaksiCubit(
          ambilDetailTransaksi: getIt(),
          hapusTransaksi: getIt(),
        ));
    getIt.registerFactory(() => BerandaCubit(ambilRingkasanPekan: getIt()));
  });

  tearDown(() => GetIt.instance.reset());

  Widget bangunAplikasiUji(int id) {
    return MultiBlocProvider(
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
        home: HalamanDetailTransaksi(id: id),
      ),
    );
  }

  testWidgets(
    'menampilkan informasi detail transaksi dengan lengkap',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeTransRepo.detailTransaksi = const TransaksiEntity(
        id: 10,
        jumlah: 35000,
        kategoriId: 1,
        tanggal: '2026-09-28',
        catatan: 'Makan siang bareng tim',
        dibuatPada: '2026-09-28T12:30:00.000',
        tipeKebutuhan: 'butuh',
        sumber: 'manual',
      );

      await tester.pumpWidget(bangunAplikasiUji(10));
      await tester.pumpAndSettle();

      expect(find.text('Detail Transaksi'), findsOneWidget);
      expect(find.text('Makan'), findsOneWidget);
      expect(find.text('-Rp35.000'), findsOneWidget);
      expect(find.text('Makan siang bareng tim'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Hapus Transaksi'), findsOneWidget);
    },
  );

  testWidgets(
    'menampilkan pesan ramah jika transaksi tidak ditemukan',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeTransRepo.detailTransaksi = null;

      await tester.pumpWidget(bangunAplikasiUji(999999));
      await tester.pumpAndSettle();

      expect(find.text('Transaksi ini sudah tidak ada'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
    },
  );

  testWidgets(
    'menampilkan dialog konfirmasi saat tombol hapus ditekan',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeTransRepo.detailTransaksi = const TransaksiEntity(
        id: 10,
        jumlah: 35000,
        kategoriId: 1,
        tanggal: '2026-09-28',
        dibuatPada: '2026-09-28T12:30:00.000',
      );

      await tester.pumpWidget(bangunAplikasiUji(10));
      await tester.pumpAndSettle();

      final tombolHapus = find.text('Hapus Transaksi');
      expect(tombolHapus, findsOneWidget);

      await tester.tap(tombolHapus);
      await tester.pumpAndSettle();

      expect(find.text('Hapus Transaksi?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
    },
  );
}
