import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/kategori_entity.dart';
import '../../domain/usecases/ambil_kategori.dart';
import 'kategori_state.dart';

/// Cubit fondasi ISSUE-02, dipakai layar beranda dan catat transaksi.
/// Halaman kelola kategori (ISSUE-04) memakai `KelolaKategoriCubit`
/// terpisah, bukan Cubit ini (lihat ATURAN-GIT.md).
class KategoriCubit extends Cubit<KategoriState> {
  final AmbilKategori _ambilKategori;

  KategoriCubit({required AmbilKategori ambilKategori})
      // ignore: prefer_initializing_formals
      : _ambilKategori = ambilKategori,
        super(const KategoriInitial());

  Future<void> muat() async {
    emit(const KategoriLoading());
    try {
      final daftar = await _ambilKategori();
      emit(KategoriLoaded(daftar));
    } catch (e) {
      emit(KategoriError(e.toString()));
    }
  }

  /// Dipakai layar catat untuk mengecek `kelompokKakeibo` kategori
  /// terpilih. Mengembalikan null kalau kategori belum dimuat atau id
  /// tidak ditemukan.
  KategoriEntity? kategoriById(int id) {
    final s = state;
    if (s is KategoriLoaded) {
      for (final kategori in s.kategoriList) {
        if (kategori.id == id) return kategori;
      }
    }
    return null;
  }
}
