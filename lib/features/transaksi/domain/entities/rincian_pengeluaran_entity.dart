import 'package:equatable/equatable.dart';

import 'total_kategori_entity.dart';

// entity buat membungkus total bulan ini dan rincian kategori pekan & bulan
class RincianPengeluaranEntity extends Equatable {
  final int totalBulanIni;
  final List<TotalKategoriEntity> kategoriPekanIni;
  final List<TotalKategoriEntity> kategoriBulanIni;

  const RincianPengeluaranEntity({
    required this.totalBulanIni,
    required this.kategoriPekanIni,
    required this.kategoriBulanIni,
  });

  @override
  List<Object?> get props => [
    totalBulanIni,
    kategoriPekanIni,
    kategoriBulanIni,
  ];
}
