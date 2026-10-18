import 'package:equatable/equatable.dart';

class AgregatKakeiboEntity extends Equatable {
  final int totalEsensial;
  final int totalOpsional;
  final int totalHiburan;
  final int totalEkstra;
  final int totalPekanIni;
  final int totalPekanLalu;
  final int totalPengen;
  final int persentasePengen;
  final int persenEsensial;
  final int persenOpsional;
  final int persenHiburan;
  final int persenEkstra;

  const AgregatKakeiboEntity({
    required this.totalEsensial,
    required this.totalOpsional,
    required this.totalHiburan,
    required this.totalEkstra,
    required this.totalPekanIni,
    required this.totalPekanLalu,
    required this.totalPengen,
    required this.persentasePengen,
    this.persenEsensial = 0,
    this.persenOpsional = 0,
    this.persenHiburan = 0,
    this.persenEkstra = 0,
  });

  int get selisihPekanLalu => totalPekanIni - totalPekanLalu;

  bool get adaTransaksi => totalPekanIni > 0;

  double get porsiEsensial =>
      totalPekanIni > 0 ? (totalEsensial / totalPekanIni).clamp(0.0, 1.0) : 0.0;

  double get porsiOpsional =>
      totalPekanIni > 0 ? (totalOpsional / totalPekanIni).clamp(0.0, 1.0) : 0.0;

  double get porsiHiburan =>
      totalPekanIni > 0 ? (totalHiburan / totalPekanIni).clamp(0.0, 1.0) : 0.0;

  double get porsiEkstra =>
      totalPekanIni > 0 ? (totalEkstra / totalPekanIni).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [
    totalEsensial,
    totalOpsional,
    totalHiburan,
    totalEkstra,
    totalPekanIni,
    totalPekanLalu,
    totalPengen,
    persentasePengen,
    persenEsensial,
    persenOpsional,
    persenHiburan,
    persenEkstra,
  ];
}
