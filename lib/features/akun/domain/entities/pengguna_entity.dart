import 'package:equatable/equatable.dart';

class PenggunaEntity extends Equatable {
  final String uid;
  final String? email;
  final String? namaTampilan;
  final String? fotoUrl;

  const PenggunaEntity({
    required this.uid,
    this.email,
    this.namaTampilan,
    this.fotoUrl,
  });

  @override
  List<Object?> get props => [uid, email, namaTampilan, fotoUrl];
}
