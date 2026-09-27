import '../../domain/entities/kategori_entity.dart';
import '../../domain/repositories/kategori_repository.dart';
import '../datasources/kategori_local_datasource.dart';

class KategoriRepositoryImpl implements KategoriRepository {
  final KategoriLocalDataSource _dataSource;

  KategoriRepositoryImpl({KategoriLocalDataSource? dataSource})
      : _dataSource = dataSource ?? KategoriLocalDataSource();

  @override
  Future<List<KategoriEntity>> ambilSemua() {
    return _dataSource.ambilSemua();
  }
}
