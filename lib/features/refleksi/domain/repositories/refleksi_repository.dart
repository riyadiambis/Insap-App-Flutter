import '../entities/refleksi_mingguan_entity.dart';

abstract class RefleksiRepository {
  Future<RefleksiMingguanEntity?> ambilPerMinggu(int tahun, int mingguKe);

  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi);

  Future<int?> bacaTargetPekanDepan();

  Future<void> simpanTargetPekanDepan(int? target);
}
