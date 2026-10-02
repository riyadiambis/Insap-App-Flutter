class RefleksiMingguan {
  final int? id;
  final int tahun;
  final int mingguKe;
  final int? targetPengeluaran;
  final int realisasi;
  final String? catatanRefleksi;
  final String dibuatPada;

  RefleksiMingguan({
    this.id,
    required this.tahun,
    required this.mingguKe,
    this.targetPengeluaran,
    required this.realisasi,
    this.catatanRefleksi,
    required this.dibuatPada,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tahun': tahun,
      'minggu_ke': mingguKe,
      'target_pengeluaran': targetPengeluaran,
      'realisasi': realisasi,
      'catatan_refleksi': catatanRefleksi,
      'dibuat_pada': dibuatPada,
    };
  }

  factory RefleksiMingguan.fromMap(Map<String, dynamic> map) {
    return RefleksiMingguan(
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
