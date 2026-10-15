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
import '../../features/transaksi/domain/usecases/ambil_rincian_kategori.dart';
import '../../features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import '../../features/transaksi/domain/usecases/ambil_riwayat.dart';
import '../../features/transaksi/domain/usecases/hapus_transaksi.dart';
import '../../features/transaksi/domain/usecases/tambah_transaksi.dart';
import '../../features/transaksi/presentation/catat/cubit/catat_transaksi_cubit.dart';
import '../../features/transaksi/presentation/riwayat/cubit/detail_transaksi_cubit.dart';
import '../../features/transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';
import '../../features/akun/data/repositories/akun_repository_impl.dart';
import '../../features/akun/data/repositories/cadangan_repository_impl.dart';
import '../../features/akun/domain/repositories/akun_repository.dart';
import '../../features/akun/domain/repositories/cadangan_repository.dart';
import '../../features/akun/presentation/cubit/akun_cubit.dart';
import '../../features/akun/presentation/cubit/cadangan_cubit.dart';
import '../../features/perkenalan/data/datasources/pengaturan_local_datasource.dart';
import '../../features/perkenalan/data/repositories/pengaturan_repository_impl.dart';
import '../../features/perkenalan/domain/repositories/pengaturan_repository.dart';
import '../../features/perkenalan/presentation/cubit/onboarding_cubit.dart';

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
  sl.registerLazySingleton(() => AmbilRincianKategori(sl()));
  sl.registerFactory(() => CatatTransaksiCubit(tambahTransaksi: sl()));

  // riwayat (Dafa) — AmbilRiwayat, HapusTransaksi, RiwayatCubit di ISSUE-03
  // (pakai TransaksiRepository dari blok transaksi di atas)
  sl.registerLazySingleton(() => AmbilRiwayat(sl()));
  sl.registerLazySingleton(() => HapusTransaksi(sl()));
  sl.registerLazySingleton(() => AmbilDetailTransaksi(sl()));
  sl.registerFactory(
    () => RiwayatCubit(
      ambilRiwayat: sl(),
      hapusTransaksi: sl(),
      tambahTransaksi: sl(),
    ),
  );
  sl.registerFactory(
    () =>
        DetailTransaksiCubit(ambilDetailTransaksi: sl(), hapusTransaksi: sl()),
  );

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
  sl.registerFactory(
    () => BerandaCubit(ambilRingkasanPekan: sl(), ambilRincianKategori: sl()),
  );

  // perkenalan & pengaturan (ISSUE-23)
  sl.registerLazySingleton<PengaturanLocalDataSource>(
    () => PengaturanLocalDataSource(),
  );
  sl.registerLazySingleton<PengaturanRepository>(
    () => PengaturanRepositoryImpl(dataSource: sl()),
  );
  sl.registerFactory(
    () => OnboardingCubit(pengaturanRepository: sl()),
  );

  // refleksi (Luthfi) — SimpanRefleksi, AmbilRefleksiPekan di v0.2

  // pindai (Dafa) — PindaiStruk, AmbilKuotaPindai di v0.3

  // akun & cadangan (Riyadi) — ISSUE-14
  sl.registerLazySingleton<AkunRepository>(() => AkunRepositoryImpl());
  sl.registerFactory(() => AkunCubit(akunRepository: sl()));
  sl.registerLazySingleton<CadanganRepository>(() => CadanganRepositoryImpl());
  sl.registerFactory(() => CadanganCubit(cadanganRepository: sl()));
}
