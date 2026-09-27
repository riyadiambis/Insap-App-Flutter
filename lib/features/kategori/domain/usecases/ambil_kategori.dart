import '../entities/kategori_entity.dart';
import '../repositories/kategori_repository.dart';

// F-03: ambil semua kategori, urut sesuai kolom urutan
class AmbilKategori {
  final KategoriRepository repository;

  AmbilKategori(this.repository);

  Future<List<KategoriEntity>> call() {
    return repository.ambilSemua();
  }
}
