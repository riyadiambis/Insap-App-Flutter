import '../entities/transaksi_entity.dart';

abstract class TransaksiRepository {
  Future<int> simpan(TransaksiEntity transaksi);

  Future<List<TransaksiEntity>> ambilTerakhir(int batas);

  Future<int> totalMingguIni(String tanggalMulai, String tanggalAkhir);

  Future<int> totalRentang(String tanggalMulai, String tanggalAkhir);

  Future<int> ambilKuotaPindai();

  /// Dibutuhkan riwayat (ISSUE-03): daftar transaksi dengan saringan
  /// rentang tanggal dan kategori, keduanya opsional.
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  });

  /// Dibutuhkan riwayat (ISSUE-03): satu transaksi berdasarkan id.
  Future<TransaksiEntity?> ambilSatu(int id);

  /// Dibutuhkan riwayat (ISSUE-03): hapus satu transaksi.
  Future<int> hapus(int id);
}
