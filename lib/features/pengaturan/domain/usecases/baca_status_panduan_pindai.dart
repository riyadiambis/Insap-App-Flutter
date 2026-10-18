import '../repositories/pengaturan_repository.dart';

/// Kasus penggunaan untuk membaca status penyembunyian popup panduan pemindaian struk (Tahap 3).
class BacaStatusPanduanPindai {
  final PengaturanRepository repository;

  BacaStatusPanduanPindai(this.repository);

  Future<bool> call() async {
    final nilai = await repository.bacaPengaturan('panduan_pindai_disembunyikan');
    return nilai == '1';
  }
}
