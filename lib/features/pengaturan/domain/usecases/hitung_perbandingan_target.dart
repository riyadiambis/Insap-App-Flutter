import '../entities/perbandingan_target_entity.dart';

class HitungPerbandinganTarget {
  const HitungPerbandinganTarget();

  PerbandinganTargetEntity call({
    required int totalBulanIni,
    int? targetBulanan,
  }) {
    return PerbandinganTargetEntity.hitung(
      totalBulanIni: totalBulanIni,
      targetBulanan: targetBulanan,
    );
  }
}
