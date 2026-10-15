import 'package:equatable/equatable.dart';

import '../../domain/entities/hasil_pindai_entity.dart';

enum PindaiStatus { awal, memuat, butuhKonfirmasi, gagal, tersimpan }

class PindaiState extends Equatable {
  final PindaiStatus status;
  final HasilPindaiEntity? hasilPindai;
  final int sisaKuota;
  final String? pesanGalat;
  final bool perluPeringatanKeyakinan;
  final bool tawarkanCatatManual;
  final String? imagePath;

  const PindaiState({
    this.status = PindaiStatus.awal,
    this.hasilPindai,
    this.sisaKuota = 10,
    this.pesanGalat,
    this.perluPeringatanKeyakinan = false,
    this.tawarkanCatatManual = false,
    this.imagePath,
  });

  PindaiState copyWith({
    PindaiStatus? status,
    HasilPindaiEntity? hasilPindai,
    int? sisaKuota,
    String? pesanGalat,
    bool? perluPeringatanKeyakinan,
    bool? tawarkanCatatManual,
    String? imagePath,
  }) {
    return PindaiState(
      status: status ?? this.status,
      hasilPindai: hasilPindai ?? this.hasilPindai,
      sisaKuota: sisaKuota ?? this.sisaKuota,
      pesanGalat: pesanGalat,
      perluPeringatanKeyakinan:
          perluPeringatanKeyakinan ?? this.perluPeringatanKeyakinan,
      tawarkanCatatManual: tawarkanCatatManual ?? this.tawarkanCatatManual,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  List<Object?> get props => [
    status,
    hasilPindai,
    sisaKuota,
    pesanGalat,
    perluPeringatanKeyakinan,
    tawarkanCatatManual,
    imagePath,
  ];
}
