import '../../../transaksi/domain/entities/transaksi_entity.dart';
import '../../../transaksi/domain/repositories/transaksi_repository.dart';

/// Kasus penggunaan untuk menyimpan transaksi hasil pemindaian struk secara atomik (F-10, Tahap 2D).
/// Semua transaksi disimpan dalam satu db.transaction; jika salah satu gagal, semua dibatalkan.
class SimpanTransaksiPindai {
  final TransaksiRepository repository;

  SimpanTransaksiPindai(this.repository);

  Future<List<int>> call(List<TransaksiEntity> daftarTransaksi) {
    return repository.simpanBanyak(daftarTransaksi);
  }
}
