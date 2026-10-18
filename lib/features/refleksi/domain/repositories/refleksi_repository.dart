import '../entities/refleksi_mingguan_entity.dart';

abstract class RefleksiRepository {
  Future<RefleksiMingguanEntity?> ambilPerMinggu(int tahun, int mingguKe);

  Future<List<RefleksiMingguanEntity>> ambilSemuaRefleksi();

  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi);

  Future<int?> bacaTargetPekanDepan({int? tahun, int? mingguKe});

  Future<void> simpanTargetPekanDepan(
    int? target, {
    int? tahunTujuan,
    int? mingguTujuan,
  });
}
