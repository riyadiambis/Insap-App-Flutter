import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
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
import 'package:insap/features/transaksi/presentation/catat/cubit/catat_transaksi_cubit.dart';
import 'package:insap/features/transaksi/presentation/catat/pages/halaman_catat_transaksi.dart';
import 'package:insap/features/transaksi/presentation/catat/widgets/kolom_input_nominal.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';

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
  final List<TransaksiEntity> tersimpan = [];

  @override
  Future<int> simpan(TransaksiEntity transaksi) async {
    tersimpan.add(transaksi);
    return tersimpan.length;
  }

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async {
    tersimpan.addAll(daftarTransaksi);
    return List.generate(daftarTransaksi.length, (i) => i + 1);
  }

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => tersimpan;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async => tersimpan;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;
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
    getIt.registerLazySingleton(() => TambahTransaksi(getIt()));
    getIt.registerLazySingleton(() => AmbilRingkasanPekan(getIt()));
    getIt.registerLazySingleton(() => AmbilRiwayat(getIt()));
    getIt.registerLazySingleton(() => HapusTransaksi(getIt()));

    getIt.registerFactory(() => CatatTransaksiCubit(tambahTransaksi: getIt()));
    getIt.registerFactory(() => BerandaCubit(ambilRingkasanPekan: getIt()));
    getIt.registerFactory(
      () => RiwayatCubit(
        ambilRiwayat: getIt(),
        hapusTransaksi: getIt(),
        tambahTransaksi: getIt(),
      ),
    );
  });

  tearDown(() => GetIt.instance.reset());

  Widget bangunAplikasiUji() {
    final router = GoRouter(
      initialLocation: '/catat',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Halaman Beranda Dummy')),
        ),
        GoRoute(
          path: '/catat',
          builder: (context, state) => const HalamanCatatTransaksi(),
        ),
      ],
    );

    final sl = GetIt.instance;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<KategoriCubit>()..muat()),
        BlocProvider(create: (_) => sl<BerandaCubit>()..muatRingkasan()),
        BlocProvider(create: (_) => sl<RiwayatCubit>()..muatRiwayat()),
        BlocProvider(create: (_) => sl<CatatTransaksiCubit>()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  testWidgets(
    'simpan transaksi tidak memicu exception build dan kolom nominal kembali kosong',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(bangunAplikasiUji());
      await tester.pumpAndSettle();

      // pastikan KolomInputNominal ada di layar
      expect(find.byType(KolomInputNominal), findsOneWidget);

      // masukkan nominal 25000
      final inputNominalFinder = find.descendant(
        of: find.byType(KolomInputNominal),
        matching: find.byType(TextFormField),
      );
      expect(inputNominalFinder, findsOneWidget);

      await tester.enterText(inputNominalFinder, '25000');
      await tester.pump();
      expect(find.text('Rp25.000'), findsOneWidget);

      // pilih kategori makan (kategori default)
      final chipMakan = find.text('Makan');
      if (chipMakan.evaluate().isNotEmpty) {
        await tester.tap(chipMakan.first);
        await tester.pump();
      }

      // ketuk tombol simpan transaksi
      final tombolSimpan = find.textContaining('Simpan Transaksi');
      await tester.ensureVisible(tombolSimpan);
      await tester.tap(tombolSimpan);
      await tester.pumpAndSettle();

      // pastikan TIDAK ada galat setState() or markNeedsBuild() called during build
      expect(tester.takeException(), isNull);

      // transaksi berhasil disimpan ke repository
      expect(fakeTransRepo.tersimpan.length, equals(1));
      expect(fakeTransRepo.tersimpan.first.jumlah, equals(25000));
    },
  );

  testWidgets(
    'KolomInputNominal reset ke nilai 0 via parent tanpa galat dan teks menjadi kosong',
    (tester) async {
      int nominalState = 30000;
      late StateSetter parentSetState;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                parentSetState = setState;
                return KolomInputNominal(
                  nominal: nominalState,
                  onChanged: (val) {
                    nominalState = val;
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rp30.000'), findsOneWidget);

      // reset nilai dari parent ke 0 seperti saat form direset
      parentSetState(() {
        nominalState = 0;
      });
      await tester.pumpAndSettle();

      // bebas exception siklus hidup widget
      expect(tester.takeException(), isNull);

      // teks nominal kembali kosong
      expect(find.text('Rp30.000'), findsNothing);
      expect(find.text(''), findsOneWidget);
    },
  );
}
