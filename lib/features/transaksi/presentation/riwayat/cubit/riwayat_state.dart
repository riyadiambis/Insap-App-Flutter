import 'package:equatable/equatable.dart';

import '../../../domain/entities/transaksi_entity.dart';

enum RiwayatStatus { initial, loading, loaded, error }

// State riwayat memakai enum status + copyWith supaya saringan tetap bertahan
// saat daftar dimuat ulang (Keputusan E, ISSUE-03)
class RiwayatState extends Equatable {
  final RiwayatStatus status;
  final List<TransaksiEntity> daftarTransaksi;
  final String? filterTanggalMulai;
  final String? filterTanggalAkhir;
  final int? filterKategoriId;
  final String? pesanError;

  const RiwayatState({
    this.status = RiwayatStatus.initial,
    this.daftarTransaksi = const [],
    this.filterTanggalMulai,
    this.filterTanggalAkhir,
    this.filterKategoriId,
    this.pesanError,
  });

  bool get isFilterAktif =>
      filterTanggalMulai != null || filterKategoriId != null;

  RiwayatState copyWith({
    RiwayatStatus? status,
    List<TransaksiEntity>? daftarTransaksi,
    String? filterTanggalMulai,
    bool resetFilterTanggal = false,
    String? filterTanggalAkhir,
    int? filterKategoriId,
    bool resetFilterKategori = false,
    String? pesanError,
  }) {
    return RiwayatState(
      status: status ?? this.status,
      daftarTransaksi: daftarTransaksi ?? this.daftarTransaksi,
      filterTanggalMulai: resetFilterTanggal
          ? null
          : (filterTanggalMulai ?? this.filterTanggalMulai),
      filterTanggalAkhir: resetFilterTanggal
          ? null
          : (filterTanggalAkhir ?? this.filterTanggalAkhir),
      filterKategoriId: resetFilterKategori
          ? null
          : (filterKategoriId ?? this.filterKategoriId),
      pesanError: pesanError ?? this.pesanError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        daftarTransaksi,
        filterTanggalMulai,
        filterTanggalAkhir,
        filterKategoriId,
        pesanError,
      ];
}
