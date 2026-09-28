import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/ambil_detail_transaksi.dart';
import '../../../domain/usecases/hapus_transaksi.dart';
import 'detail_transaksi_state.dart';

// Cubit untuk detail transaksi dan hapus (F-02, P06-Cubit)
class DetailTransaksiCubit extends Cubit<DetailTransaksiState> {
  final AmbilDetailTransaksi ambilDetailTransaksi;
  final HapusTransaksi hapusTransaksi;

  DetailTransaksiCubit({
    required this.ambilDetailTransaksi,
    required this.hapusTransaksi,
  }) : super(const DetailTransaksiInitial());

  Future<void> muat(int id) async {
    emit(const DetailTransaksiLoading());
    try {
      final transaksi = await ambilDetailTransaksi(id);
      if (transaksi != null) {
        emit(DetailTransaksiLoaded(transaksi));
      } else {
        emit(const DetailTransaksiError('Transaksi ini sudah tidak ada'));
      }
    } catch (e) {
      emit(DetailTransaksiError(e.toString()));
    }
  }

  Future<bool> hapus() async {
    final currentState = state;
    if (currentState is DetailTransaksiLoaded && currentState.transaksi.id != null) {
      try {
        await hapusTransaksi(currentState.transaksi.id!);
        return true;
      } catch (e) {
        emit(DetailTransaksiError(e.toString()));
        return false;
      }
    }
    return false;
  }
}
