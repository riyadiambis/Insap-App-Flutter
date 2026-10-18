import 'package:equatable/equatable.dart';

import '../../domain/usecases/ambil_refleksi_pekan.dart';

enum RefleksiStatus { initial, loading, success, saving, saved, error }

class RefleksiState extends Equatable {
  final RefleksiStatus status;
  final DataRefleksiPekan? data;
  final String? pesanGalat;
  final String? pesanSukses;

  const RefleksiState({
    this.status = RefleksiStatus.initial,
    this.data,
    this.pesanGalat,
    this.pesanSukses,
  });

  RefleksiState copyWith({
    RefleksiStatus? status,
    DataRefleksiPekan? data,
    String? pesanGalat,
    String? pesanSukses,
    bool hapusPesan = false,
  }) {
    return RefleksiState(
      status: status ?? this.status,
      data: data ?? this.data,
      pesanGalat: hapusPesan ? null : (pesanGalat ?? this.pesanGalat),
      pesanSukses: hapusPesan ? null : (pesanSukses ?? this.pesanSukses),
    );
  }

  @override
  List<Object?> get props => [status, data, pesanGalat, pesanSukses];
}
