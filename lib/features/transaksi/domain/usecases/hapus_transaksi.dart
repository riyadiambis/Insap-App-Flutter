import '../repositories/transaksi_repository.dart';

// F-02: hapus satu transaksi berdasarkan id
class HapusTransaksi {
  final TransaksiRepository repository;

  HapusTransaksi(this.repository);

  Future<int> call(int id) {
    return repository.hapus(id);
  }
}
