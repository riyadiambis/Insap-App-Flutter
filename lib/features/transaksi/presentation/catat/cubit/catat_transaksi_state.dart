import 'package:equatable/equatable.dart';

// status isian form (P06-Cubit)
enum StatusCatatTransaksi { awal, menyimpan, berhasil, gagal }

// satu class state + copyWith, bukan sealed, soalnya isian form berubah
// sebagian-sebagian (nominal doang, kategori doang, dst)
class CatatTransaksiState extends Equatable {
  final StatusCatatTransaksi status;
  final int nominal;
  final int? kategoriId;

  // format yyyy-MM-dd (Jebakan 1, ISSUE-02)
  final String tanggal;

  // 'butuh', 'pengen', atau null (boleh tetap null, lihat F-07)
  final String? tipeKebutuhan;
  final String? catatan;
  final String? pesanKesalahan;

  const CatatTransaksiState({
    this.status = StatusCatatTransaksi.awal,
    this.nominal = 0,
    this.kategoriId,
    required this.tanggal,
    this.tipeKebutuhan,
    this.catatan,
    this.pesanKesalahan,
  });

  // flag hapusX biar field nullable bisa sengaja di-null-kan lagi, pola
  // "?? this.field" biasa nggak bisa balikin ke null
  CatatTransaksiState copyWith({
    StatusCatatTransaksi? status,
    int? nominal,
    int? kategoriId,
    bool hapusKategoriId = false,
    String? tanggal,
    String? tipeKebutuhan,
    bool hapusTipeKebutuhan = false,
    String? catatan,
    bool hapusCatatan = false,
    String? pesanKesalahan,
    bool hapusPesanKesalahan = false,
  }) {
    return CatatTransaksiState(
      status: status ?? this.status,
      nominal: nominal ?? this.nominal,
      kategoriId: hapusKategoriId ? null : (kategoriId ?? this.kategoriId),
      tanggal: tanggal ?? this.tanggal,
      tipeKebutuhan:
          hapusTipeKebutuhan ? null : (tipeKebutuhan ?? this.tipeKebutuhan),
      catatan: hapusCatatan ? null : (catatan ?? this.catatan),
      pesanKesalahan: hapusPesanKesalahan
          ? null
          : (pesanKesalahan ?? this.pesanKesalahan),
    );
  }

  @override
  List<Object?> get props => [
        status,
        nominal,
        kategoriId,
        tanggal,
        tipeKebutuhan,
        catatan,
        pesanKesalahan,
      ];
}
