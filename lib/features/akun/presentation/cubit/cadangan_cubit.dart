import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cadangan_info.dart';
import '../../domain/entities/rencana_cadangan.dart';
import '../../domain/repositories/cadangan_repository.dart';
import 'cadangan_state.dart';

class CadanganCubit extends Cubit<CadanganState> {
  final CadanganRepository cadanganRepository;

  CadanganCubit({required this.cadanganRepository})
    : super(const CadanganAwal());

  Stream<CadanganInfo?> pantauCadanganTerakhir(String uid) {
    return cadanganRepository.pantauCadanganTerakhir(uid);
  }

  Future<CadanganInfo?> ambilCadanganTerakhir(String uid) {
    return cadanganRepository.ambilCadanganTerakhir(uid);
  }

  /// Menghitung dampak pencadangan ke awan. Mengembalikan null bila gagal.
  Future<RencanaCadangan?> siapkanCadangan(String uid) async {
    emit(const CadanganMemuat('Memeriksa cadangan di awan...'));
    try {
      final rencana = await cadanganRepository.siapkanCadangan(uid);
      if (isClosed) return null;
      emit(const CadanganAwal());
      return rencana;
    } catch (e) {
      if (isClosed) return null;
      emit(CadanganGalat(e.toString().replaceAll('Exception: ', '')));
      return null;
    }
  }

  Future<void> cadangkanData(String uid) async {
    emit(const CadanganMemuat('Sedang mencadangkan data ke awan...'));
    try {
      await cadanganRepository.cadangkanData(uid);
      if (isClosed) return;
      final info = await cadanganRepository.ambilCadanganTerakhir(uid);
      if (isClosed) return;
      emit(CadanganSukses('Data berhasil dicadangkan ke awan!', info: info));
    } catch (e) {
      if (isClosed) return;
      emit(CadanganGalat(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> pulihkanData(String uid) async {
    emit(const CadanganMemuat('Sedang memulihkan data dari awan...'));
    try {
      final info = await cadanganRepository.pulihkanData(uid);
      if (isClosed) return;
      emit(CadanganPulihSukses(info));
    } catch (e) {
      if (isClosed) return;
      emit(CadanganGalat(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void resetStatus() {
    emit(const CadanganAwal());
  }
}
