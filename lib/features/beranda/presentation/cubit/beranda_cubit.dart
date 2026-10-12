import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../transaksi/domain/entities/rincian_pengeluaran_entity.dart';
import '../../../transaksi/domain/usecases/ambil_rincian_kategori.dart';
import '../../../transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'beranda_state.dart';

// beranda cuma punya presentation, datanya dari use case fitur transaksi
class BerandaCubit extends Cubit<BerandaState> {
  final AmbilRingkasanPekan ambilRingkasanPekan;
  final AmbilRincianKategori? ambilRincianKategori;

  BerandaCubit({required this.ambilRingkasanPekan, this.ambilRincianKategori})
    : super(const BerandaInitial());

  Future<void> muatRingkasan() async {
    emit(const BerandaLoading());
    try {
      final ringkasan = await ambilRingkasanPekan();
      final rincian = ambilRincianKategori != null
          ? await ambilRincianKategori!()
          : const RincianPengeluaranEntity(
              totalBulanIni: 0,
              kategoriPekanIni: [],
              kategoriBulanIni: [],
            );
      emit(BerandaLoaded(ringkasan, rincian));
    } catch (e) {
      emit(BerandaError(e.toString()));
    }
  }
}
