import '../../../../core/database/models/refleksi_mingguan.dart';
import '../../domain/entities/refleksi_mingguan_entity.dart';

class RefleksiMingguanModel extends RefleksiMingguanEntity {
  const RefleksiMingguanModel({
    super.id,
    required super.tahun,
    required super.mingguKe,
    super.targetPengeluaran,
    required super.realisasi,
    super.catatanRefleksi,
    required super.dibuatPada,
  });

  factory RefleksiMingguanModel.fromEntity(RefleksiMingguanEntity entity) {
    return RefleksiMingguanModel(
      id: entity.id,
      tahun: entity.tahun,
      mingguKe: entity.mingguKe,
      targetPengeluaran: entity.targetPengeluaran,
      realisasi: entity.realisasi,
      catatanRefleksi: entity.catatanRefleksi,
      dibuatPada: entity.dibuatPada,
    );
  }

  factory RefleksiMingguanModel.fromDatabaseModel(RefleksiMingguan dbModel) {
    return RefleksiMingguanModel(
      id: dbModel.id,
      tahun: dbModel.tahun,
      mingguKe: dbModel.mingguKe,
      targetPengeluaran: dbModel.targetPengeluaran,
      realisasi: dbModel.realisasi,
      catatanRefleksi: dbModel.catatanRefleksi,
      dibuatPada: dbModel.dibuatPada,
    );
  }

  RefleksiMingguan toDatabaseModel() {
    return RefleksiMingguan(
      id: id,
      tahun: tahun,
      mingguKe: mingguKe,
      targetPengeluaran: targetPengeluaran,
      realisasi: realisasi,
      catatanRefleksi: catatanRefleksi,
      dibuatPada: dibuatPada,
    );
  }

  Map<String, dynamic> toMap() {
    return toDatabaseModel().toMap();
  }

  factory RefleksiMingguanModel.fromMap(Map<String, dynamic> map) {
    return RefleksiMingguanModel.fromDatabaseModel(
      RefleksiMingguan.fromMap(map),
    );
  }
}
