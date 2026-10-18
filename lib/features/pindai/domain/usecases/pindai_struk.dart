import 'package:dio/dio.dart';

import '../entities/hasil_pindai_entity.dart';
import '../repositories/pindai_repository.dart';

/// Kasus penggunaan untuk memindai struk belanja via Gemini AI (F-09, Modul REST API Dio).
/// Kuota hanya dipotong jika hasil valid sebagai struk dan proses tidak dibatalkan.
class PindaiStruk {
  final PindaiRepository repository;

  PindaiStruk(this.repository);

  Future<HasilPindaiEntity> call({
    required String imagePath,
    required List<String> daftarKategori,
    Map<String, int>? petaKategoriId,
    CancelToken? cancelToken,
  }) {
    return repository.pindaiStruk(
      imagePath: imagePath,
      daftarKategori: daftarKategori,
      petaKategoriId: petaKategoriId,
      cancelToken: cancelToken,
    );
  }
}
