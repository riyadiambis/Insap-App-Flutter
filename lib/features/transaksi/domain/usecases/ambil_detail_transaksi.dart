import '../entities/transaksi_entity.dart';
import '../repositories/transaksi_repository.dart';

// F-02: ambil satu detail transaksi berdasarkan id
class AmbilDetailTransaksi {
  final TransaksiRepository repository;

  AmbilDetailTransaksi(this.repository);

  Future<TransaksiEntity?> call(int id) {
    return repository.ambilSatu(id);
  }
}
