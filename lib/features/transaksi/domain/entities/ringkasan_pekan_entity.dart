import 'package:equatable/equatable.dart';

import 'transaksi_entity.dart';

class RingkasanPekanEntity extends Equatable {
  final int totalMingguIni;
  final int totalMingguLalu;

  // totalMingguIni - totalMingguLalu, boleh negatif (= lebih hemat).
  // .abs() itu urusan tampilan, bukan urusan entity ini (Jebakan 2)
  final int selisihMingguan;
  final int kuotaPindai;
  final List<TransaksiEntity> transaksiTerakhir;

  const RingkasanPekanEntity({
    required this.totalMingguIni,
    required this.totalMingguLalu,
    required this.selisihMingguan,
    required this.kuotaPindai,
    required this.transaksiTerakhir,
  });

  @override
  List<Object?> get props => [
        totalMingguIni,
        totalMingguLalu,
        selisihMingguan,
        kuotaPindai,
        transaksiTerakhir,
      ];
}
