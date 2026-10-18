import 'package:dio/dio.dart';

import '../../../../core/network/gemini_client.dart';
import '../../domain/entities/hasil_pindai_entity.dart';
import '../../domain/repositories/pindai_repository.dart';
import '../datasources/kuota_local_datasource.dart';
import '../datasources/pindai_remote_datasource.dart';

class PindaiRepositoryImpl implements PindaiRepository {
  final PindaiRemoteDataSource remoteDataSource;
  final KuotaLocalDataSource localDataSource;

  PindaiRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<HasilPindaiEntity> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
    CancelToken? cancelToken,
  }) async {
    // 1. Periksa ketersediaan kuota
    final sisaKuota = await localDataSource.ambilSisaKuota();
    if (sisaKuota <= 0) {
      throw const GeminiException('Kuota pemindaian struk pekan ini sudah habis');
    }

    // 2. Kirim permintaan ke Gemini API
    final hasil = await remoteDataSource.pindaiStruk(
      imagePath: imagePath,
      daftarKategori: daftarKategori,
      cancelToken: cancelToken,
    );

    // 3. Potong kuota HANYA jika terverifikasi sebagai struk belanja DAN belum dibatalkan (GEMINI-CONTRACT.md, No 5)
    if (hasil.adalahStruk && (cancelToken == null || !cancelToken.isCancelled)) {
      await localDataSource.potongKuota();
    }

    return hasil;
  }

  @override
  Future<int> ambilSisaKuota() {
    return localDataSource.ambilSisaKuota();
  }

  @override
  Future<void> potongKuota() {
    return localDataSource.potongKuota();
  }
}
