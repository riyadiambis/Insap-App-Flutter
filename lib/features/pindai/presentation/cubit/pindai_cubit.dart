import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/gemini_client.dart';
import '../../../transaksi/domain/entities/transaksi_entity.dart';
import '../../../transaksi/domain/usecases/tambah_transaksi.dart';
import '../../domain/usecases/ambil_kuota_pindai.dart';
import '../../domain/usecases/pindai_struk.dart';
import 'pindai_state.dart';

/// Cubit untuk mengelola state alur pemindaian struk dengan Gemini AI (F-09, F-10, F-11).
class PindaiCubit extends Cubit<PindaiState> {
  final PindaiStruk pindaiStruk;
  final AmbilKuotaPindai ambilKuotaPindai;
  final TambahTransaksi tambahTransaksi;

  CancelToken? _cancelToken;

  PindaiCubit({
    required this.pindaiStruk,
    required this.ambilKuotaPindai,
    required this.tambahTransaksi,
  }) : super(const PindaiState());

  /// Mengambil sisa kuota awal dari database
  Future<void> inisialisasi() async {
    try {
      final kuota = await ambilKuotaPindai();
      if (!isClosed) {
        emit(state.copyWith(sisaKuota: kuota));
      }
    } catch (_) {}
  }

  /// Membatalkan proses pemindaian yang sedang berjalan (No 5 & No 38)
  void batalkanPindai() {
    _cancelToken?.cancel('Dibatalkan oleh pengguna');
    _cancelToken = null;
    reset();
  }

  /// Memproses berkas citra struk melalui Gemini AI
  Future<void> prosesPindai({
    required String imagePath,
    required List<String> daftarKategori,
  }) async {
    _cancelToken?.cancel('Permintaan baru dimulai');
    _cancelToken = CancelToken();
    final currentCancelToken = _cancelToken;

    if (!isClosed) {
      emit(
        state.copyWith(
          status: PindaiStatus.memuat,
          pesanGalat: null,
          tawarkanCatatManual: false,
          imagePath: imagePath,
        ),
      );
    }

    try {
      final hasil = await pindaiStruk(
        imagePath: imagePath,
        daftarKategori: daftarKategori,
        cancelToken: currentCancelToken,
      );

      if (currentCancelToken?.isCancelled ?? false) {
        return;
      }

      final kuotaTerbaru = await ambilKuotaPindai();

      if (isClosed) return;

      if (!hasil.adalahStruk) {
        emit(
          state.copyWith(
            status: PindaiStatus.gagal,
            pesanGalat: 'Ini sepertinya bukan struk belanja',
            sisaKuota: kuotaTerbaru,
            tawarkanCatatManual: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: PindaiStatus.butuhKonfirmasi,
            hasilPindai: hasil,
            sisaKuota: kuotaTerbaru,
            perluPeringatanKeyakinan: hasil.keyakinan < 0.5,
            tawarkanCatatManual: false,
          ),
        );
      }
    } on GeminiException catch (e) {
      if (currentCancelToken?.isCancelled ?? false) return;
      if (isClosed) return;
      final kuotaTerbaru = await ambilKuotaPindai();
      final bool tawarkanManual =
          e.statusCode == 408 || e.statusCode == 503 || e.statusCode == 400;
      emit(
        state.copyWith(
          status: PindaiStatus.gagal,
          pesanGalat: e.pesan,
          sisaKuota: kuotaTerbaru,
          tawarkanCatatManual: tawarkanManual,
        ),
      );
    } catch (e) {
      if (currentCancelToken?.isCancelled ?? false) return;
      if (isClosed) return;
      final kuotaTerbaru = await ambilKuotaPindai();
      emit(
        state.copyWith(
          status: PindaiStatus.gagal,
          pesanGalat: 'Terjadi galat tak terduga: $e',
          sisaKuota: kuotaTerbaru,
          tawarkanCatatManual: false,
        ),
      );
    } finally {
      if (_cancelToken == currentCancelToken) {
        _cancelToken = null;
      }
    }
  }

  /// Menyimpan draf transaksi yang telah dikonfirmasi pengguna ke database (sumber: 'pindai')
  Future<bool> simpanTransaksi({
    required int jumlah,
    required int kategoriId,
    required String tanggal,
    String? catatan,
    String? namaToko,
  }) async {
    try {
      final transaksi = TransaksiEntity(
        jumlah: jumlah,
        kategoriId: kategoriId,
        tanggal: tanggal,
        catatan: catatan,
        namaToko: namaToko,
        sumber: 'pindai',
        dibuatPada: DateTime.now().toIso8601String(),
      );

      await tambahTransaksi(transaksi);
      if (!isClosed) {
        emit(state.copyWith(status: PindaiStatus.tersimpan));
      }
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PindaiStatus.gagal,
            pesanGalat: 'Gagal menyimpan transaksi: $e',
          ),
        );
      }
      return false;
    }
  }

  /// Mengembalikan state ke kondisi awal
  void reset() {
    _cancelToken?.cancel('Dibatalkan oleh pengguna');
    _cancelToken = null;
    if (!isClosed) {
      emit(PindaiState(sisaKuota: state.sisaKuota));
    }
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('Cubit ditutup');
    _cancelToken = null;
    return super.close();
  }
}
