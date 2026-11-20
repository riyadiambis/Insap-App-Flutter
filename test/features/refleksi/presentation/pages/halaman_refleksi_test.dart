import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/tombol_stabilo.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/refleksi/domain/entities/refleksi_mingguan_entity.dart';
import 'package:insap/features/refleksi/domain/repositories/refleksi_repository.dart';
import 'package:insap/features/refleksi/domain/usecases/ambil_refleksi_pekan.dart';
import 'package:insap/features/refleksi/domain/usecases/simpan_refleksi.dart';
import 'package:insap/features/refleksi/presentation/cubit/refleksi_cubit.dart';
import 'package:insap/features/refleksi/presentation/pages/halaman_refleksi.dart';
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
    KategoriEntity(
      id: 2,
      nama: 'transport',
      ikon: 'two_wheeler',
      warna: '#4A9BE8',
      kelompokKakeibo: 'esensial',
      bawaan: 1,
      urutan: 2,
    ),
    KategoriEntity(
      id: 6,
      nama: 'nongkrong',
      ikon: 'local_cafe',
      warna: '#FFB020',
      kelompokKakeibo: 'hiburan',
      bawaan: 1,
      urutan: 6,
    ),
    KategoriEntity(
      id: 7,
      nama: 'top up',
      ikon: 'sports_esports',
      warna: '#D9482F',
      kelompokKakeibo: 'hiburan',
      bawaan: 1,
      urutan: 7,
    ),
  ];
}

class _FakeTransaksiRepository implements TransaksiRepository {
  List<TransaksiEntity> daftarPekanIni = const [];
  List<TransaksiEntity> daftarPekanLalu = const [];
  List<TransaksiEntity> daftarBulanIni = const [];
  List<TransaksiEntity> daftarBulanLalu = const [];

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    if (tanggalMulai == '2026-11-16') return daftarPekanIni;
    if (tanggalMulai == '2026-11-09') return daftarPekanLalu;
    if (tanggalMulai == '2026-11-01') return daftarBulanIni;
    if (tanggalMulai == '2026-10-01') return daftarBulanLalu;
    return const [];
  }

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async =>
      List.generate(daftarTransaksi.length, (i) => i + 1);
}

class _FakeRefleksiRepository implements RefleksiRepository {
  @override
  Future<RefleksiMingguanEntity?> ambilPerMinggu(
    int tahun,
    int mingguKe,
  ) async => null;

  @override
  Future<List<RefleksiMingguanEntity>> ambilSemuaRefleksi() async => [];

  @override
  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi) async => 1;

  @override
  Future<int?> bacaTargetPekanDepan({int? tahun, int? mingguKe}) async => null;

  @override
  Future<void> simpanTargetPekanDepan(
    int? target, {
    int? tahunTujuan,
    int? mingguTujuan,
  }) async {}
}

void main() {
  late _FakeTransaksiRepository fakeTransaksiRepo;
  late _FakeRefleksiRepository fakeRefleksiRepo;
  late RefleksiCubit cubit;
  final tanggalAcuan = DateTime(2026, 11, 20); // Pekan 16 - 22 Nov 2026

  setUp(() {
    fakeTransaksiRepo = _FakeTransaksiRepository();
    fakeRefleksiRepo = _FakeRefleksiRepository();
    final ambilUseCase = AmbilRefleksiPekan(
      refleksiRepository: fakeRefleksiRepo,
      transaksiRepository: fakeTransaksiRepo,
      kategoriRepository: _FakeKategoriRepository(),
      sekarang: () => tanggalAcuan,
    );
    final simpanUseCase = SimpanRefleksi(
      fakeRefleksiRepo,
      sekarang: () => tanggalAcuan,
    );
    cubit = RefleksiCubit(
      ambilRefleksiPekan: ambilUseCase,
      simpanRefleksi: simpanUseCase,
    );
  });

  tearDown(() => cubit.close());

  Widget buatWidgetUji({
    BerandaCubit? berandaCubit,
    VoidCallback? onMintaRefleksiAi,
  }) {
    final child = BlocProvider<RefleksiCubit>.value(
      value: cubit,
      child: HalamanRefleksi(onMintaRefleksiAi: onMintaRefleksiAi),
    );
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: berandaCubit != null
          ? BlocProvider<BerandaCubit>.value(value: berandaCubit, child: child)
          : child,
    );
  }

  testWidgets(
    'menampilkan chip Pekan ini & Bulan ini, kartu periode, bilah kategori urut terbesar, dan tombol AI aktif',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeTransaksiRepo.daftarPekanIni = const [
        TransaksiEntity(
          id: 1,
          jumlah: 66000,
          kategoriId: 2, // Transport
          tanggal: '2026-11-17',
          dibuatPada: '2026-11-17T10:00:00',
        ),
        TransaksiEntity(
          id: 2,
          jumlah: 189000,
          kategoriId: 1, // Makan
          tanggal: '2026-11-18',
          dibuatPada: '2026-11-18T12:00:00',
        ),
        TransaksiEntity(
          id: 3,
          jumlah: 124300,
          kategoriId: 6, // Nongkrong
          tanggal: '2026-11-19',
          dibuatPada: '2026-11-19T20:00:00',
        ),
        TransaksiEntity(
          id: 4,
          jumlah: 33200,
          kategoriId: 7, // Top up
          tanggal: '2026-11-20',
          dibuatPada: '2026-11-20T09:00:00',
        ),
      ];
      fakeTransaksiRepo.daftarPekanLalu = const [
        TransaksiEntity(
          id: 5,
          jumlah: 468750,
          kategoriId: 1,
          tanggal: '2026-11-10',
          dibuatPada: '2026-11-10T10:00:00',
        ),
      ];

      bool tombolAiDitekan = false;
      await cubit.muatRefleksi(tanggalAcuan);
      await tester.pumpWidget(
        buatWidgetUji(onMintaRefleksiAi: () => tombolAiDitekan = true),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chip_refleksi_pekan_ini')), findsOneWidget);
      expect(find.byKey(const Key('chip_refleksi_bulan_ini')), findsOneWidget);
      expect(find.text('16 - 22 NOV'), findsOneWidget);
      expect(find.text('Rp412.500'), findsOneWidget);
      expect(find.text('-12% dari pekan lalu'), findsOneWidget);

      final teksPersen = tester.widget<Text>(
        find.byKey(const Key('persen_banding_refleksi')),
      );
      expect(teksPersen.style?.color, AppColors.daunTua);

      expect(find.text('Ke mana uangmu pergi'), findsOneWidget);
      expect(find.text('Makan'), findsOneWidget);
      expect(find.text('Nongkrong'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Top up'), findsOneWidget);

      // Verifikasi urutan terbesar ke terkecil (Makan di atas Nongkrong di atas Transport)
      final yMakan = tester.getTopLeft(find.text('Makan')).dy;
      final yNongkrong = tester.getTopLeft(find.text('Nongkrong')).dy;
      final yTransport = tester.getTopLeft(find.text('Transport')).dy;
      final yTopUp = tester.getTopLeft(find.text('Top up')).dy;
      expect(yMakan, lessThan(yNongkrong));
      expect(yNongkrong, lessThan(yTransport));
      expect(yTransport, lessThan(yTopUp));

      // Form Kakeibo lama sudah dihapus
      expect(find.text('4 Kelompok Kakeibo'), findsNothing);
      expect(find.text('Rencana Pekan Depan'), findsNothing);

      // Tombol AI aktif + keterangan
      final tombolAi = find.byKey(const Key('tombol_minta_refleksi_ai'));
      expect(tombolAi, findsOneWidget);
      expect(
        tester.widget<TombolStabilo>(tombolAi).onPressed,
        isNotNull,
      );
      expect(
        find.text('Struki merangkum pola belanjamu dan memberi 3 saran.'),
        findsOneWidget,
      );

      // Target sentuh >= 48 dp
      expect(
        tester.getSize(find.byKey(const Key('chip_refleksi_pekan_ini'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const Key('chip_refleksi_bulan_ini'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.getSize(tombolAi).height, greaterThanOrEqualTo(48));

      await tester.tap(tombolAi);
      await tester.pumpAndSettle();
      expect(tombolAiDitekan, isTrue);
    },
  );

  testWidgets(
    'beralih ke chip Bulan ini menampilkan data bulanan, warna merah saat naik, dan menyembunyikan tombol AI',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeTransaksiRepo.daftarBulanIni = const [
        TransaksiEntity(
          id: 1,
          jumlah: 300000,
          kategoriId: 1,
          tanggal: '2026-11-05',
          dibuatPada: '2026-11-05T10:00:00',
        ),
      ];
      fakeTransaksiRepo.daftarBulanLalu = const [
        TransaksiEntity(
          id: 2,
          jumlah: 200000,
          kategoriId: 1,
          tanggal: '2026-10-12',
          dibuatPada: '2026-10-12T10:00:00',
        ),
      ];

      await cubit.muatRefleksi(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chip_refleksi_bulan_ini')));
      await tester.pumpAndSettle();

      expect(find.text('NOVEMBER 2026'), findsOneWidget);
      expect(find.text('Rp300.000'), findsAtLeastNWidgets(1));
      expect(find.text('+50% dari bulan lalu'), findsOneWidget);
      final teksPersen = tester.widget<Text>(
        find.byKey(const Key('persen_banding_refleksi')),
      );
      expect(teksPersen.style?.color, AppColors.merahTeks);

      expect(
        find.byKey(const Key('tombol_minta_refleksi_ai')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'pekan tanpa transaksi menonaktifkan tombol Minta refleksi AI dan menampilkan teks ajakan catat',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await cubit.muatRefleksi(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji());
      await tester.pumpAndSettle();

      expect(find.text('Rp0'), findsOneWidget);
      expect(find.text('Belum ada pengeluaran pekan ini.'), findsOneWidget);

      final tombolAi = tester.widget<TombolStabilo>(
        find.byKey(const Key('tombol_minta_refleksi_ai')),
      );
      expect(tombolAi.onPressed, isNull);
      expect(find.text('Catat dulu belanjamu pekan ini.'), findsOneWidget);
    },
  );

  testWidgets(
    'otomatis memuat ulang saat BerandaCubit memancarkan BerandaLoaded',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final berandaCubit = BerandaCubit(
        ambilRingkasanPekan: AmbilRingkasanPekan(
          fakeTransaksiRepo,
          sekarang: () => tanggalAcuan,
        ),
      );
      addTearDown(berandaCubit.close);

      fakeTransaksiRepo.daftarPekanIni = const [
        TransaksiEntity(
          id: 1,
          jumlah: 50000,
          kategoriId: 1,
          tanggal: '2026-11-17',
          dibuatPada: '2026-11-17T10:00:00',
        ),
      ];

      await cubit.muatRefleksi(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji(berandaCubit: berandaCubit));
      await tester.pumpAndSettle();

      expect(find.text('Rp50.000'), findsAtLeastNWidgets(1));

      fakeTransaksiRepo.daftarPekanIni = const [
        TransaksiEntity(
          id: 1,
          jumlah: 50000,
          kategoriId: 1,
          tanggal: '2026-11-17',
          dibuatPada: '2026-11-17T10:00:00',
        ),
        TransaksiEntity(
          id: 2,
          jumlah: 35000,
          kategoriId: 6,
          tanggal: '2026-11-19',
          dibuatPada: '2026-11-19T12:00:00',
        ),
      ];

      await berandaCubit.muatRingkasan();
      await tester.pumpAndSettle();

      expect(find.text('Rp85.000'), findsOneWidget);
    },
  );
}
