import 'package:equatable/equatable.dart';

class RefleksiMingguanEntity extends Equatable {
  final int? id;
  final int tahun;
  final int mingguKe;
  final int? targetPengeluaran;
  final int realisasi;
  final String? catatanRefleksi;
  final String dibuatPada;

  const RefleksiMingguanEntity({
    this.id,
    required this.tahun,
    required this.mingguKe,
    this.targetPengeluaran,
    required this.realisasi,
    this.catatanRefleksi,
    required this.dibuatPada,
  });

  RefleksiMingguanEntity copyWith({
    int? id,
    int? tahun,
    int? mingguKe,
    int? targetPengeluaran,
    int? realisasi,
    String? catatanRefleksi,
    String? dibuatPada,
  }) {
    return RefleksiMingguanEntity(
      id: id ?? this.id,
      tahun: tahun ?? this.tahun,
      mingguKe: mingguKe ?? this.mingguKe,
      targetPengeluaran: targetPengeluaran ?? this.targetPengeluaran,
      realisasi: realisasi ?? this.realisasi,
      catatanRefleksi: catatanRefleksi ?? this.catatanRefleksi,
      dibuatPada: dibuatPada ?? this.dibuatPada,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tahun,
    mingguKe,
    targetPengeluaran,
    realisasi,
    catatanRefleksi,
    dibuatPada,
  ];
}
