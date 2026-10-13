import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cadangan_info.dart';
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

  Future<void> cadangkanData(String uid) async {
    emit(const CadanganMemuat('Sedang mencadangkan data ke awan...'));
    try {
      await cadanganRepository.cadangkanData(uid);
      emit(const CadanganSukses('Data berhasil dicadangkan ke awan!'));
    } catch (e) {
      emit(CadanganGalat(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> pulihkanData(String uid) async {
    emit(const CadanganMemuat('Sedang memulihkan data dari awan...'));
    try {
      final info = await cadanganRepository.pulihkanData(uid);
      emit(CadanganPulihSukses(info));
    } catch (e) {
      emit(CadanganGalat(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void resetStatus() {
    emit(const CadanganAwal());
  }
}
