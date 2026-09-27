import 'package:equatable/equatable.dart';

import 'transaksi_entity.dart';

class RingkasanPekanEntity extends Equatable {
  final int totalMingguIni;
  final int totalMingguLalu;

  /// `totalMingguIni - totalMingguLalu`. Negatif berarti lebih hemat
  /// dibanding pekan lalu. Nilai ini sengaja DISIMPAN APA ADANYA (boleh
  /// negatif) — mengambil nilai absolut adalah urusan tampilan saat
  /// memformat teks, bukan urusan use case ini (Jebakan 2, ISSUE-02).
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
