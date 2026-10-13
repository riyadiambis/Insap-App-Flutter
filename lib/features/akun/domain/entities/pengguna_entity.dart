import 'package:equatable/equatable.dart';

class PenggunaEntity extends Equatable {
  final String uid;
  final String? email;

  const PenggunaEntity({required this.uid, this.email});

  @override
  List<Object?> get props => [uid, email];
}
