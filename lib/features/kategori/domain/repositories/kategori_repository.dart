import '../entities/kategori_entity.dart';

abstract class KategoriRepository {
  Future<List<KategoriEntity>> ambilSemua();
}
