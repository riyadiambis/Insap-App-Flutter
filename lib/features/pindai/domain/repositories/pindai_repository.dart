import 'package:dio/dio.dart';

import '../entities/hasil_pindai_entity.dart';

abstract class PindaiRepository {
  /// Memindai struk melalui remote data source dan mengelola kuota
  Future<HasilPindaiEntity> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
    Map<String, int>? petaKategoriId,
    CancelToken? cancelToken,
  });

  /// Mengambil sisa kuota pemindaian pekan berjalan
  Future<int> ambilSisaKuota();

  /// Memotong kuota pemindaian sebanyak 1
  Future<void> potongKuota();

  /// Mengambil sisa jatah bonus pindai dari iklan pekan berjalan (maksimal 10)
  Future<int> ambilSisaBonusIklan();

  /// Menambahkan +1 bonus kuota pindai dari iklan rewarded (maksimal 10 per pekan)
  Future<bool> klaimBonusIklan();
}
