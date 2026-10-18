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
      tanggal: '2026-10-13',
      catatan: 'Nasi padang',
      dibuatPada: '2026-10-13T12:30:00.000',
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
  }) async => const [];

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

// font uji bawaan (Ahem) tiap hurufnya selebar 1em, beranda jadi overflow.
// pakai font asli dari assets biar lebarnya sama kayak di HP
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

  testWidgets('jam di catatan terakhir tampil tanpa label WIB', (tester) async {
    tester.view.physicalSize = const Size(460, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final transRepo = _FakeTransaksiRepository();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => KategoriCubit(
              ambilKategori: AmbilKategori(_FakeKategoriRepository()),
            )..muat(),
          ),
          BlocProvider(
            create: (_) => BerandaCubit(
              ambilRingkasanPekan: AmbilRingkasanPekan(transRepo),
            )..muatRingkasan(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HalamanBeranda(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nasi padang'), findsOneWidget);
    // dibuatPada tanpa zona waktu, jadi toLocal() tetap 12:30
    expect(find.text('12:30'), findsOneWidget);
    expect(find.textContaining('WIB'), findsNothing);
  });
}
