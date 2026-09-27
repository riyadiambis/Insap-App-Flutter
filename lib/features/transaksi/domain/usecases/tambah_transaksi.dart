import '../entities/transaksi_entity.dart';
import '../repositories/transaksi_repository.dart';

// F-01: simpan satu transaksi baru
class TambahTransaksi {
  final TransaksiRepository repository;

  TambahTransaksi(this.repository);

  Future<int> call(TransaksiEntity transaksi) {
    return repository.simpan(transaksi);
  }
}
