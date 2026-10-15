import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/beranda/presentation/widgets/kartu_rincian_pengeluaran.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/pengaturan/domain/entities/perbandingan_target_entity.dart';
import 'package:insap/features/transaksi/domain/entities/rincian_pengeluaran_entity.dart';

class _FakeKategoriRepository implements KategoriRepository {
  @override
  Future<List<KategoriEntity>> ambilSemua() async => const [];
}

void main() {
  late KategoriCubit kategoriCubit;

  setUp(() {
    kategoriCubit = KategoriCubit(
      ambilKategori: AmbilKategori(_FakeKategoriRepository()),
    )..muat();
  });

  tearDown(() {
    kategoriCubit.close();
  });

  Widget buatWidgetUji({
    required int totalPekanIni,
    required RincianPengeluaranEntity rincian,
    PerbandinganTargetEntity? perbandinganTarget,
    Future<void> Function(int)? onUbahTarget,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: BlocProvider<KategoriCubit>.value(
          value: kategoriCubit,
          child: SingleChildScrollView(
            child: KartuRincianPengeluaran(
              totalPekanIni: totalPekanIni,
              rincian: rincian,
              perbandinganTarget: perbandinganTarget,
              onUbahTarget: onUbahTarget,
            ),
          ),
        ),
      ),
    );
  }

  group('KartuRincianPengeluaran Target Bulanan (ISSUE-25)', () {
    const rincianContoh = RincianPengeluaranEntity(
      totalBulanIni: 1500000,
      kategoriPekanIni: [],
      kategoriBulanIni: [],
    );

    testWidgets(
      '(d) tab Pekan ini tidak menampilkan baris target bulanan maupun tombol atur target',
      (tester) async {
        final perbandinganAdaTarget = PerbandinganTargetEntity.hitung(
          totalBulanIni: 1500000,
          targetBulanan: 2000000,
        );

        await tester.pumpWidget(
          buatWidgetUji(
            totalPekanIni: 350000,
            rincian: rincianContoh,
            perbandinganTarget: perbandinganAdaTarget,
          ),
        );
        await tester.pumpAndSettle();

        // Default tab adalah 'Pekan ini'
        expect(find.text('Total pekan ini'), findsOneWidget);
        // Baris target bulanan tidak boleh tampil
        expect(find.textContaining('dari target'), findsNothing);
        expect(find.text('Atur target bulanan'), findsNothing);
        expect(find.byKey(const Key('baris_target_bulanan')), findsNothing);
        expect(find.byKey(const Key('tombol_atur_target_bulanan')), findsNothing);
      },
    );

    testWidgets(
      '(b.1) tab Bulan ini menampilkan "dari target", bilah progres, dan sisa ketika target ada',
      (tester) async {
        final perbandinganAdaTarget = PerbandinganTargetEntity.hitung(
          totalBulanIni: 1500000,
          targetBulanan: 2000000,
        );

        await tester.pumpWidget(
          buatWidgetUji(
            totalPekanIni: 350000,
            rincian: rincianContoh,
            perbandinganTarget: perbandinganAdaTarget,
          ),
        );
        await tester.pumpAndSettle();

        // Pindah ke tab Bulan ini
        await tester.tap(find.byKey(const Key('pilih_periode_bulan')));
        await tester.pumpAndSettle();

        // Verifikasi informasi target
        expect(find.textContaining('dari target'), findsOneWidget);
        expect(find.text('Rp1.500.000 dari target Rp2.000.000'), findsOneWidget);
        expect(find.byKey(const Key('bilah_progres_target')), findsOneWidget);
        expect(find.text('Sisa Rp500.000'), findsOneWidget);
        expect(find.text('Atur target bulanan'), findsNothing);
      },
    );

    testWidgets(
      '(b.2) tab Bulan ini menampilkan status "Lewat Rp... dari target" ketika pengeluaran melebihi target',
      (tester) async {
        final perbandinganLewatTarget = PerbandinganTargetEntity.hitung(
          totalBulanIni: 2300000,
          targetBulanan: 2000000,
        );

        await tester.pumpWidget(
          buatWidgetUji(
            totalPekanIni: 350000,
            rincian: const RincianPengeluaranEntity(
              totalBulanIni: 2300000,
              kategoriPekanIni: [],
              kategoriBulanIni: [],
            ),
            perbandinganTarget: perbandinganLewatTarget,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('pilih_periode_bulan')));
        await tester.pumpAndSettle();

        expect(find.text('Rp2.300.000 dari target Rp2.000.000'), findsOneWidget);
        expect(find.text('Lewat Rp300.000 dari target'), findsOneWidget);
      },
    );

    testWidgets(
      '(b.3) tab Bulan ini menampilkan tombol "Atur target bulanan" ketika target belum ada',
      (tester) async {
        final perbandinganTanpaTarget = PerbandinganTargetEntity.hitung(
          totalBulanIni: 1500000,
          targetBulanan: null,
        );

        await tester.pumpWidget(
          buatWidgetUji(
            totalPekanIni: 350000,
            rincian: rincianContoh,
            perbandinganTarget: perbandinganTanpaTarget,
          ),
        );
        await tester.pumpAndSettle();

        // Pindah ke tab Bulan ini
        await tester.tap(find.byKey(const Key('pilih_periode_bulan')));
        await tester.pumpAndSettle();

        expect(find.text('Total bulan ini'), findsOneWidget);
        expect(find.text('Atur target bulanan'), findsOneWidget);
        expect(find.byKey(const Key('tombol_atur_target_bulanan')), findsOneWidget);
        expect(find.textContaining('dari target'), findsNothing);
      },
    );

    testWidgets(
      '(c) mengetuk "Atur target bulanan" membuka lembar bawah dan simpan memperbarui target',
      (tester) async {
        int? targetTersimpan;

        final perbandinganTanpaTarget = PerbandinganTargetEntity.hitung(
          totalBulanIni: 1500000,
          targetBulanan: null,
        );

        await tester.pumpWidget(
          buatWidgetUji(
            totalPekanIni: 350000,
            rincian: rincianContoh,
            perbandinganTarget: perbandinganTanpaTarget,
            onUbahTarget: (nilai) async {
              targetTersimpan = nilai;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Pindah ke tab Bulan ini
        await tester.tap(find.byKey(const Key('pilih_periode_bulan')));
        await tester.pumpAndSettle();

        // Ketuk tombol Atur target bulanan
        await tester.tap(find.byKey(const Key('tombol_atur_target_bulanan')));
        await tester.pumpAndSettle();

        // Verifikasi bottom sheet terbuka
        expect(find.text('Target Bulanan'), findsOneWidget);
        expect(find.byKey(const Key('kolom_input_target_bulanan')), findsOneWidget);
        expect(find.byKey(const Key('tombol_simpan_target_bulanan')), findsOneWidget);

        // Masukkan nominal 2500000
        await tester.enterText(find.byKey(const Key('kolom_input_target_bulanan')), '2500000');
        await tester.pumpAndSettle();

        // Ketuk tombol Simpan
        await tester.tap(find.byKey(const Key('tombol_simpan_target_bulanan')));
        await tester.pumpAndSettle();

        // Callback onUbahTarget terpanggil dengan angka bulat murni
        expect(targetTersimpan, equals(2500000));
        // Lembar bawah tertutup
        expect(find.text('Batas pengeluaran sebulan. Kamu bisa ubah kapan saja.'), findsNothing);
      },
    );

    testWidgets(
      '(c.2) mengetuk baris target yang sudah ada juga membuka lembar bawah ubah target',
      (tester) async {
        int? targetTersimpan;

        final perbandinganAdaTarget = PerbandinganTargetEntity.hitung(
          totalBulanIni: 1500000,
          targetBulanan: 2000000,
        );

        await tester.pumpWidget(
          buatWidgetUji(
            totalPekanIni: 350000,
            rincian: rincianContoh,
            perbandinganTarget: perbandinganAdaTarget,
            onUbahTarget: (nilai) async {
              targetTersimpan = nilai;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('pilih_periode_bulan')));
        await tester.pumpAndSettle();

        // Ketuk baris target bulanan
        await tester.tap(find.byKey(const Key('baris_target_bulanan')));
        await tester.pumpAndSettle();

        expect(find.text('Target Bulanan'), findsOneWidget);

        // Ubah nominal menjadi 3000000
        await tester.enterText(find.byKey(const Key('kolom_input_target_bulanan')), '3000000');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('tombol_simpan_target_bulanan')));
        await tester.pumpAndSettle();

        expect(targetTersimpan, equals(3000000));
      },
    );
  });
}
