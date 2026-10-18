import '../repositories/pengaturan_repository.dart';

/// Kasus penggunaan untuk menyimpan status penyembunyian popup panduan pemindaian struk (Tahap 3).
class SimpanStatusPanduanPindai {
  final PengaturanRepository repository;

  SimpanStatusPanduanPindai(this.repository);

  Future<void> call(bool disembunyikan) async {
    await repository.simpanPengaturan(
      'panduan_pindai_disembunyikan',
      disembunyikan ? '1' : '0',
    );
  }
}
