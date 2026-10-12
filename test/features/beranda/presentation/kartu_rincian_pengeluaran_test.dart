import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/beranda/presentation/widgets/kartu_rincian_pengeluaran.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/transaksi/domain/entities/rincian_pengeluaran_entity.dart';
import 'package:insap/features/transaksi/domain/entities/total_kategori_entity.dart';

// repository kategori tiruan untuk pengujian widget kartu rincian
class _FakeKategoriRepository implements KategoriRepository {
  final List<KategoriEntity> data;

  _FakeKategoriRepository(this.data);

  @override
  Future<List<KategoriEntity>> ambilSemua() async => data;
}

void main() {
  late _FakeKategoriRepository repo;
  late KategoriCubit cubit;

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
    const KategoriEntity(
      id: 2,
      nama: 'jajan',
      ikon: 'local_cafe',
      warna: '#4A9BE8',
      kelompokKakeibo: 'opsional',
      bawaan: 1,
      urutan: 2,
    ),
  ];

  setUp(() {
    repo = _FakeKategoriRepository(dummyKategori);
    cubit = KategoriCubit(ambilKategori: AmbilKategori(repo))..muat();
  });

  tearDown(() {
    cubit.close();
  });

  Widget bangunWidget({
    required int totalPekanIni,
    required RincianPengeluaranEntity rincian,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<KategoriCubit>.value(
          value: cubit,
          child: SingleChildScrollView(
            child: KartuRincianPengeluaran(
              totalPekanIni: totalPekanIni,
              rincian: rincian,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('bawaan menampilkan rincian pekan', (tester) async {
    const rincian = RincianPengeluaranEntity(
      totalBulanIni: 300000,
      kategoriPekanIni: [
        TotalKategoriEntity(kategoriId: 1, total: 75000),
        TotalKategoriEntity(kategoriId: 2, total: 25000),
      ],
      kategoriBulanIni: [
        TotalKategoriEntity(kategoriId: 1, total: 200000),
        TotalKategoriEntity(kategoriId: 2, total: 100000),
      ],
    );

    await tester.pumpWidget(
      bangunWidget(totalPekanIni: 100000, rincian: rincian),
    );
    await tester.pumpAndSettle();

    // label seksi dan total pekan
    expect(find.text('RINCIAN PENGELUARAN'), findsOneWidget);
    expect(find.text('Rp100.000'), findsOneWidget);
    expect(find.text('Rp300.000'), findsNothing);

    // daftar kategori pekan
    expect(find.text('Makan'), findsOneWidget);
    expect(find.text('Jajan'), findsOneWidget);
    expect(find.text('Rp75.000'), findsOneWidget);
    expect(find.text('Rp25.000'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets(
    'mengetuk pilih_periode_bulan menampilkan total dan rincian bulan',
    (tester) async {
      const rincian = RincianPengeluaranEntity(
        totalBulanIni: 250000,
        kategoriPekanIni: [
          TotalKategoriEntity(kategoriId: 1, total: 75000),
          TotalKategoriEntity(kategoriId: 2, total: 25000),
        ],
        kategoriBulanIni: [
          TotalKategoriEntity(kategoriId: 1, total: 200000),
          TotalKategoriEntity(kategoriId: 2, total: 50000),
        ],
      );

      await tester.pumpWidget(
        bangunWidget(totalPekanIni: 100000, rincian: rincian),
      );
      await tester.pumpAndSettle();

      // ketuk pil bulan ini
      await tester.tap(find.byKey(const Key('pilih_periode_bulan')));
      await tester.pumpAndSettle();

      // total bulan dan rincian bulan aktif
      expect(find.text('Rp250.000'), findsOneWidget);
      expect(find.text('Rp100.000'), findsNothing);
      expect(find.text('Rp200.000'), findsOneWidget);
      expect(find.text('Rp50.000'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);

      // bisa kembali ke pekan
      await tester.tap(find.byKey(const Key('pilih_periode_pekan')));
      await tester.pumpAndSettle();

      expect(find.text('Rp100.000'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Rp250.000'), findsNothing);
    },
  );

  testWidgets('data kosong menampilkan rincian_kosong dan teks Rp0', (
    tester,
  ) async {
    const rincianKosong = RincianPengeluaranEntity(
      totalBulanIni: 0,
      kategoriPekanIni: [],
      kategoriBulanIni: [],
    );

    await tester.pumpWidget(
      bangunWidget(totalPekanIni: 0, rincian: rincianKosong),
    );
    await tester.pumpAndSettle();

    // pekan kosong
    expect(find.text('Rp0'), findsOneWidget);
    expect(find.byKey(const Key('rincian_kosong')), findsOneWidget);
    expect(find.text('Belum ada pengeluaran pekan ini.'), findsOneWidget);
    expect(
      find.text('Catat pengeluaran pertamamu, rinciannya muncul di sini.'),
      findsOneWidget,
    );

    // beralih ke bulan kosong
    await tester.tap(find.byKey(const Key('pilih_periode_bulan')));
    await tester.pumpAndSettle();

    expect(find.text('Rp0'), findsOneWidget);
    expect(find.byKey(const Key('rincian_kosong')), findsOneWidget);
    expect(find.text('Belum ada pengeluaran bulan ini.'), findsOneWidget);
    expect(
      find.text('Catat pengeluaran pertamamu, rinciannya muncul di sini.'),
      findsOneWidget,
    );
  });
}
