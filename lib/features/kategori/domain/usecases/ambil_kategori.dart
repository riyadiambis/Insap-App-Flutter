import '../entities/kategori_entity.dart';
import '../repositories/kategori_repository.dart';

/// Use case F-03: ambil seluruh kategori, terurut sesuai `urutan`.
class AmbilKategori {
  final KategoriRepository repository;

  AmbilKategori(this.repository);

  Future<List<KategoriEntity>> call() {
    return repository.ambilSemua();
  }
}
