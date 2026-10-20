import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insap/core/constants/kuota_constants.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/kartu_buku_tulis.dart';
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
  }) {
    final ringkasan = RingkasanPekanEntity(
      totalMingguIni: totalMingguIni,
      totalMingguLalu: 40000,
      selisihMingguan: 10000,
      transaksiTerakhir: [],
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

      // pastikan kartu Pindai Struk ditemukan
      final kartuPindaiFinder = find.ancestor(
        of: find.text('Pindai Struk'),
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
    '(b) bar kuota dan teks "10/10" tampil',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 10));
      await tester.pumpAndSettle();

      // teks 10/10 tampil
      expect(find.text('10/10'), findsOneWidget);

      // badge AI tetap ada di kartu Pindai Struk
      expect(find.text('AI'), findsOneWidget);

      // bar kuota memiliki faktor lebar 1.0 (penuh)
      final kartuPindaiFinder = find.ancestor(
        of: find.text('Pindai Struk'),
        matching: find.byType(KartuBukuTulis),
      );
      final fractionallySizedBoxFinder = find.descendant(
        of: kartuPindaiFinder,
        matching: find.byType(FractionallySizedBox),
      );
      expect(fractionallySizedBoxFinder, findsOneWidget);

      final fractionallySizedBox =
          tester.widget<FractionallySizedBox>(fractionallySizedBoxFinder);
      expect(fractionallySizedBox.widthFactor, equals(1.0));

      // tidak ada exception/overflow
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '(c) saat sisa 0, teks "Habis, reset Senin" tampil dan nilai bar 0',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 0));
      await tester.pumpAndSettle();

      // teks sisa habis tampil
      expect(find.text('Habis, reset Senin'), findsOneWidget);
      expect(find.text('0/10'), findsNothing);

      // bar kuota kosong (nilai progress 0.0)
      final kartuPindaiFinder = find.ancestor(
        of: find.text('Pindai Struk'),
        matching: find.byType(KartuBukuTulis),
      );
      final fractionallySizedBoxFinder = find.descendant(
        of: kartuPindaiFinder,
        matching: find.byType(FractionallySizedBox),
      );
      expect(fractionallySizedBoxFinder, findsOneWidget);

      final fractionallySizedBox =
          tester.widget<FractionallySizedBox>(fractionallySizedBoxFinder);
      expect(fractionallySizedBox.widthFactor, equals(0.0));

      // tidak ada exception/overflow
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

      expect(find.text('Catat Cepat'), findsOneWidget);
      expect(find.text('Pindai Struk'), findsOneWidget);
      expect(find.text('5/10'), findsOneWidget);

      // pastikan kartu kuota mandiri lama sudah tidak ada
      expect(find.text('Sisa Kuota Pindai Struk'), findsNothing);
      expect(find.text('struk sisa'), findsNothing);

      // bebas overflow
      expect(tester.takeException(), isNull);
    },
  );

  group('ISSUE-33 kartu aksi cepat beranda', () {
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

    testWidgets('kartu Pindai Struk memakai aiBiru solid, Catat Cepat tetap stabilo',
        (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      final pindai = tester.widget<KartuBukuTulis>(kartuDari('Pindai Struk'));
      expect(pindai.backgroundColor, AppColors.aiBiru);

      final catat = tester.widget<KartuBukuTulis>(kartuDari('Catat Cepat'));
      expect(catat.backgroundColor, AppColors.stabilo);
    });

    testWidgets('subjudul baru tampil dan teks lama OCR otomatis AI hilang',
        (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      expect(find.text('Foto struk, AI yang isi'), findsOneWidget);
      expect(find.text('OCR otomatis AI'), findsNothing);
    });

    testWidgets('Catat Cepat memakai ikon pensil penuh', (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: kartuDari('Catat Cepat'),
          matching: find.byIcon(Icons.edit),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.edit_note_rounded), findsNothing);
    });

    testWidgets('bilah kuota masih menampilkan angka dari konstanta jatah',
        (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      expect(find.text('5/$kuotaPindaiPekanan'), findsOneWidget);
      final teks = tester.widget<Text>(find.text('5/$kuotaPindaiPekanan'));
      expect(teks.style?.color, AppColors.kartu);
    });

    testWidgets('judul Pindai Struk putih dan jalur bilah kuota aiBiruTua',
        (tester) async {
      ukuranStandar(tester);
      await tester.pumpWidget(bangunLayarBeranda(kuotaPindai: 5));
      await tester.pumpAndSettle();

      final judul = tester.widget<Text>(find.text('Pindai Struk'));
      expect(judul.style?.color, AppColors.kartu);

      final jalur = tester.widget<Container>(
        find
            .descendant(
              of: kartuDari('Pindai Struk'),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration as BoxDecoration).color ==
                        AppColors.aiBiruTua,
              ),
            )
            .first,
      );
      final dekor = jalur.decoration as BoxDecoration;
      expect((dekor.border as Border).top.color, AppColors.kartu);
    });
  });
}
