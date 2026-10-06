import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:insap/core/di/injection_container.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_detail_transaksi.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_riwayat.dart';
import 'package:insap/features/transaksi/domain/usecases/hapus_transaksi.dart';
import 'package:insap/features/transaksi/domain/usecases/tambah_transaksi.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/detail_transaksi_cubit.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';
import 'package:insap/features/transaksi/presentation/riwayat/pages/halaman_detail_transaksi.dart';

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
      ];
}

class _FakeTransaksiRepository implements TransaksiRepository {
  List<TransaksiEntity> daftarPalsu = [];

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => daftarPalsu;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async =>
      daftarPalsu;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async {
    for (final t in daftarPalsu) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<int> hapus(int id) async {
    daftarPalsu.removeWhere((t) => t.id == id);
    return 1;
  }
}

void main() {
  late _FakeTransaksiRepository transaksiRepo;
  late _FakeKategoriRepository kategoriRepo;

  setUp(() async {
    await GetIt.instance.reset();

    transaksiRepo = _FakeTransaksiRepository();
    kategoriRepo = _FakeKategoriRepository();

    sl.registerLazySingleton<TransaksiRepository>(() => transaksiRepo);
    sl.registerLazySingleton<KategoriRepository>(() => kategoriRepo);

    sl.registerLazySingleton(() => AmbilKategori(sl()));
    sl.registerLazySingleton(() => TambahTransaksi(sl()));
    sl.registerLazySingleton(() => AmbilRingkasanPekan(sl()));
    sl.registerLazySingleton(() => AmbilRiwayat(sl()));
    sl.registerLazySingleton(() => HapusTransaksi(sl()));
    sl.registerLazySingleton(() => AmbilDetailTransaksi(sl()));

    sl.registerFactory(() => KategoriCubit(ambilKategori: sl()));
    sl.registerFactory(() => BerandaCubit(ambilRingkasanPekan: sl()));
    sl.registerFactory(() => RiwayatCubit(
          ambilRiwayat: sl(),
          hapusTransaksi: sl(),
          tambahTransaksi: sl(),
        ));
    sl.registerFactory(() => DetailTransaksiCubit(
          ambilDetailTransaksi: sl(),
          hapusTransaksi: sl(),
        ));
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget buatWidget(int id) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<KategoriCubit>()..muat()),
        BlocProvider(create: (_) => sl<BerandaCubit>()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: HalamanDetailTransaksi(id: id),
      ),
    );
  }

  testWidgets('menampilkan pesan ramah jika ID transaksi tidak ditemukan',
      (tester) async {
    transaksiRepo.daftarPalsu = [];

    await tester.pumpWidget(buatWidget(999));
    await tester.pumpAndSettle();

    expect(find.text('Transaksi ini sudah tidak ada'), findsOneWidget);
    expect(find.text('Kembali ke Riwayat'), findsOneWidget);
  });

  testWidgets('menampilkan rincian kuitansi jika transaksi ditemukan',
      (tester) async {
    transaksiRepo.daftarPalsu = [
      const TransaksiEntity(
        id: 10,
        jumlah: 45000,
        kategoriId: 1,
        tanggal: '2026-09-28',
        catatan: 'Beli makan malam',
        tipeKebutuhan: 'butuh',
        sumber: 'manual',
        dibuatPada: '2026-09-28T19:00:00.000',
      ),
    ];

    await tester.pumpWidget(buatWidget(10));
    await tester.pumpAndSettle();

    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('Makan'), findsOneWidget);
    expect(find.textContaining('45.000'), findsOneWidget);
    expect(find.text('Beli makan malam'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Hapus Transaksi'), 100);
    expect(find.text('Hapus Transaksi'), findsOneWidget);
  });
}
