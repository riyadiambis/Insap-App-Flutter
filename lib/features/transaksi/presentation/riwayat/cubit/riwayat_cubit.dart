import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/transaksi_entity.dart';
import '../../../domain/usecases/ambil_riwayat.dart';
import '../../../domain/usecases/hapus_transaksi.dart';
import '../../../domain/usecases/tambah_transaksi.dart';
import 'riwayat_state.dart';

// Cubit untuk daftar riwayat dan filternya (F-02, P06-Cubit)
class RiwayatCubit extends Cubit<RiwayatState> {
  final AmbilRiwayat ambilRiwayat;
  final HapusTransaksi hapusTransaksi;
  final TambahTransaksi tambahTransaksi;

  RiwayatCubit({
    required this.ambilRiwayat,
    required this.hapusTransaksi,
    required this.tambahTransaksi,
  }) : super(const RiwayatState());

  Future<void> muatRiwayat() async {
    emit(state.copyWith(status: RiwayatStatus.loading));
    try {
      final daftar = await ambilRiwayat(
        tanggalMulai: state.filterTanggalMulai,
        tanggalAkhir: state.filterTanggalAkhir,
        kategoriId: state.filterKategoriId,
      );
      emit(state.copyWith(
        status: RiwayatStatus.loaded,
        daftarTransaksi: daftar,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RiwayatStatus.error,
        pesanError: e.toString(),
      ));
    }
  }

  Future<void> terapkanFilter({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    emit(state.copyWith(
      filterTanggalMulai: tanggalMulai,
      resetFilterTanggal: tanggalMulai == null,
      filterTanggalAkhir: tanggalAkhir,
      filterKategoriId: kategoriId,
      resetFilterKategori: kategoriId == null,
    ));
    await muatRiwayat();
  }

  Future<void> resetFilter() async {
    emit(state.copyWith(
      resetFilterTanggal: true,
      resetFilterKategori: true,
    ));
    await muatRiwayat();
  }

  Future<void> hapus(TransaksiEntity transaksi) async {
    if (transaksi.id == null) return;
    try {
      await hapusTransaksi(transaksi.id!);
      await muatRiwayat();
    } catch (e) {
      emit(state.copyWith(
        status: RiwayatStatus.error,
        pesanError: e.toString(),
      ));
    }
  }

  Future<void> batalHapus(TransaksiEntity transaksi) async {
    try {
      await tambahTransaksi(transaksi);
      await muatRiwayat();
    } catch (e) {
      emit(state.copyWith(
        status: RiwayatStatus.error,
        pesanError: e.toString(),
      ));
    }
  }
}
