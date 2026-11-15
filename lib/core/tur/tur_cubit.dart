import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/pengaturan/domain/repositories/pengaturan_repository.dart';
import 'tur_state.dart';

/// Mengatur petunjuk sorotan di layar utama (ISSUE-37).
/// Muncul sekali setelah sambutan, bisa dilewati, bisa diputar ulang.
class TurCubit extends Cubit<TurState> {
  final PengaturanRepository pengaturanRepository;
  final Future<bool> Function()? cekSudahMasuk;
  final int jumlahLangkah;

  static const String kunciSelesai = 'tur_selesai';

  TurCubit({
    required this.pengaturanRepository,
    required this.jumlahLangkah,
    this.cekSudahMasuk,
  }) : super(const TurState());

  /// Dipanggil saat layar utama pertama tampil. Petunjuk hanya mulai kalau
  /// belum pernah diselesaikan atau dilewati.
  Future<void> periksa() async {
    if (state.aktif) return;
    try {
      final nilai = await pengaturanRepository.bacaPengaturan(kunciSelesai);
      if (nilai == '1') return;
    } catch (_) {
      // gagal baca pengaturan: lebih baik tidak mengganggu pengguna
      return;
    }
    await _mulai();
  }

  /// Putar ulang dari tombol "Lihat petunjuk lagi".
  Future<void> mulaiUlang() => _mulai();

  Future<void> _mulai() async {
    var masuk = false;
    try {
      masuk = await cekSudahMasuk?.call() ?? false;
    } catch (_) {
      masuk = false;
    }
    if (isClosed) return;
    emit(TurState(aktif: true, indeks: 0, sudahMasuk: masuk));
  }

  void lanjut() {
    if (!state.aktif) return;
    if (state.indeks >= jumlahLangkah - 1) {
      selesai();
      return;
    }
    emit(state.copyWith(indeks: state.indeks + 1));
  }

  void kembali() {
    if (!state.aktif || state.indeks == 0) return;
    emit(state.copyWith(indeks: state.indeks - 1));
  }

  /// Menutup petunjuk dan mencatat supaya tidak muncul otomatis lagi.
  Future<void> selesai() async {
    if (!state.aktif) return;
    emit(const TurState());
    try {
      await pengaturanRepository.simpanPengaturan(kunciSelesai, '1');
    } catch (_) {
      // kalau gagal simpan, petunjuk muncul lagi lain kali. tidak apa-apa
    }
  }
}
