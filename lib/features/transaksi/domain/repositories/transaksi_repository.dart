import '../entities/transaksi_entity.dart';

abstract class TransaksiRepository {
  Future<int> simpan(TransaksiEntity transaksi);

  /// Menyimpan sekumpulan transaksi secara atomik dalam satu transaksi basis data
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi);

  Future<List<TransaksiEntity>> ambilTerakhir(int batas);

  Future<int> totalMingguIni(String tanggalMulai, String tanggalAkhir);

  Future<int> totalRentang(String tanggalMulai, String tanggalAkhir);

  Future<int> ambilKuotaPindai();

  // buat riwayat (ISSUE-03): filter rentang tanggal & kategori, opsional
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  });

  // buat riwayat (ISSUE-03)
  Future<TransaksiEntity?> ambilSatu(int id);

  // buat riwayat (ISSUE-03)
  Future<int> hapus(int id);
}
