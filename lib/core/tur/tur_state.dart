import 'package:equatable/equatable.dart';

class TurState extends Equatable {
  /// Petunjuk lagi tampil atau tidak.
  final bool aktif;

  /// Langkah yang lagi disorot, mulai dari 0.
  final int indeks;

  /// Pengguna sudah masuk akun, jadi langkah akun tidak mengajak daftar lagi.
  final bool sudahMasuk;

  const TurState({
    this.aktif = false,
    this.indeks = 0,
    this.sudahMasuk = false,
  });

  TurState copyWith({bool? aktif, int? indeks, bool? sudahMasuk}) {
    return TurState(
      aktif: aktif ?? this.aktif,
      indeks: indeks ?? this.indeks,
      sudahMasuk: sudahMasuk ?? this.sudahMasuk,
    );
  }

  @override
  List<Object?> get props => [aktif, indeks, sudahMasuk];
}
