import 'package:equatable/equatable.dart';

import '../../domain/entities/hasil_pindai_entity.dart';

enum PindaiStatus { awal, memuat, butuhKonfirmasi, gagal, tersimpan }

enum StatusKlaimBonus { diam, sedang, berhasil, gagal }

class PindaiState extends Equatable {
  final PindaiStatus status;
  final HasilPindaiEntity? hasilPindai;
  final int sisaKuota;
  final int sisaBonusIklan;
  final StatusKlaimBonus statusKlaimBonus;
  final String? pesanGalat;
  final bool perluPeringatanKeyakinan;
  final bool tawarkanCatatManual;
  final String? imagePath;

  const PindaiState({
    this.status = PindaiStatus.awal,
    this.hasilPindai,
    this.sisaKuota = 0,
    this.sisaBonusIklan = 0,
    this.statusKlaimBonus = StatusKlaimBonus.diam,
    this.pesanGalat,
    this.perluPeringatanKeyakinan = false,
    this.tawarkanCatatManual = false,
    this.imagePath,
  });

  PindaiState copyWith({
    PindaiStatus? status,
    HasilPindaiEntity? hasilPindai,
    int? sisaKuota,
    int? sisaBonusIklan,
    StatusKlaimBonus? statusKlaimBonus,
    String? pesanGalat,
    bool? perluPeringatanKeyakinan,
    bool? tawarkanCatatManual,
    String? imagePath,
  }) {
    return PindaiState(
      status: status ?? this.status,
      hasilPindai: hasilPindai ?? this.hasilPindai,
      sisaKuota: sisaKuota ?? this.sisaKuota,
      sisaBonusIklan: sisaBonusIklan ?? this.sisaBonusIklan,
      statusKlaimBonus: statusKlaimBonus ?? this.statusKlaimBonus,
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
    sisaBonusIklan,
    statusKlaimBonus,
    pesanGalat,
    perluPeringatanKeyakinan,
    tawarkanCatatManual,
    imagePath,
  ];
}
