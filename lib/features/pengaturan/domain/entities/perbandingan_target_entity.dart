import 'package:equatable/equatable.dart';

/// Entitas domain yang merepresentasikan perbandingan antara total pengeluaran
/// bulan berjalan terhadap target bulanan yang telah ditetapkan.
class PerbandinganTargetEntity extends Equatable {
  final int totalBulanIni;
  final int? targetBulanan;
  final double persen;
  final int sisa;
  final int lewat;
  final bool isLewat;
  final bool isTepat;
  final bool adaTarget;

  const PerbandinganTargetEntity({
    required this.totalBulanIni,
    this.targetBulanan,
    required this.persen,
    required this.sisa,
    required this.lewat,
    required this.isLewat,
    required this.isTepat,
    required this.adaTarget,
  });

  /// Factory untuk menghitung perbandingan secara murni di lapisan domain (Modul 01 & P07-Clean).
  factory PerbandinganTargetEntity.hitung({
    required int totalBulanIni,
    int? targetBulanan,
  }) {
    if (targetBulanan == null || targetBulanan <= 0) {
      return PerbandinganTargetEntity(
        totalBulanIni: totalBulanIni,
        targetBulanan: null,
        persen: 0.0,
        sisa: 0,
        lewat: 0,
        isLewat: false,
        isTepat: false,
        adaTarget: false,
      );
    }

    final double persen = totalBulanIni / targetBulanan;
    final int sisa =
        totalBulanIni < targetBulanan ? (targetBulanan - totalBulanIni) : 0;
    final int lewat =
        totalBulanIni > targetBulanan ? (totalBulanIni - targetBulanan) : 0;
    final bool isLewat = totalBulanIni > targetBulanan;
    final bool isTepat = totalBulanIni == targetBulanan;

    return PerbandinganTargetEntity(
      totalBulanIni: totalBulanIni,
      targetBulanan: targetBulanan,
      persen: persen,
      sisa: sisa,
      lewat: lewat,
      isLewat: isLewat,
      isTepat: isTepat,
      adaTarget: true,
    );
  }

  @override
  List<Object?> get props => [
        totalBulanIni,
        targetBulanan,
        persen,
        sisa,
        lewat,
        isLewat,
        isTepat,
        adaTarget,
      ];
}
