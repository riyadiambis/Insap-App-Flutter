import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/beranda/presentation/pages/halaman_beranda.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/refleksi/domain/entities/refleksi_mingguan_entity.dart';
import 'package:insap/features/refleksi/domain/repositories/refleksi_repository.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';

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
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [
        TransaksiEntity(
          id: 1,
          jumlah: 25000,
          kategoriId: 1,
          tanggal: '2026-10-17',
          catatan: 'Makan siang',
          dibuatPada: '2026-10-17T12:00:00.000',
        ),
      ];

  @override
  Future<int> totalMingguIni(String a, String b) async => 25000;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

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
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async =>
      List.generate(daftarTransaksi.length, (i) => i + 1);

  @override
  Future<int> hapus(int id) async => 0;
}

class _FakeRefleksiRepository implements RefleksiRepository {
  RefleksiMingguanEntity? dataRefleksi;

  _FakeRefleksiRepository({this.dataRefleksi});

  @override
  Future<RefleksiMingguanEntity?> ambilPerMinggu(
          int tahun, int mingguKe) async =>
      dataRefleksi;

  @override
  Future<List<RefleksiMingguanEntity>> ambilSemuaRefleksi() async =>
      dataRefleksi != null ? [dataRefleksi!] : [];

  @override
  Future<int?> bacaTargetPekanDepan({int? tahun, int? mingguKe}) async => null;

  @override
  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi) async {
    dataRefleksi = refleksi;
    return 1;
  }

  @override
  Future<void> simpanTargetPekanDepan(int? target,
      {int? tahunTujuan, int? mingguTujuan}) async {}
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

  // 17 Oktober 2026 adalah hari Sabtu
  final sabtu = DateTime(2026, 10, 17, 10, 0);
  // 19 Oktober 2026 adalah hari Senin
  final senin = DateTime(2026, 10, 19, 10, 0);

  testWidgets('Banner refleksi muncul pada hari Sabtu bila belum ada refleksi',
      (tester) async {
    tester.view.physicalSize = const Size(460, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final transRepo = _FakeTransaksiRepository();
    final refleksiRepo = _FakeRefleksiRepository(dataRefleksi: null);

    final berandaCubit = BerandaCubit(
      ambilRingkasanPekan: AmbilRingkasanPekan(transRepo),
      refleksiRepository: refleksiRepo,
      sekarang: () => sabtu,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => KategoriCubit(
              ambilKategori: AmbilKategori(_FakeKategoriRepository()),
            )..muat(),
          ),
          BlocProvider.value(
            value: berandaCubit..muatRingkasan(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: HalamanBeranda(
            waktuSekarang: () => sabtu,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('banner_refleksi_beranda')), findsOneWidget);
    expect(
      find.text('Pekan ini belum direfleksikan. Luangkan 2 menit, yuk.'),
      findsOneWidget,
    );
  });

  testWidgets('Banner refleksi TIDAK muncul pada hari Senin', (tester) async {
    tester.view.physicalSize = const Size(460, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final transRepo = _FakeTransaksiRepository();
    final refleksiRepo = _FakeRefleksiRepository(dataRefleksi: null);

    final berandaCubit = BerandaCubit(
      ambilRingkasanPekan: AmbilRingkasanPekan(transRepo),
      refleksiRepository: refleksiRepo,
      sekarang: () => senin,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => KategoriCubit(
              ambilKategori: AmbilKategori(_FakeKategoriRepository()),
            )..muat(),
          ),
          BlocProvider.value(
            value: berandaCubit..muatRingkasan(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: HalamanBeranda(
            waktuSekarang: () => senin,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('banner_refleksi_beranda')), findsNothing);
  });

  testWidgets(
      'Banner refleksi TIDAK muncul pada hari Sabtu jika refleksi sudah tersimpan',
      (tester) async {
    tester.view.physicalSize = const Size(460, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final transRepo = _FakeTransaksiRepository();
    final refleksiRepo = _FakeRefleksiRepository(
      dataRefleksi: const RefleksiMingguanEntity(
        id: 1,
        tahun: 2026,
        mingguKe: 42,
        realisasi: 25000,
        dibuatPada: '2026-10-17T09:00:00.000',
      ),
    );

    final berandaCubit = BerandaCubit(
      ambilRingkasanPekan: AmbilRingkasanPekan(transRepo),
      refleksiRepository: refleksiRepo,
      sekarang: () => sabtu,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => KategoriCubit(
              ambilKategori: AmbilKategori(_FakeKategoriRepository()),
            )..muat(),
          ),
          BlocProvider.value(
            value: berandaCubit..muatRingkasan(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: HalamanBeranda(
            waktuSekarang: () => sabtu,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('banner_refleksi_beranda')), findsNothing);
  });
}
