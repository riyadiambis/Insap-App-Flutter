import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/constants/kuota_constants.dart';
import 'package:insap/core/iklan/layanan_iklan.dart';
import 'package:insap/core/paper_background.dart';
import 'package:insap/core/router/app_shell.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/beranda/presentation/pages/halaman_beranda.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';
import 'package:insap/features/pengaturan/domain/usecases/baca_status_panduan_pindai.dart';
import 'package:insap/features/pindai/domain/entities/hasil_pindai_entity.dart';
import 'package:insap/features/pindai/domain/repositories/pindai_repository.dart';
import 'package:insap/features/pindai/domain/usecases/ambil_kuota_pindai.dart';
import 'package:insap/features/pindai/domain/usecases/ambil_sisa_bonus_iklan.dart';
import 'package:insap/features/pindai/domain/usecases/klaim_bonus_iklan.dart';
import 'package:insap/features/pindai/domain/usecases/pindai_struk.dart';
import 'package:insap/features/pindai/domain/usecases/simpan_transaksi_pindai.dart';
import 'package:insap/features/pindai/presentation/cubit/pindai_cubit.dart';
import 'package:insap/features/pindai/presentation/pages/halaman_konfirmasi_pindai.dart';
import 'package:insap/features/pindai/presentation/pages/halaman_pindai.dart';
import 'package:insap/features/pindai/domain/entities/barang_pindai.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_rincian_kategori.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_riwayat.dart';
import 'package:insap/features/transaksi/domain/usecases/hapus_transaksi.dart';
import 'package:insap/features/transaksi/domain/usecases/tambah_transaksi.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';
import 'package:insap/features/transaksi/presentation/riwayat/pages/halaman_riwayat.dart';

class _FakeKategoriRepo implements KategoriRepository {
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

class _FakePengaturanRepo implements PengaturanRepository {
  @override
  Future<String?> bacaPengaturan(String kunci) async => '1';

  @override
  Future<bool> bacaStatusOnboarding() async => true;

  @override
  Future<int?> bacaTargetBulanan() async => 2000000;

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {}

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {}

  @override
  Future<void> simpanTargetBulanan(int target) async {}
}

class _FakePindaiDanTransaksiRepo
    implements TransaksiRepository, PindaiRepository {
  int kuota = 0;
  int sisaBonus = 10;
  List<TransaksiEntity> daftar = [];

  @override
  Future<int> ambilKuotaPindai() async => kuota;

  @override
  Future<int> ambilSisaKuota() async => kuota;

  @override
  Future<int> ambilSisaBonusIklan() async => sisaBonus;

  @override
  Future<bool> klaimBonusIklan() async {
    if (sisaBonus <= 0) return false;
    sisaBonus--;
    kuota++;
    return true;
  }

  @override
  Future<void> potongKuota() async {
    if (kuota > 0) kuota--;
  }

  @override
  Future<HasilPindaiEntity> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
    Map<String, int>? petaKategoriId,
    CancelToken? cancelToken,
  }) async => const HasilPindaiEntity(adalahStruk: true, keyakinan: 0.9);

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async => daftar;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async =>
      daftar.take(batas).toList();

  @override
  Future<int> hapus(int id) async => 1;

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async =>
      List.generate(daftarTransaksi.length, (i) => i + 1);

  @override
  Future<int> totalMingguIni(String a, String b) async => 412500;

  @override
  Future<int> totalRentang(String a, String b) async => 412500;
}

class _FakeLayananIklanSukses implements LayananIklan {
  final _notif = ValueNotifier<bool>(false);

  @override
  bool get bolehMintaIklan => true;

  @override
  bool get perluTombolPrivasi => false;

  @override
  ValueListenable<bool> get perluTombolPrivasiListenable => _notif;

  @override
  Future<void> siapkan() async {}

  @override
  Future<void> tampilkanOpsiPrivasi() async {}

  @override
  Future<bool> tontonIklanBonus() async => true;
}

Future<void> _muatFont(String keluarga, List<String> berkas) async {
  final loader = FontLoader(keluarga);
  for (final b in berkas) {
    loader.addFont(rootBundle.load('assets/fonts/$b'));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _muatFont('Nunito', [
      'Nunito-Regular.ttf',
      'Nunito-SemiBold.ttf',
      'Nunito-Bold.ttf',
      'Nunito-ExtraBold.ttf',
    ]);
    await _muatFont('Baloo2', [
      'Baloo2-SemiBold.ttf',
      'Baloo2-Bold.ttf',
      'Baloo2-ExtraBold.ttf',
    ]);
  });

  group('Latar polos tanpa grid', () {
    testWidgets(
      'PaperBackground merender latar polos AppColors.paper tanpa CustomPaint grid',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PaperBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Text('Konten'),
              ),
            ),
          ),
        );

        expect(
          find.descendant(
            of: find.byType(PaperBackground),
            matching: find.byType(CustomPaint),
          ),
          findsNothing,
        );
        final coloredBox = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(PaperBackground),
            matching: find.byType(ColoredBox),
          ).first,
        );
        expect(coloredBox.color, AppColors.paper);
      },
    );
  });

  group('Beranda kuota ringkas & muat ulang setelah /pindai + latar depan', () {
    late _FakePindaiDanTransaksiRepo repo;
    late _FakeKategoriRepo katRepo;
    late _FakePengaturanRepo pengaturanRepo;
    late _FakeLayananIklanSukses iklan;

    setUp(() async {
      final sl = GetIt.instance;
      await sl.reset();
      repo = _FakePindaiDanTransaksiRepo();
      katRepo = _FakeKategoriRepo();
      pengaturanRepo = _FakePengaturanRepo();
      iklan = _FakeLayananIklanSukses();

      sl.registerSingleton<BacaStatusPanduanPindai>(
        BacaStatusPanduanPindai(pengaturanRepo),
      );
      sl.registerSingleton<SimpanTransaksiPindai>(
        SimpanTransaksiPindai(repo),
      );
      sl.registerFactory<PindaiCubit>(
        () => PindaiCubit(
          pindaiStruk: PindaiStruk(repo),
          ambilKuotaPindai: AmbilKuotaPindai(repo),
          tambahTransaksi: TambahTransaksi(repo),
          ambilSisaBonusIklan: AmbilSisaBonusIklan(repo),
          klaimBonusIklanUseCase: KlaimBonusIklan(repo),
          layananIklan: iklan,
        ),
      );
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    testWidgets(
      'kuota 0 -> buka /pindai dari Beranda -> tonton iklan -> kembali -> Beranda menampilkan "Sisa 1 dari $kuotaPindaiPekanan"',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        repo.kuota = 0;
        final katCubit = KategoriCubit(ambilKategori: AmbilKategori(katRepo))
          ..muat();
        final berandaCubit = BerandaCubit(
          ambilRingkasanPekan: AmbilRingkasanPekan(repo),
          ambilRincianKategori: AmbilRincianKategori(repo),
        )..muatRingkasan();
        addTearDown(katCubit.close);
        addTearDown(berandaCubit.close);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HalamanBeranda(),
            ),
            GoRoute(
              path: '/pindai',
              builder: (context, state) => BlocProvider(
                create: (_) => GetIt.I<PindaiCubit>(),
                child: const HalamanPindai(mulaiLangsung: false),
              ),
            ),
            GoRoute(
              path: '/catat',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/refleksi',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/riwayat',
              builder: (context, state) => const SizedBox(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<KategoriCubit>.value(value: katCubit),
              BlocProvider<BerandaCubit>.value(value: berandaCubit),
            ],
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Habis, tonton iklan +1'), findsOneWidget);

        await tester.tap(find.text('Pindai struk'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('tombol_bonus_iklan')), findsOneWidget);
        await tester.tap(find.byKey(const Key('tombol_bonus_iklan')));
        await tester.pumpAndSettle();
        expect(repo.kuota, 1);

        // Kembali ke Beranda
        await tester.tap(find.bySemanticsLabel('Kembali'));
        await tester.pumpAndSettle();

        expect(
          find.text('Sisa 1 dari $kuotaPindaiPekanan'),
          findsOneWidget,
        );
        expect(find.text('Habis, tonton iklan +1'), findsNothing);
      },
    );

    testWidgets(
      'Beranda memuat ulang kuota ketika aplikasi kembali ke latar depan (resumed)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        repo.kuota = 2;
        final katCubit = KategoriCubit(ambilKategori: AmbilKategori(katRepo))
          ..muat();
        final berandaCubit = BerandaCubit(
          ambilRingkasanPekan: AmbilRingkasanPekan(repo),
          ambilRincianKategori: AmbilRincianKategori(repo),
        )..muatRingkasan();
        addTearDown(katCubit.close);
        addTearDown(berandaCubit.close);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<KategoriCubit>.value(value: katCubit),
              BlocProvider<BerandaCubit>.value(value: berandaCubit),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const HalamanBeranda(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Sisa 2 dari $kuotaPindaiPekanan'),
          findsOneWidget,
        );

        repo.kuota = 4;
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        expect(
          find.text('Sisa 4 dari $kuotaPindaiPekanan'),
          findsOneWidget,
        );
      },
    );
  });

  group('Tata letak Tablet h27-h29 (800x1280 skala 1.5x)', () {
    late _FakePindaiDanTransaksiRepo repo;
    late _FakeKategoriRepo katRepo;

    setUp(() async {
      final sl = GetIt.instance;
      await sl.reset();
      repo = _FakePindaiDanTransaksiRepo()
        ..kuota = 3
        ..daftar = [
          const TransaksiEntity(
            id: 1,
            jumlah: 78300,
            kategoriId: 1,
            tanggal: '2026-11-20',
            catatan: 'Indomaret',
            sumber: 'pindai',
            dibuatPada: '2026-11-20T14:12:00.000',
          ),
        ];
      katRepo = _FakeKategoriRepo();
      sl.registerSingleton<SimpanTransaksiPindai>(
        SimpanTransaksiPindai(repo),
      );
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    Widget bungkusTablet(Widget child) {
      return Builder(
        builder: (context) {
          final mq = MediaQuery.of(context);
          final ukuranSkala = mq.size / AppSizes.skalaTablet;
          return Align(
            alignment: Alignment.topLeft,
            child: Transform.scale(
              scale: AppSizes.skalaTablet,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: ukuranSkala.width,
                height: ukuranSkala.height,
                child: MediaQuery(
                  data: mq.copyWith(
                    size: ukuranSkala,
                    devicePixelRatio:
                        mq.devicePixelRatio * AppSizes.skalaTablet,
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('h27 Tablet Beranda tampil tanpa overflow dan maskot utuh', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final katCubit = KategoriCubit(ambilKategori: AmbilKategori(katRepo))
        ..muat();
      final berandaCubit = BerandaCubit(
        ambilRingkasanPekan: AmbilRingkasanPekan(repo),
        ambilRincianKategori: AmbilRincianKategori(repo),
      )..muatRingkasan();
      addTearDown(katCubit.close);
      addTearDown(berandaCubit.close);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => AppShell(navigationShell: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(path: '/', builder: (_, _) => const HalamanBeranda()),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(path: '/catat', builder: (_, _) => const SizedBox()),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/refleksi',
                    builder: (_, _) => const SizedBox(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/riwayat',
                    builder: (_, _) => const SizedBox(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<KategoriCubit>.value(value: katCubit),
            BlocProvider<BerandaCubit>.value(value: berandaCubit),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            builder: (context, child) => bungkusTablet(child!),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('maskot_detektif_beranda')), findsOneWidget);
      expect(find.text('Sisa 3 dari $kuotaPindaiPekanan'), findsOneWidget);
    });

    testWidgets('h28 Tablet Riwayat tampil tanpa overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final katCubit = KategoriCubit(ambilKategori: AmbilKategori(katRepo))
        ..muat();
      final riwayatCubit = RiwayatCubit(
        ambilRiwayat: AmbilRiwayat(repo),
        tambahTransaksi: TambahTransaksi(repo),
        hapusTransaksi: HapusTransaksi(repo),
      )..muatRiwayat();
      addTearDown(katCubit.close);
      addTearDown(riwayatCubit.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<KategoriCubit>.value(value: katCubit),
            BlocProvider<RiwayatCubit>.value(value: riwayatCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => bungkusTablet(child!),
            home: const HalamanRiwayat(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Indomaret'), findsOneWidget);
      expect(find.text('Dari struk'), findsOneWidget);
    });

    testWidgets('h29 Tablet Periksa hasil tampil tanpa overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final katCubit = KategoriCubit(ambilKategori: AmbilKategori(katRepo))
        ..muat();
      final riwayatCubit = RiwayatCubit(
        ambilRiwayat: AmbilRiwayat(repo),
        tambahTransaksi: TambahTransaksi(repo),
        hapusTransaksi: HapusTransaksi(repo),
      );
      addTearDown(katCubit.close);
      addTearDown(riwayatCubit.close);

      const hasil = HasilPindaiEntity(
        adalahStruk: true,
        keyakinan: 0.95,
        namaToko: 'Indomaret Pramuka',
        tanggal: '2026-11-20',
        total: 78300,
        barang: [
          BarangPindai(nama: 'Susu UHT 1L x2', harga: 37800, kategoriId: 1),
          BarangPindai(nama: 'Roti tawar', harga: 16500, kategoriId: 1),
          BarangPindai(nama: 'Telur 10 butir', harga: 24000, kategoriId: 1),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<KategoriCubit>.value(value: katCubit),
            BlocProvider<RiwayatCubit>.value(value: riwayatCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => bungkusTablet(child!),
            home: const HalamanKonfirmasiPindai(hasilPindai: hasil),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Indomaret Pramuka'), findsOneWidget);
      expect(find.text('20 Nov 2026 · 3 barang'), findsOneWidget);
      expect(find.text('Dikelompokkan AI'), findsOneWidget);
    });
  });
}
