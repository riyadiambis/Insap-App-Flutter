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
import '../../features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import '../../features/transaksi/domain/usecases/tambah_transaksi.dart';
import '../../features/transaksi/presentation/catat/cubit/catat_transaksi_cubit.dart';

/// Instansiasi seluruh objek terpusat di sini (P07-Clean). `sl` singkatan
/// dari service locator, nama umum untuk instance global `GetIt`.
final GetIt sl = GetIt.instance;

/// Daftarkan seluruh dependency lewat get_it.
///
/// Satu blok berkomentar per fitur, dipisah satu baris kosong, dengan
/// urutan sesuai ATURAN-GIT.md: transaksi, riwayat, kategori, beranda,
/// perkenalan, refleksi, pindai. Tambahkan baris hanya di dalam blok
/// fiturmu sendiri supaya penambahan oleh anggota berbeda tidak bentrok.
void setupInjectionContainer() {
  // ---------------------------------------------------------------------
  // transaksi (Riyadi)
  // ---------------------------------------------------------------------
  sl.registerLazySingleton<TransaksiLocalDataSource>(
    () => TransaksiLocalDataSource(),
  );
  sl.registerLazySingleton<TransaksiRepository>(
    () => TransaksiRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => TambahTransaksi(sl()));
  sl.registerLazySingleton(() => AmbilRingkasanPekan(sl()));
  sl.registerFactory(() => CatatTransaksiCubit(tambahTransaksi: sl()));

  // ---------------------------------------------------------------------
  // riwayat (Dafa)
  // ---------------------------------------------------------------------
  // Use case AmbilRiwayat dan HapusTransaksi, plus RiwayatCubit,
  // didaftarkan di ISSUE-03. Keduanya memakai TransaksiRepository yang
  // sudah didaftarkan di blok transaksi di atas.

  // ---------------------------------------------------------------------
  // kategori (Luthfi)
  // ---------------------------------------------------------------------
  sl.registerLazySingleton<KategoriLocalDataSource>(
    () => KategoriLocalDataSource(),
  );
  sl.registerLazySingleton<KategoriRepository>(
    () => KategoriRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => AmbilKategori(sl()));
  sl.registerFactory(() => KategoriCubit(ambilKategori: sl()));
  // KategoriCubit ini fondasi ISSUE-02, dipakai beranda dan catat. Use
  // case TambahKategori dan SembunyikanKategori, plus
  // KelolaKategoriCubit, didaftarkan di ISSUE-04.

  // ---------------------------------------------------------------------
  // beranda (Riyadi)
  // ---------------------------------------------------------------------
  // Hanya presentation/, tidak punya domain/data sendiri, memakai
  // AmbilRingkasanPekan dari blok transaksi di atas.
  sl.registerFactory(() => BerandaCubit(ambilRingkasanPekan: sl()));

  // ---------------------------------------------------------------------
  // perkenalan (Luthfi)
  // ---------------------------------------------------------------------
  // Didaftarkan di ISSUE-05.

  // ---------------------------------------------------------------------
  // refleksi (Luthfi)
  // ---------------------------------------------------------------------
  // Use case SimpanRefleksi dan AmbilRefleksiPekan didaftarkan pada v0.2.

  // ---------------------------------------------------------------------
  // pindai (Dafa)
  // ---------------------------------------------------------------------
  // Use case PindaiStruk dan AmbilKuotaPindai didaftarkan pada v0.3.
}
