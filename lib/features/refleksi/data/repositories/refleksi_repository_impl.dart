import '../../domain/entities/refleksi_mingguan_entity.dart';
import '../../domain/repositories/refleksi_repository.dart';
import '../datasources/refleksi_local_datasource.dart';
import '../models/refleksi_mingguan_model.dart';

class RefleksiRepositoryImpl implements RefleksiRepository {
  final RefleksiLocalDataSource dataSource;

  RefleksiRepositoryImpl({required this.dataSource});

  @override
  Future<RefleksiMingguanEntity?> ambilPerMinggu(int tahun, int mingguKe) {
    return dataSource.ambilPerMinggu(tahun, mingguKe);
  }

  @override
  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi) {
    final model = RefleksiMingguanModel.fromEntity(refleksi);
    return dataSource.simpanAtauPerbarui(model);
  }

  @override
  Future<int?> bacaTargetPekanDepan() {
    return dataSource.bacaTargetPekanDepan();
  }

  @override
  Future<void> simpanTargetPekanDepan(int? target) {
    return dataSource.simpanTargetPekanDepan(target);
  }
}
