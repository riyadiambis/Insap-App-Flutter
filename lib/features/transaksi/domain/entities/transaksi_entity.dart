import 'package:equatable/equatable.dart';

class TransaksiEntity extends Equatable {
  final int? id;
  final int jumlah;
  final int kategoriId;
  final String tanggal;
  final String? catatan;
  final String? tipeKebutuhan;
  final String sumber;
  final String? namaToko;
  final String dibuatPada;

  const TransaksiEntity({
    this.id,
    required this.jumlah,
    required this.kategoriId,
    required this.tanggal,
    this.catatan,
    this.tipeKebutuhan,
    this.sumber = 'manual',
    this.namaToko,
    required this.dibuatPada,
  });

  @override
  List<Object?> get props => [
        id,
        jumlah,
        kategoriId,
        tanggal,
        catatan,
        tipeKebutuhan,
        sumber,
        namaToko,
        dibuatPada,
      ];
}
