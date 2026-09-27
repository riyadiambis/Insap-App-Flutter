import 'package:equatable/equatable.dart';

import '../../domain/entities/kategori_entity.dart';

/// State `KategoriCubit`. Sealed class empat status (P06-Cubit), seperti
/// contoh dosen P07: Initial, Loading, Loaded, Error.
sealed class KategoriState extends Equatable {
  const KategoriState();

  @override
  List<Object?> get props => [];
}

class KategoriInitial extends KategoriState {
  const KategoriInitial();
}

class KategoriLoading extends KategoriState {
  const KategoriLoading();
}

class KategoriLoaded extends KategoriState {
  final List<KategoriEntity> kategoriList;

  const KategoriLoaded(this.kategoriList);

  @override
  List<Object?> get props => [kategoriList];
}

class KategoriError extends KategoriState {
  final String pesan;

  const KategoriError(this.pesan);

  @override
  List<Object?> get props => [pesan];
}
