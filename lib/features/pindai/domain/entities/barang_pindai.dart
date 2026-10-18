import 'package:equatable/equatable.dart';

/// Entitas domain yang merepresentasikan satu baris barang hasil pemindaian struk (F-10, GEMINI-CONTRACT).
class BarangPindai extends Equatable {
  final String nama;
  final int harga;
  final int kategoriId;
  final bool dicentang;
  final bool adalahSelisih;

  const BarangPindai({
    required this.nama,
    required this.harga,
    required this.kategoriId,
    this.dicentang = true,
    this.adalahSelisih = false,
  });

  BarangPindai copyWith({
    String? nama,
    int? harga,
    int? kategoriId,
    bool? dicentang,
    bool? adalahSelisih,
  }) {
    return BarangPindai(
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
      kategoriId: kategoriId ?? this.kategoriId,
      dicentang: dicentang ?? this.dicentang,
      adalahSelisih: adalahSelisih ?? this.adalahSelisih,
    );
  }

  @override
  List<Object?> get props => [
        nama,
        harga,
        kategoriId,
        dicentang,
        adalahSelisih,
      ];
}
