import '../entities/hasil_pindai_entity.dart';
import '../repositories/pindai_repository.dart';

/// Use case untuk memindai struk belanja dengan Gemini AI (F-09, P07-Clean).
class PindaiStruk {
  final PindaiRepository repository;

  PindaiStruk(this.repository);

  Future<HasilPindaiEntity> call({
    required String imagePath,
    required List<String> daftarKategori,
  }) {
    return repository.pindaiStruk(
      imagePath: imagePath,
      daftarKategori: daftarKategori,
    );
  }
}
