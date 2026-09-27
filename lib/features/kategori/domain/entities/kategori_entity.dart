import 'package:equatable/equatable.dart';

class KategoriEntity extends Equatable {
  final int? id;
  final String nama;
  final String ikon;
  final String warna;
  final String kelompokKakeibo;
  final int bawaan;
  final int urutan;

  const KategoriEntity({
    this.id,
    required this.nama,
    required this.ikon,
    required this.warna,
    required this.kelompokKakeibo,
    this.bawaan = 0,
    this.urutan = 0,
  });

  @override
  List<Object?> get props => [
        id,
        nama,
        ikon,
        warna,
        kelompokKakeibo,
        bawaan,
        urutan,
      ];
}
