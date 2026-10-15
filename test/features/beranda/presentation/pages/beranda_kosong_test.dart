import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/router/app_shell.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/header_aplikasi.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_state.dart';
import 'package:insap/features/beranda/presentation/pages/halaman_beranda.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/pengaturan/domain/usecases/ambil_target_bulanan.dart';
import 'package:insap/features/pengaturan/domain/usecases/hitung_perbandingan_target.dart';
import 'package:insap/features/pengaturan/domain/usecases/simpan_target_bulanan.dart';
import 'package:insap/features/transaksi/domain/entities/rincian_pengeluaran_entity.dart';
import 'package:insap/features/transaksi/domain/entities/ringkasan_pekan_entity.dart';
import 'package:insap/features/transaksi/domain/entities/total_kategori_entity.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_rincian_kategori.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';

class _FakeKategoriRepository implements KategoriRepository {
  final List<KategoriEntity> data;
  _FakeKategoriRepository(this.data);

  @override
  Future<List<KategoriEntity>> ambilSemua() async => data;
}

class _FakeBerandaCubit extends Cubit<BerandaState> implements BerandaCubit {
  final RingkasanPekanEntity ringkasan;
  final RincianPengeluaranEntity rincian;

  _FakeBerandaCubit({required this.ringkasan, required this.rincian})
      : super(BerandaLoaded(ringkasan, rincian));

  @override
  AmbilRingkasanPekan get ambilRingkasanPekan => throw UnimplementedError();

  @override
  AmbilRincianKategori? get ambilRincianKategori => null;

  @override
  AmbilTargetBulanan? get ambilTargetBulanan => null;

  @override
  SimpanTargetBulanan? get simpanTargetBulanan => null;

  @override
  HitungPerbandinganTarget get hitungPerbandinganTarget =>
      const HitungPerbandinganTarget();

  @override
  Future<void> muatRingkasan() async {
    emit(BerandaLoaded(ringkasan, rincian));
  }

  @override
  Future<void> ubahTarget(int targetBaru) async {}
}

void main() {
  late _FakeKategoriRepository kategoriRepo;
  late KategoriCubit kategoriCubit;

  final dummyKategori = [
    const KategoriEntity(
      id: 1,
      nama: 'makan',
      ikon: 'restaurant',
      warna: '#E8734A',
      kelompokKakeibo: 'esensial',
      bawaan: 1,
      urutan: 1,
    ),
  ];

  setUp(() {
    kategoriRepo = _FakeKategoriRepository(dummyKategori);
    kategoriCubit = KategoriCubit(ambilKategori: AmbilKategori(kategoriRepo))..muat();
  });

  tearDown(() {
    kategoriCubit.close();
  });

  testWidgets(
      'keadaan kosong tampil saat 0 transaksi dan tombol menuju ke /catat',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const ringkasanKosong = RingkasanPekanEntity(
      totalMingguIni: 0,
      totalMingguLalu: 0,
      selisihMingguan: 0,
      transaksiTerakhir: [],
      kuotaPindai: 10,
    );

    const rincianKosong = RincianPengeluaranEntity(
      totalBulanIni: 0,
      kategoriPekanIni: [],
      kategoriBulanIni: [],
    );

    final berandaCubit = _FakeBerandaCubit(
      ringkasan: ringkasanKosong,
      rincian: rincianKosong,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<BerandaCubit>.value(value: berandaCubit),
              BlocProvider<KategoriCubit>.value(value: kategoriCubit),
            ],
            child: const HalamanBeranda(),
          ),
        ),
        GoRoute(
          path: '/catat',
          builder: (context, state) => const Scaffold(
            body: Text('Halaman Catat Transaksi'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    // Pastikan elemen keadaan kosong Beranda tampil
    expect(find.text('Belum Ada Pengeluaran yang Dicatat'), findsOneWidget);
    expect(find.text('Tips Cepat'), findsOneWidget);
    expect(find.byKey(const Key('tombol_catat_pertama')), findsOneWidget);

    // Ketuk tombol catat pengeluaran pertama
    await tester.tap(find.byKey(const Key('tombol_catat_pertama')));
    await tester.pumpAndSettle();

    // Rute berhasil berpindah ke /catat
    expect(find.text('Halaman Catat Transaksi'), findsOneWidget);
    expect(find.text('Belum Ada Pengeluaran yang Dicatat'), findsNothing);
  });

  testWidgets(
      'keadaan kosong hilang saat ada minimal satu transaksi',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final ringkasanAdaTransaksi = RingkasanPekanEntity(
      totalMingguIni: 25000,
      totalMingguLalu: 0,
      selisihMingguan: 25000,
      transaksiTerakhir: const [
        TransaksiEntity(
          id: 1,
          jumlah: 25000,
          kategoriId: 1,
          tanggal: '2026-10-15',
          catatan: 'Nasi goreng',
          dibuatPada: '2026-10-15T00:00:00Z',
        ),
      ],
      kuotaPindai: 10,
    );

    const rincianAda = RincianPengeluaranEntity(
      totalBulanIni: 25000,
      kategoriPekanIni: [
        TotalKategoriEntity(kategoriId: 1, total: 25000),
      ],
      kategoriBulanIni: [
        TotalKategoriEntity(kategoriId: 1, total: 25000),
      ],
    );

    final berandaCubit = _FakeBerandaCubit(
      ringkasan: ringkasanAdaTransaksi,
      rincian: rincianAda,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<BerandaCubit>.value(value: berandaCubit),
              BlocProvider<KategoriCubit>.value(value: kategoriCubit),
            ],
            child: const HalamanBeranda(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    // Pastikan elemen keadaan kosong TIDAK muncul
    expect(find.text('Belum Ada Pengeluaran yang Dicatat'), findsNothing);
    expect(find.byKey(const Key('tombol_catat_pertama')), findsNothing);

    // Pastikan elemen Beranda normal muncul
    expect(find.text('PENGELUARAN PEKAN INI'), findsOneWidget);
    expect(find.text('Catatan Terakhir'), findsOneWidget);
  });

  testWidgets(
      'Beranda kosong di dalam AppShell hanya menampilkan tepat satu HeaderAplikasi (tidak dobel)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const ringkasanKosong = RingkasanPekanEntity(
      totalMingguIni: 0,
      totalMingguLalu: 0,
      selisihMingguan: 0,
      transaksiTerakhir: [],
      kuotaPindai: 10,
    );

    const rincianKosong = RincianPengeluaranEntity(
      totalBulanIni: 0,
      kategoriPekanIni: [],
      kategoriBulanIni: [],
    );

    final berandaCubit = _FakeBerandaCubit(
      ringkasan: ringkasanKosong,
      rincian: rincianKosong,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => MultiBlocProvider(
                    providers: [
                      BlocProvider<BerandaCubit>.value(value: berandaCubit),
                      BlocProvider<KategoriCubit>.value(value: kategoriCubit),
                    ],
                    child: const HalamanBeranda(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    // Memastikan konten beranda kosong tampil
    expect(find.text('Belum Ada Pengeluaran yang Dicatat'), findsOneWidget);
    // Memastikan hanya ada tepat SATU HeaderAplikasi dengan subjudul BERANDA (tidak dobel)
    expect(find.byType(HeaderAplikasi), findsOneWidget);
    expect(find.text('BERANDA'), findsOneWidget);
  });
}
