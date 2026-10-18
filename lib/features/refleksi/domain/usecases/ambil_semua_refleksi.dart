import '../entities/refleksi_mingguan_entity.dart';
import '../repositories/refleksi_repository.dart';

class AmbilSemuaRefleksi {
  final RefleksiRepository repository;

  AmbilSemuaRefleksi(this.repository);

  Future<List<RefleksiMingguanEntity>> call() {
    return repository.ambilSemuaRefleksi();
  }
}
