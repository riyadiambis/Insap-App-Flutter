import 'package:equatable/equatable.dart';

import '../../domain/entities/refleksi_ai_entity.dart';

sealed class HasilRefleksiState extends Equatable {
  const HasilRefleksiState();

  @override
  List<Object?> get props => [];
}

class HasilRefleksiInitial extends HasilRefleksiState {
  const HasilRefleksiInitial();
}

class HasilRefleksiLoading extends HasilRefleksiState {
  const HasilRefleksiLoading();
}

class HasilRefleksiLoaded extends HasilRefleksiState {
  final HasilRefleksiAi hasil;

  const HasilRefleksiLoaded(this.hasil);

  @override
  List<Object?> get props => [hasil];
}

class HasilRefleksiError extends HasilRefleksiState {
  final String pesan;

  const HasilRefleksiError(this.pesan);

  @override
  List<Object?> get props => [pesan];
}
