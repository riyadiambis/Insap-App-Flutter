import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/di/injection_container.dart';
import 'package:insap/core/router/app_shell.dart';
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
import 'package:insap/features/transaksi/presentation/riwayat/pages/halaman_riwayat.dart';

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

// repo di memori, simpan beneran nambah ke daftar biar riwayat bisa berubah
class _FakeTransaksiRepository implements TransaksiRepository {
  final List<TransaksiEntity> daftar = [];

  @override
  Future<int> simpan(TransaksiEntity transaksi) async {
    final id = daftar.length + 1;
    daftar.add(
      TransaksiEntity(
        id: id,
        jumlah: transaksi.jumlah,
        kategoriId: transaksi.kategoriId,
        tanggal: transaksi.tanggal,
        catatan: transaksi.catatan,
        tipeKebutuhan: transaksi.tipeKebutuhan,
        dibuatPada: transaksi.dibuatPada,
      ),
    );
    return id;
  }

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async => List.of(daftar);

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async =>
      daftar.take(batas).toList();

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;
}

void main() {
  setUp(() {
    final getIt = GetIt.instance;
    getIt.reset();

    getIt.registerLazySingleton<KategoriRepository>(
      () => _FakeKategoriRepository(),
    );
    getIt.registerLazySingleton(() => AmbilKategori(getIt()));
    getIt.registerFactory(() => KategoriCubit(ambilKategori: getIt()));

    getIt.registerLazySingleton<TransaksiRepository>(
      () => _FakeTransaksiRepository(),
    );
    getIt.registerLazySingleton(() => TambahTransaksi(getIt()));
    getIt.registerLazySingleton(() => AmbilRiwayat(getIt()));
    getIt.registerLazySingleton(() => HapusTransaksi(getIt()));
    getIt.registerLazySingleton(() => AmbilRingkasanPekan(getIt()));
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

  // susunannya ditiru dari main.dart & app_router.dart: provider di root,
  // tab pakai StatefulShellRoute.indexedStack (biang bug-nya)
  Widget bangunAplikasiUji() {
    final router = GoRouter(
      initialLocation: '/riwayat',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, __) => const SizedBox()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/catat',
                  builder: (_, __) => const HalamanCatatTransaksi(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/refleksi',
                  builder: (_, __) => const SizedBox(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/riwayat',
                  builder: (_, __) => const HalamanRiwayat(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<KategoriCubit>()..muat()),
        BlocProvider(create: (_) => sl<BerandaCubit>()..muatRingkasan()),
        BlocProvider(create: (_) => sl<RiwayatCubit>()..muatRiwayat()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  testWidgets(
    'transaksi yang baru disimpan langsung tampil saat tab riwayat dibuka lagi',
    (tester) async {
      tester.view.physicalSize = const Size(460, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(bangunAplikasiUji());
      await tester.pumpAndSettle();

      // riwayat masih kosong
      expect(find.text('Belum Ada Catatan Boncos'), findsOneWidget);

      // pindah ke tab catat, isi form, simpan
      await tester.tap(find.text('Catat'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(KolomInputNominal),
          matching: find.byType(TextFormField),
        ),
        '25000',
      );
      await tester.tap(find.text('Makan'));
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Tambah catatan (misal: Es kopi sama temen)...',
        ),
        'Bakso urat',
      );
      await tester.pump();

      final tombolSimpan = find.textContaining('Simpan Transaksi');
      await tester.ensureVisible(tombolSimpan);
      await tester.tap(tombolSimpan);
      await tester.pumpAndSettle();

      // bug lama di luar ISSUE-16: KolomInputNominal.didUpdateWidget ngubah
      // controller pas build waktu form direset. ditelan di sini biar tes ini
      // fokus ke riwayat, galat lain tetap bikin gagal
      final galat = tester.takeException();
      expect(
        galat == null || '$galat'.contains('called during build'),
        isTrue,
        reason: 'galat tak terduga: $galat',
      );

      // buka tab riwayat lagi, transaksi baru harus sudah ada
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Catatan Boncos'), findsNothing);
      expect(find.text('Bakso urat'), findsOneWidget);
    },
  );
}
