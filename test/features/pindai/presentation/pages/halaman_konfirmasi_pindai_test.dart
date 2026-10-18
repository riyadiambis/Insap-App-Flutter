import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/pindai/domain/entities/barang_pindai.dart';
import 'package:insap/features/pindai/domain/entities/hasil_pindai_entity.dart';
import 'package:insap/features/pindai/domain/usecases/simpan_transaksi_pindai.dart';
import 'package:insap/features/pindai/presentation/pages/halaman_konfirmasi_pindai.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'package:insap/core/widgets/tombol_stabilo.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_riwayat.dart';
import 'package:insap/features/transaksi/domain/usecases/hapus_transaksi.dart';
import 'package:insap/features/transaksi/domain/usecases/tambah_transaksi.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';

class _FakeTransaksiRepository implements TransaksiRepository {
  List<TransaksiEntity> tersimpan = [];

  @override
  Future<int> simpan(TransaksiEntity transaksi) async {
    tersimpan.add(transaksi);
    return tersimpan.length;
  }

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async {
    tersimpan.addAll(daftarTransaksi);
    return List.generate(daftarTransaksi.length, (i) => i + 1);
  }

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async => tersimpan;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => tersimpan;

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;
}

class _FakeKategoriRepository implements KategoriRepository {
  @override
  Future<List<KategoriEntity>> ambilSemua() async => const [
        KategoriEntity(
          id: 1,
          nama: 'Makan',
          ikon: 'restaurant',
          warna: '#E8734A',
          kelompokKakeibo: 'esensial',
          bawaan: 1,
          urutan: 1,
        ),
        KategoriEntity(
          id: 2,
          nama: 'Jajan',
          ikon: 'local_cafe',
          warna: '#FFB800',
          kelompokKakeibo: 'opsional',
          bawaan: 1,
          urutan: 2,
        ),
        KategoriEntity(
          id: 3,
          nama: 'Hiburan',
          ikon: 'sports_esports',
          warna: '#7C4DFF',
          kelompokKakeibo: 'hiburan',
          bawaan: 1,
          urutan: 3,
        ),
      ];
}

void main() {
  final sl = GetIt.instance;
  late _FakeTransaksiRepository fakeTransaksiRepo;
  late _FakeKategoriRepository fakeKategoriRepo;

  setUp(() {
    sl.reset();
    fakeTransaksiRepo = _FakeTransaksiRepository();
    fakeKategoriRepo = _FakeKategoriRepository();

    sl.registerLazySingleton<TransaksiRepository>(() => fakeTransaksiRepo);
    sl.registerLazySingleton<KategoriRepository>(() => fakeKategoriRepo);
    sl.registerLazySingleton(() => SimpanTransaksiPindai(sl()));
    sl.registerLazySingleton(() => AmbilKategori(sl()));
    sl.registerLazySingleton(() => AmbilRingkasanPekan(sl()));
    sl.registerLazySingleton(() => AmbilRiwayat(sl()));
    sl.registerLazySingleton(() => TambahTransaksi(sl()));
    sl.registerLazySingleton(() => HapusTransaksi(sl()));

    sl.registerFactory(() => KategoriCubit(ambilKategori: sl()));
    sl.registerFactory(() => RiwayatCubit(
          ambilRiwayat: sl(),
          tambahTransaksi: sl(),
          hapusTransaksi: sl(),
        ));
    sl.registerFactory(() => BerandaCubit(
          ambilRingkasanPekan: sl(),
          ambilRincianKategori: sl(),
          ambilTargetBulanan: sl(),
          simpanTargetBulanan: sl(),
          hitungPerbandinganTarget: sl(),
        ));
  });

  tearDown(() {
    sl.reset();
  });

  Widget buatWidgetUji(HasilPindaiEntity hasilPindai) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => KategoriCubit(ambilKategori: sl())..muat(),
          ),
          BlocProvider(create: (_) => sl<RiwayatCubit>()),
        ],
        child: HalamanKonfirmasiPindai(hasilPindai: hasilPindai),
      ),
    );
  }

  testWidgets('Menampilkan ringkasan toko, tanggal, dan pengelompokan barang',
      (tester) async {
    tester.view.physicalSize = const Size(500, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const hasil = HasilPindaiEntity(
      adalahStruk: true,
      keyakinan: 0.95,
      namaToko: 'Indomaret Point',
      tanggal: '2026-10-18',
      total: 35000,
      barang: [
        BarangPindai(nama: 'Nasi Goreng', harga: 20000, kategoriId: 1),
        BarangPindai(nama: 'Kopi Susu', harga: 15000, kategoriId: 2),
      ],
    );

    await tester.pumpWidget(buatWidgetUji(hasil));
    await tester.pumpAndSettle();

    expect(find.text('Indomaret Point'), findsOneWidget);
    expect(find.text('Total struk'), findsOneWidget);
    expect(find.text('Dipilih'), findsOneWidget);
    expect(find.text('Rp35.000'), findsWidgets);
    expect(find.text('Nasi Goreng'), findsOneWidget);
    expect(find.text('Kopi Susu'), findsOneWidget);
    expect(find.textContaining('Simpan semua (2 transaksi)'), findsOneWidget);
  });

  testWidgets(
      'Tombol Lihat semua muncul jika barang lebih dari 10 dan tetap terhitung',
      (tester) async {
    tester.view.physicalSize = const Size(500, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final barangBanyak = List.generate(
      12,
      (i) => BarangPindai(nama: 'Barang ${i + 1}', harga: 5000, kategoriId: 1),
    );
    final hasil = HasilPindaiEntity(
      adalahStruk: true,
      keyakinan: 0.95,
      total: 60000,
      barang: barangBanyak,
    );

    await tester.pumpWidget(buatWidgetUji(hasil));
    await tester.pumpAndSettle();

    expect(find.text('Lihat semua (2 barang lagi)'), findsOneWidget);
    expect(find.text('Barang 1'), findsOneWidget);
    expect(find.text('Barang 10'), findsOneWidget);
    expect(find.text('Barang 11'), findsNothing);

    // Buka semua
    await tester.tap(find.text('Lihat semua (2 barang lagi)'));
    await tester.pumpAndSettle();

    expect(find.text('Barang 11'), findsOneWidget);
    expect(find.text('Barang 12'), findsOneWidget);
  });

  testWidgets(
      'Hapus centang barang menurunkan nominal dipilih dan jika semua batal tombol simpan nonaktif',
      (tester) async {
    tester.view.physicalSize = const Size(500, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const hasil = HasilPindaiEntity(
      adalahStruk: true,
      keyakinan: 0.9,
      total: 30000,
      barang: [
        BarangPindai(nama: 'Item A', harga: 10000, kategoriId: 1),
        BarangPindai(nama: 'Item B', harga: 20000, kategoriId: 1),
      ],
    );

    await tester.pumpWidget(buatWidgetUji(hasil));
    await tester.pumpAndSettle();

    expect(find.text('Rp30.000'), findsWidgets);

    // Hapus centang item pertama
    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.first);
    await tester.pumpAndSettle();

    expect(find.text('Rp20.000'), findsWidgets);

    // Hapus centang item kedua
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();

    expect(find.text('Rp0'), findsNWidgets(2));
    // Tombol simpan nonaktif (TombolStabilo dengan onPressed null)
    final tombolSimpan = tester.widget<TombolStabilo>(
      find.byType(TombolStabilo),
    );
    expect(tombolSimpan.onPressed, isNull);
  });

  testWidgets('Sunting harga barang memperbarui subtotal', (tester) async {
    tester.view.physicalSize = const Size(500, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const hasil = HasilPindaiEntity(
      adalahStruk: true,
      keyakinan: 0.9,
      total: 15000,
      barang: [
        BarangPindai(nama: 'Es Teh', harga: 15000, kategoriId: 2),
      ],
    );

    await tester.pumpWidget(buatWidgetUji(hasil));
    await tester.pumpAndSettle();

    // Ketuk harga untuk menyunting
    await tester.tap(find.text('Rp15.000').last);
    await tester.pumpAndSettle();

    expect(find.text('Sunting Harga'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '18000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Rp18.000'), findsWidgets);
  });
}
