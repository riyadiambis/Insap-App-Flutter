import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'beranda_state.dart';

/// `beranda` hanya punya lapisan presentation (lihat MATERI-KULIAH.md),
/// karena seluruh datanya diambil lewat use case fitur `transaksi`.
class BerandaCubit extends Cubit<BerandaState> {
  final AmbilRingkasanPekan _ambilRingkasanPekan;

  BerandaCubit({required AmbilRingkasanPekan ambilRingkasanPekan})
      // ignore: prefer_initializing_formals
      : _ambilRingkasanPekan = ambilRingkasanPekan,
        super(const BerandaInitial());

  Future<void> muatRingkasan() async {
    emit(const BerandaLoading());
    try {
      final ringkasan = await _ambilRingkasanPekan();
      emit(BerandaLoaded(ringkasan));
    } catch (e) {
      emit(BerandaError(e.toString()));
    }
  }
}
