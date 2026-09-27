import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'beranda_state.dart';

// beranda cuma punya presentation, datanya dari use case fitur transaksi
class BerandaCubit extends Cubit<BerandaState> {
  final AmbilRingkasanPekan ambilRingkasanPekan;

  BerandaCubit({required this.ambilRingkasanPekan})
      : super(const BerandaInitial());

  Future<void> muatRingkasan() async {
    emit(const BerandaLoading());
    try {
      final ringkasan = await ambilRingkasanPekan();
      emit(BerandaLoaded(ringkasan));
    } catch (e) {
      emit(BerandaError(e.toString()));
    }
  }
}
