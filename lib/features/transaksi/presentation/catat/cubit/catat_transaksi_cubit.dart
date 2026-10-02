import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/iso_week.dart';
import '../../../domain/entities/transaksi_entity.dart';
import '../../../domain/usecases/tambah_transaksi.dart';
import 'catat_transaksi_state.dart';

// F-01. simpan lewat use case TambahTransaksi, jangan panggil
// TransaksiRepository langsung dari sini
class CatatTransaksiCubit extends Cubit<CatatTransaksiState> {
  final TambahTransaksi tambahTransaksi;

  CatatTransaksiCubit({required this.tambahTransaksi})
      : super(CatatTransaksiState(tanggal: formatTanggalIso(DateTime.now())));

  void ubahNominal(int nominal) {
    emit(state.copyWith(nominal: nominal));
  }

  void pilihKategori(int kategoriId) {
    emit(state.copyWith(kategoriId: kategoriId));
  }

  void pilihTanggal(String tanggal) {
    emit(state.copyWith(tanggal: tanggal));
  }

  // 'butuh', 'pengen', atau null buat skip pertanyaannya (F-07)
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
      await tambahTransaksi(TransaksiEntity(
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

  // F-01 baris 24 & 35: setelah simpan berhasil, form kembali ke keadaan awal
  // untuk transaksi berikutnya, dengan kategori awal = kategori terakhir dipakai
  void reset() {
    emit(CatatTransaksiState(
      tanggal: formatTanggalIso(DateTime.now()),
      kategoriId: state.kategoriId,
    ));
  }
}
