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

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tahun': tahun,
      'minggu_ke': mingguKe,
      'target_pengeluaran': targetPengeluaran,
      'realisasi': realisasi,
      'catatan_refleksi': catatanRefleksi,
      'dibuat_pada': dibuatPada,
    };
  }

  factory RefleksiMingguanModel.fromMap(Map<String, dynamic> map) {
    return RefleksiMingguanModel(
      id: map['id'] as int?,
      tahun: map['tahun'] as int,
      mingguKe: map['minggu_ke'] as int,
      targetPengeluaran: map['target_pengeluaran'] as int?,
      realisasi: map['realisasi'] as int,
      catatanRefleksi: map['catatan_refleksi'] as String?,
      dibuatPada: map['dibuat_pada'] as String,
    );
  }
}
