import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pengguna_entity.dart';
import '../../domain/repositories/akun_repository.dart';
import 'akun_state.dart';

class AkunCubit extends Cubit<AkunState> {
  final AkunRepository akunRepository;
  StreamSubscription<PenggunaEntity?>? _authSubscription;

  AkunCubit({required this.akunRepository}) : super(const AkunAwal()) {
    pantauStatusAuth();
  }

  void pantauStatusAuth() {
    _authSubscription?.cancel();
    _authSubscription = akunRepository.pantauPengguna().listen(
      (pengguna) {
        if (pengguna != null) {
          emit(AkunMasuk(pengguna));
        } else {
          emit(const AkunKeluar());
        }
      },
      onError: (e) {
        emit(AkunGalat(e.toString()));
      },
    );
  }

  Future<void> masukDenganEmail({
    required String email,
    required String kataSandi,
  }) async {
    emit(const AkunMemuat());
    try {
      final pengguna = await akunRepository.masukDenganEmail(
        email: email,
        kataSandi: kataSandi,
      );
      emit(AkunMasuk(pengguna));
    } catch (e) {
      emit(AkunGalat(e.toString()));
    }
  }

  Future<void> daftarDenganEmail({
    required String email,
    required String kataSandi,
  }) async {
    emit(const AkunMemuat());
    try {
      final pengguna = await akunRepository.daftarDenganEmail(
        email: email,
        kataSandi: kataSandi,
      );
      emit(AkunMasuk(pengguna));
    } catch (e) {
      emit(AkunGalat(e.toString()));
    }
  }

  Future<void> kirimResetKataSandi(String email) async {
    emit(const AkunMemuat());
    try {
      await akunRepository.kirimResetKataSandi(email);
      emit(
        const AkunPesanSukses(
          'Tautan atur ulang kata sandi telah dikirim ke surel Anda.',
        ),
      );
    } catch (e) {
      emit(AkunGalat(e.toString()));
    }
  }

  Future<void> masukDenganGoogle() async {
    emit(const AkunMemuat());
    try {
      final pengguna = await akunRepository.masukDenganGoogle();
      if (pengguna != null) {
        emit(AkunMasuk(pengguna));
      } else {
        emit(const AkunKeluar());
      }
    } catch (e) {
      emit(AkunGalat(e.toString()));
    }
  }

  Future<void> keluar() async {
    emit(const AkunMemuat());
    try {
      await akunRepository.keluar();
      emit(const AkunKeluar());
    } catch (e) {
      emit(AkunGalat(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
