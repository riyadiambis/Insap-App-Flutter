import 'package:equatable/equatable.dart';

import '../../../pengaturan/domain/entities/perbandingan_target_entity.dart';
import '../../../transaksi/domain/entities/ringkasan_pekan_entity.dart';
import '../../../transaksi/domain/entities/rincian_pengeluaran_entity.dart';

// sealed class 4 status (P06-Cubit), ikut contoh dosen: Initial, Loading,
// Loaded, Error
sealed class BerandaState extends Equatable {
  const BerandaState();

  @override
  List<Object?> get props => [];
}

class BerandaInitial extends BerandaState {
  const BerandaInitial();
}

class BerandaLoading extends BerandaState {
  const BerandaLoading();
}

class BerandaLoaded extends BerandaState {
  final RingkasanPekanEntity ringkasan;
  final RincianPengeluaranEntity rincian;
  final int? targetBulanan;
  final PerbandinganTargetEntity perbandinganTarget;

  BerandaLoaded(
    this.ringkasan,
    this.rincian, {
    this.targetBulanan,
    PerbandinganTargetEntity? perbandinganTarget,
  }) : perbandinganTarget = perbandinganTarget ??
            PerbandinganTargetEntity.hitung(
              totalBulanIni: rincian.totalBulanIni,
              targetBulanan: targetBulanan,
            );

  @override
  List<Object?> get props => [
        ringkasan,
        rincian,
        targetBulanan,
        perbandinganTarget,
      ];
}

class BerandaError extends BerandaState {
  final String pesan;

  const BerandaError(this.pesan);

  @override
  List<Object?> get props => [pesan];
}
