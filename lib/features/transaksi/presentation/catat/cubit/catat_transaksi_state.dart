import 'package:equatable/equatable.dart';

/// Status isian form catat transaksi (P06-Cubit).
enum StatusCatatTransaksi { awal, menyimpan, berhasil, gagal }

/// State `CatatTransaksiCubit`. Satu class dengan field `status` berupa
/// enum dan `copyWith`, bukan sealed class, karena isian form berubah
/// sebagian demi sebagian (nominal berubah tanpa mengubah kategori,
/// kategori berubah tanpa mengubah tanggal, dan seterusnya).
class CatatTransaksiState extends Equatable {
  final StatusCatatTransaksi status;
  final int nominal;
  final int? kategoriId;

  /// Tanggal transaksi, format `yyyy-MM-dd` (Jebakan 1, ISSUE-02).
  final String tanggal;

  /// `'butuh'`, `'pengen'`, atau null. Boleh tetap null, lihat F-07.
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

  /// `hapusKategoriId`, `hapusTipeKebutuhan`, `hapusCatatan`, dan
  /// `hapusPesanKesalahan` ada supaya field nullable bisa sengaja
  /// dikosongkan lagi lewat `copyWith`. Tanpa penanda ini, pola
  /// `field ?? this.field` yang umum dipakai tidak akan pernah bisa
  /// mengembalikan field tersebut ke null.
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
