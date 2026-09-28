import '../entities/transaksi_entity.dart';
import '../repositories/transaksi_repository.dart';

// F-02: ambil daftar riwayat transaksi dengan filter opsional
class AmbilRiwayat {
  final TransaksiRepository repository;

  AmbilRiwayat(this.repository);

  Future<List<TransaksiEntity>> call({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) {
    return repository.ambilDaftar(
      tanggalMulai: tanggalMulai,
      tanggalAkhir: tanggalAkhir,
      kategoriId: kategoriId,
    );
  }
}
