import 'package:equatable/equatable.dart';

import '../../domain/entities/pengguna_entity.dart';

abstract class AkunState extends Equatable {
  const AkunState();

  @override
  List<Object?> get props => [];
}

class AkunAwal extends AkunState {
  const AkunAwal();
}

class AkunMemuat extends AkunState {
  const AkunMemuat();
}

class AkunMasuk extends AkunState {
  final PenggunaEntity pengguna;

  const AkunMasuk(this.pengguna);

  @override
  List<Object?> get props => [pengguna];
}

class AkunKeluar extends AkunState {
  const AkunKeluar();
}

class AkunPesanSukses extends AkunState {
  final String pesan;

  const AkunPesanSukses(this.pesan);

  @override
  List<Object?> get props => [pesan];
}

class AkunGalat extends AkunState {
  final String pesan;

  const AkunGalat(this.pesan);

  @override
  List<Object?> get props => [pesan];
}
