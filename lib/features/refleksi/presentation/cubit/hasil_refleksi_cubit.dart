import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/minta_refleksi_ai.dart';
import 'hasil_refleksi_state.dart';

class HasilRefleksiCubit extends Cubit<HasilRefleksiState> {
  final MintaRefleksiAi mintaRefleksiAi;

  HasilRefleksiCubit({required this.mintaRefleksiAi})
      : super(const HasilRefleksiInitial());

  Future<void> muat([DateTime? tanggalAcuan]) async {
    emit(const HasilRefleksiLoading());
    try {
      final hasil = await mintaRefleksiAi(tanggalAcuan);
      if (isClosed) return;
      emit(HasilRefleksiLoaded(hasil));
    } catch (_) {
      if (isClosed) return;
      emit(
        const HasilRefleksiError(
          'Struki belum bisa merangkum sekarang. Coba lagi sebentar lagi.',
        ),
      );
    }
  }
}
