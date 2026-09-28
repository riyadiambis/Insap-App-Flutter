import 'package:get_it/get_it.dart';

import '../../features/beranda/presentation/cubit/beranda_cubit.dart';
import '../../features/kategori/data/datasources/kategori_local_datasource.dart';
import '../../features/kategori/data/repositories/kategori_repository_impl.dart';
import '../../features/kategori/domain/repositories/kategori_repository.dart';
import '../../features/kategori/domain/usecases/ambil_kategori.dart';
import '../../features/kategori/presentation/cubit/kategori_cubit.dart';
import '../../features/transaksi/data/datasources/transaksi_local_datasource.dart';
import '../../features/transaksi/data/repositories/transaksi_repository_impl.dart';
import '../../features/transaksi/domain/repositories/transaksi_repository.dart';
import '../../features/transaksi/domain/usecases/ambil_detail_transaksi.dart';
import '../../features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import '../../features/transaksi/domain/usecases/ambil_riwayat.dart';
import '../../features/transaksi/domain/usecases/hapus_transaksi.dart';
import '../../features/transaksi/domain/usecases/tambah_transaksi.dart';
import '../../features/transaksi/presentation/catat/cubit/catat_transaksi_cubit.dart';
import '../../features/transaksi/presentation/riwayat/cubit/detail_transaksi_cubit.dart';
import '../../features/transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';

// service locator get_it (P07-Clean). satu blok komentar per fitur,
// urutannya ikut ATURAN-GIT.md. tambah baris cuma di blok fiturmu sendiri
// biar nggak bentrok sama anggota lain.
final GetIt sl = GetIt.instance;

void setupInjectionContainer() {
  // transaksi (Riyadi)
  sl.registerLazySingleton<TransaksiLocalDataSource>(
    () => TransaksiLocalDataSource(),
  );
  sl.registerLazySingleton<TransaksiRepository>(
    () => TransaksiRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => TambahTransaksi(sl()));
  sl.registerLazySingleton(() => AmbilRingkasanPekan(sl()));
  sl.registerFactory(() => CatatTransaksiCubit(tambahTransaksi: sl()));

  // riwayat (Dafa) — AmbilRiwayat, HapusTransaksi, RiwayatCubit di ISSUE-03
  // (pakai TransaksiRepository dari blok transaksi di atas)
  sl.registerLazySingleton(() => AmbilRiwayat(sl()));
  sl.registerLazySingleton(() => HapusTransaksi(sl()));
  sl.registerLazySingleton(() => AmbilDetailTransaksi(sl()));
  sl.registerFactory(() => RiwayatCubit(
        ambilRiwayat: sl(),
        hapusTransaksi: sl(),
        tambahTransaksi: sl(),
      ));
  sl.registerFactory(() => DetailTransaksiCubit(
        ambilDetailTransaksi: sl(),
        hapusTransaksi: sl(),
      ));

  // kategori (Luthfi)
  sl.registerLazySingleton<KategoriLocalDataSource>(
    () => KategoriLocalDataSource(),
  );
  sl.registerLazySingleton<KategoriRepository>(
    () => KategoriRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => AmbilKategori(sl()));
  sl.registerFactory(() => KategoriCubit(ambilKategori: sl()));
  // KategoriCubit ini fondasi ISSUE-02, dipakai beranda & catat.
  // TambahKategori, SembunyikanKategori, KelolaKategoriCubit di ISSUE-04.

  // beranda (Riyadi) — cuma presentation, pakai AmbilRingkasanPekan
  // dari blok transaksi di atas
  sl.registerFactory(() => BerandaCubit(ambilRingkasanPekan: sl()));

  // perkenalan (Luthfi) — didaftarkan di ISSUE-05

  // refleksi (Luthfi) — SimpanRefleksi, AmbilRefleksiPekan di v0.2

  // pindai (Dafa) — PindaiStruk, AmbilKuotaPindai di v0.3
}
