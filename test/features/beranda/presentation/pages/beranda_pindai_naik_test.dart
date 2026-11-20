import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insap/core/constants/kuota_constants.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/kartu_buku_tulis.dart';
import 'package:insap/core/widgets/maskot_struki.dart';
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

// fake repository kategori untuk pengujian kartu rincian di beranda
class _FakeKategoriRepository implements KategoriRepository {
  final List<KategoriEntity> data;
  _FakeKategoriRepository(this.data);

  @override
  Future<List<KategoriEntity>> ambilSemua() async => data;
}

// fake cubit beranda untuk menyuplai state ringkasan dengan kuota tertentu
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

  const dummyRincian = RincianPengeluaranEntity(
    totalBulanIni: 150000,
    kategoriPekanIni: [
      TotalKategoriEntity(kategoriId: 1, total: 50000),
    ],
    kategoriBulanIni: [
      TotalKategoriEntity(kategoriId: 1, total: 150000),
    ],
  );

  setUp(() {
    kategoriRepo = _FakeKategoriRepository(dummyKategori);
    kategoriCubit = KategoriCubit(ambilKategori: AmbilKategori(kategoriRepo))..muat();
  });

  tearDown(() {
    kategoriCubit.close();
  });

  Widget bangunLayarBeranda({
    required int kuotaPindai,
    int totalMingguIni = 50000,
    List<TransaksiEntity> transaksiTerakhir = const [],
  }) {
    final ringkasan = RingkasanPekanEntity(
      totalMingguIni: totalMingguIni,
      totalMingguLalu: 40000,
      selisihMingguan: 10000,
      transaksiTerakhir: transaksiTerakhir,
      kuotaPindai: kuotaPindai,
    );

    final berandaCubit = _FakeBerandaCubit(
      ringkasan: ringkasan,
      rincian: dummyRincian,
    );

    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<BerandaCubit>.value(value: berandaCubit),
          BlocProvider<KategoriCubit>.value(value: kategoriCubit),
        ],
        child: const HalamanBeranda(),
      ),
    );
  }

  testWidgets(
    '(a) ukuran layar 411x914, kartu Pindai Struk terlihat tanpa gulir',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 10));
      await tester.pumpAndSettle();

      // pastikan kartu Pindai struk ditemukan
      final kartuPindaiFinder = find.ancestor(
        of: find.text('Pindai struk'),
        matching: find.byType(KartuBukuTulis),
      );
      expect(kartuPindaiFinder, findsOneWidget);

      // sisi bawah kartu harus berada di dalam layar (<= 914) tanpa digulir
      final rect = tester.getRect(kartuPindaiFinder);
      expect(rect.top, greaterThanOrEqualTo(0.0));
      expect(rect.bottom, lessThanOrEqualTo(914.0));

      // tidak ada exception/overflow
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '(b) teks kuota "Sisa 10 dari $kuotaPindaiPekanan pekan ini" dan badge AI tampil',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 10));
      await tester.pumpAndSettle();

      expect(
        find.text('Sisa 10 dari $kuotaPindaiPekanan pekan ini'),
        findsOneWidget,
      );
      expect(find.text('AI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '(c) saat sisa 0, teks "Habis, reset Senin" tampil',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 0));
      await tester.pumpAndSettle();

      expect(find.text('Habis, reset Senin'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '(d) tidak ada overflow (tester.takeException isNull)',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      expect(find.text('Catat cepat'), findsOneWidget);
      expect(find.text('Pindai struk'), findsOneWidget);
      expect(
        find.text('Sisa 5 dari $kuotaPindaiPekanan pekan ini'),
        findsOneWidget,
      );

      expect(find.text('Sisa Kuota Pindai Struk'), findsNothing);
      expect(find.text('struk sisa'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  group('ISSUE-33 & 41 kartu aksi cepat beranda', () {
    void ukuranStandar(WidgetTester tester) {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    Finder kartuDari(String teks) => find.ancestor(
          of: find.text(teks),
          matching: find.byType(KartuBukuTulis),
        );

    testWidgets('kartu Pindai struk memakai ink dengan bayangan stabilo, Catat cepat tetap stabilo',
        (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      final pindai = tester.widget<KartuBukuTulis>(kartuDari('Pindai struk'));
      expect(pindai.backgroundColor, AppColors.ink);
      expect(pindai.shadow?.color, AppColors.stabilo);

      final catat = tester.widget<KartuBukuTulis>(kartuDari('Catat cepat'));
      expect(catat.backgroundColor, AppColors.stabilo);
    });

    testWidgets('maskot detektif beranda berukuran 76x76 dan terlihat di layar',
        (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      final maskotFinder = find.byKey(const Key('maskot_detektif_beranda'));
      expect(maskotFinder, findsOneWidget);
      expect(tester.getSize(maskotFinder), const Size(76, 76));
      expect(tester.widget<MaskotStruki>(maskotFinder).pose, PoseMaskot.detektif);
    });

    testWidgets('Catat cepat memakai ikon pensil garis', (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: kartuDari('Catat cepat'),
          matching: find.byIcon(Icons.edit_outlined),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.edit_note_rounded), findsNothing);
    });

    testWidgets(
        'subjudul kartu aksi cepat tampil dan teks lama OCR otomatis AI hilang',
        (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      expect(find.text('Ketik manual'), findsOneWidget);
      expect(
        find.text('Sisa 5 dari $kuotaPindaiPekanan pekan ini'),
        findsOneWidget,
      );
      expect(find.text('OCR otomatis AI'), findsNothing);
    });

    testWidgets(
        'teks kuota masih menampilkan angka dari konstanta kuotaPindaiPekanan',
        (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      final kuotaFinder = find.descendant(
        of: kartuDari('Pindai struk'),
        matching: find.text('Sisa 5 dari $kuotaPindaiPekanan pekan ini'),
      );
      expect(kuotaFinder, findsOneWidget);
      final teks = tester.widget<Text>(kuotaFinder);
      expect(teks.style?.color, AppColors.biruPudar);
    });

    testWidgets('maskot tampil di Beranda (pose detektif) pada keadaan normal',
        (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(
        bangunLayarBeranda(
          kuotaPindai: 5,
          transaksiTerakhir: const [
            TransaksiEntity(
              id: 1,
              jumlah: 25000,
              kategoriId: 1,
              tanggal: '2026-10-15',
              catatan: 'Nasi goreng',
              dibuatPada: '2026-10-15T12:00:00.000',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada catatan'), findsNothing);
      expect(find.text('Terakhir dicatat'), findsOneWidget);
      expect(find.text('Nasi goreng'), findsOneWidget);

      final maskotFinder = find.byKey(const Key('maskot_detektif_beranda'));
      expect(maskotFinder, findsOneWidget);
      expect(tester.getSize(maskotFinder), const Size(76, 76));
      expect(tester.widget<MaskotStruki>(maskotFinder).pose, PoseMaskot.detektif);
    });

    testWidgets('judul Pindai struk putih dan teks kuota biru pudar',
        (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      final judul = tester.widget<Text>(find.text('Pindai struk'));
      expect(judul.style?.color, AppColors.kartu);

      final kuotaTeks = tester.widget<Text>(
        find.text('Sisa 5 dari $kuotaPindaiPekanan pekan ini'),
      );
      expect(kuotaTeks.style?.color, AppColors.biruPudar);
    });
  });
}
