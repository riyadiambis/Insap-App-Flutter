import 'package:equatable/equatable.dart';

import '../../../transaksi/domain/entities/ringkasan_pekan_entity.dart';

/// State `BerandaCubit`. Sealed class empat status (P06-Cubit), seperti
/// contoh dosen P07: Initial, Loading, Loaded, Error.
sealed class BerandaState extends Equatable {
  const BerandaState();

  @override
  List<Object?> get props => [];
}

class BerandaInitial extends BerandaState {
  const BerandaInitial();
}

class BerandaLoading extends BerandaState {
  const BerandaLoading();
}

class BerandaLoaded extends BerandaState {
  final RingkasanPekanEntity ringkasan;

  const BerandaLoaded(this.ringkasan);

  @override
  List<Object?> get props => [ringkasan];
}

class BerandaError extends BerandaState {
  final String pesan;

  const BerandaError(this.pesan);

  @override
  List<Object?> get props => [pesan];
}
