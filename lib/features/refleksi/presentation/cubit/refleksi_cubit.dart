import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/ambil_refleksi_pekan.dart';
import '../../domain/usecases/simpan_refleksi.dart';
import 'refleksi_state.dart';

class RefleksiCubit extends Cubit<RefleksiState> {
  final AmbilRefleksiPekan ambilRefleksiPekan;
  final SimpanRefleksi simpanRefleksi;

  RefleksiCubit({
    required this.ambilRefleksiPekan,
    required this.simpanRefleksi,
  }) : super(const RefleksiState());

  Future<void> muatRefleksi([DateTime? tanggalAcuan]) async {
    emit(state.copyWith(status: RefleksiStatus.loading, hapusPesan: true));
    try {
      final data = await ambilRefleksiPekan(tanggalAcuan);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RefleksiStatus.success,
          data: data,
          hapusPesan: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: RefleksiStatus.error, pesanGalat: e.toString()),
      );
    }
  }

  Future<void> simpan({
    required String catatanRefleksi,
    int? targetPekanDepan,
    DateTime? tanggalAcuan,
  }) async {
    emit(state.copyWith(status: RefleksiStatus.saving, hapusPesan: true));
    try {
      final realisasi = state.data?.agregat.totalPekanIni ?? 0;
      await simpanRefleksi(
        catatanRefleksi: catatanRefleksi,
        realisasi: realisasi,
        targetPekanDepan: targetPekanDepan,
        targetPengeluaranPekanIni: state.data?.targetPekanIni,
        tanggalAcuan: tanggalAcuan,
      );
      if (isClosed) return;

      final dataTerbaru = await ambilRefleksiPekan(tanggalAcuan);
      if (isClosed) return;

      emit(
        state.copyWith(
          status: RefleksiStatus.saved,
          data: dataTerbaru,
          pesanSukses: 'Refleksi mingguan berhasil disimpan!',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: RefleksiStatus.error, pesanGalat: e.toString()),
      );
    }
  }
}
