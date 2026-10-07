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
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_riwayat.dart';
import 'package:insap/features/transaksi/domain/usecases/hapus_transaksi.dart';
import 'package:insap/features/transaksi/domain/usecases/tambah_transaksi.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';
import 'package:insap/features/transaksi/presentation/riwayat/pages/halaman_riwayat.dart';
import 'package:insap/features/transaksi/presentation/riwayat/widgets/riwayat_helper.dart';

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
        KategoriEntity(
          id: 2,
          nama: 'jajan',
          ikon: 'local_cafe',
          warna: '#4A9BE8',
          kelompokKakeibo: 'opsional',
          bawaan: 1,
          urutan: 2,
        ),
      ];
}

class _FakeTransaksiRepository implements TransaksiRepository {
  List<TransaksiEntity> daftarKembalian = [];
  int idTerhapus = 0;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    return daftarKembalian;
  }

  @override
  Future<int> hapus(int id) async {
    idTerhapus = id;
    return 1;
  }

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

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
    getIt.registerLazySingleton(() => AmbilRiwayat(getIt()));
    getIt.registerLazySingleton(() => HapusTransaksi(getIt()));
    getIt.registerLazySingleton(() => TambahTransaksi(getIt()));
    getIt.registerLazySingleton(() => AmbilRingkasanPekan(getIt()));

    getIt.registerFactory(() => RiwayatCubit(
          ambilRiwayat: getIt(),
          hapusTransaksi: getIt(),
          tambahTransaksi: getIt(),
        ));
    getIt.registerFactory(() => BerandaCubit(ambilRingkasanPekan: getIt()));
  });

  tearDown(() => GetIt.instance.reset());

  Widget bangunAplikasiUji() {
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
        home: const HalamanRiwayat(),
      ),
    );
  }

  testWidgets(
    'menampilkan pesan ajakan mencatat jika riwayat masih kosong',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeTransRepo.daftarKembalian = [];

      await tester.pumpWidget(bangunAplikasiUji());
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Catatan Boncos'), findsOneWidget);
      expect(find.text('Catat Pengeluaran'), findsOneWidget);
    },
  );

  testWidgets(
    'menampilkan daftar transaksi dikelompokkan per tanggal',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tglHariIni = RiwayatHelper.toIsoDate(DateTime.now());
      fakeTransRepo.daftarKembalian = [
        TransaksiEntity(
          id: 1,
          jumlah: 25000,
          kategoriId: 1,
          tanggal: tglHariIni,
          catatan: 'Nasi padang komplit',
          dibuatPada: '${tglHariIni}T12:30:00.000',
          tipeKebutuhan: 'butuh',
          sumber: 'manual',
        ),
        TransaksiEntity(
          id: 2,
          jumlah: 18000,
          kategoriId: 2,
          tanggal: tglHariIni,
          catatan: 'Es kopi susu',
          dibuatPada: '${tglHariIni}T15:00:00.000',
          tipeKebutuhan: 'pengen',
          sumber: 'pindai',
        ),
      ];

      await tester.pumpWidget(bangunAplikasiUji());
      await tester.pumpAndSettle();

      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Nasi padang komplit'), findsOneWidget);
      expect(find.text('Es kopi susu'), findsOneWidget);
      // Memeriksa penanda struk untuk sumber pindai
      expect(find.textContaining('Struk'), findsOneWidget);
    },
  );

  testWidgets(
    'membuka bottom sheet filter saat tombol filter ditekan',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(bangunAplikasiUji());
      await tester.pumpAndSettle();

      final tombolFilter = find.byIcon(Icons.tune_rounded);
      expect(tombolFilter, findsOneWidget);

      await tester.tap(tombolFilter);
      await tester.pumpAndSettle();

      expect(find.text('Saringan Riwayat'), findsOneWidget);
      expect(find.text('Terapkan Saringan'), findsOneWidget);
      expect(find.text('Reset Saringan'), findsOneWidget);
    },
  );
}
