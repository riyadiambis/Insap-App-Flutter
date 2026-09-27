import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/iso_week.dart';
import '../../../domain/entities/transaksi_entity.dart';
import '../../../domain/usecases/tambah_transaksi.dart';
import 'catat_transaksi_state.dart';

/// Cubit F-01. Menyimpan lewat use case `TambahTransaksi`, tidak pernah
/// memanggil `TransaksiRepository` langsung (P07-Clean).
class CatatTransaksiCubit extends Cubit<CatatTransaksiState> {
  final TambahTransaksi _tambahTransaksi;

  CatatTransaksiCubit({required TambahTransaksi tambahTransaksi})
      // ignore: prefer_initializing_formals
      : _tambahTransaksi = tambahTransaksi,
        super(CatatTransaksiState(tanggal: formatTanggalIso(DateTime.now())));

  void ubahNominal(int nominal) {
    emit(state.copyWith(nominal: nominal));
  }

  void pilihKategori(int kategoriId) {
    emit(state.copyWith(kategoriId: kategoriId));
  }

  void pilihTanggal(String tanggal) {
    emit(state.copyWith(tanggal: tanggal));
  }

  /// `tipe` berupa `'butuh'`, `'pengen'`, atau null untuk melewati
  /// pertanyaan (F-07, boleh dilewati).
  void pilihTipeKebutuhan(String? tipe) {
    if (tipe == null) {
      emit(state.copyWith(hapusTipeKebutuhan: true));
    } else {
      emit(state.copyWith(tipeKebutuhan: tipe));
    }
  }

  void ubahCatatan(String? catatan) {
    if (catatan == null || catatan.isEmpty) {
      emit(state.copyWith(hapusCatatan: true));
    } else {
      emit(state.copyWith(catatan: catatan));
    }
  }

  Future<void> simpan() async {
    if (state.nominal <= 0) {
      emit(state.copyWith(
        status: StatusCatatTransaksi.gagal,
        pesanKesalahan: 'Nominal wajib diisi.',
      ));
      return;
    }
    if (state.kategoriId == null) {
      emit(state.copyWith(
        status: StatusCatatTransaksi.gagal,
        pesanKesalahan: 'Kategori wajib dipilih.',
      ));
      return;
    }

    emit(state.copyWith(status: StatusCatatTransaksi.menyimpan));
    try {
      await _tambahTransaksi(TransaksiEntity(
        jumlah: state.nominal,
        kategoriId: state.kategoriId!,
        tanggal: state.tanggal,
        catatan: state.catatan,
        tipeKebutuhan: state.tipeKebutuhan,
        dibuatPada: DateTime.now().toIso8601String(),
      ));
      emit(state.copyWith(status: StatusCatatTransaksi.berhasil));
    } catch (e) {
      emit(state.copyWith(
        status: StatusCatatTransaksi.gagal,
        pesanKesalahan: e.toString(),
      ));
    }
  }
}
