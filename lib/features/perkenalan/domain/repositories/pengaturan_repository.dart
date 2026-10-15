abstract class PengaturanRepository {
  /// Membaca penanda apakah alur perkenalan (onboarding) sudah selesai.
  Future<bool> bacaStatusOnboarding();

  /// Menyimpan penanda status onboarding ('1' = selesai, '0' = belum).
  Future<void> simpanStatusOnboarding(bool selesai);

  /// Membaca target pengeluaran bulanan dalam Rupiah penuh, null bila belum ada.
  Future<int?> bacaTargetBulanan();

  /// Menyimpan target pengeluaran bulanan dalam Rupiah penuh ke tabel pengaturan.
  Future<void> simpanTargetBulanan(int target);

  /// Membaca nilai mentah pengaturan berdasarkan kunci.
  Future<String?> bacaPengaturan(String kunci);

  /// Menyimpan pasangan kunci-nilai ke tabel pengaturan.
  Future<void> simpanPengaturan(String kunci, String nilai);
}
