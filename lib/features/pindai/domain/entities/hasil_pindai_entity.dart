import 'package:equatable/equatable.dart';

import 'barang_pindai.dart';

/// Entitas domain yang merepresentasikan hasil ekstraksi OCR AI dari struk belanja (F-09, GEMINI-CONTRACT).
class HasilPindaiEntity extends Equatable {
  final bool adalahStruk;
  final String? namaToko;
  final String? tanggal;
  final int? total;
  final String? kategoriUsulan;
  final double keyakinan;
  final List<BarangPindai> barang;
  final bool totalDihitungDariBarang;

  const HasilPindaiEntity({
    required this.adalahStruk,
    this.namaToko,
    this.tanggal,
    this.total,
    this.kategoriUsulan,
    required this.keyakinan,
    this.barang = const [],
    this.totalDihitungDariBarang = false,
  });

  @override
  List<Object?> get props => [
        adalahStruk,
        namaToko,
        tanggal,
        total,
        kategoriUsulan,
        keyakinan,
        barang,
        totalDihitungDariBarang,
      ];
}
