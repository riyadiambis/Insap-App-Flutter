import 'package:equatable/equatable.dart';

import '../../../domain/entities/transaksi_entity.dart';

// sealed class 4 status (P06-Cubit), ikut pola KategoriCubit & BerandaCubit
sealed class DetailTransaksiState extends Equatable {
  const DetailTransaksiState();

  @override
  List<Object?> get props => [];
}

class DetailTransaksiInitial extends DetailTransaksiState {
  const DetailTransaksiInitial();
}

class DetailTransaksiLoading extends DetailTransaksiState {
  const DetailTransaksiLoading();
}

class DetailTransaksiLoaded extends DetailTransaksiState {
  final TransaksiEntity transaksi;

  const DetailTransaksiLoaded(this.transaksi);

  @override
  List<Object?> get props => [transaksi];
}

class DetailTransaksiError extends DetailTransaksiState {
  final String pesan;

  const DetailTransaksiError(this.pesan);

  @override
  List<Object?> get props => [pesan];
}
