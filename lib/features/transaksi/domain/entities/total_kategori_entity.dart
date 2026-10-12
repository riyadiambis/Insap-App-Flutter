import 'package:equatable/equatable.dart';

// entity buat menampung total pengeluaran per kategori
class TotalKategoriEntity extends Equatable {
  final int kategoriId;
  final int total;

  const TotalKategoriEntity({required this.kategoriId, required this.total});

  @override
  List<Object?> get props => [kategoriId, total];
}
