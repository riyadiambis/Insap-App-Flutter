import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/kategori_entity.dart';
import '../../domain/usecases/ambil_kategori.dart';
import 'kategori_state.dart';

// fondasi ISSUE-02, dipakai beranda & catat. kelola kategori (ISSUE-04)
// pakai KelolaKategoriCubit sendiri, lihat ATURAN-GIT.md
class KategoriCubit extends Cubit<KategoriState> {
  final AmbilKategori ambilKategori;

  KategoriCubit({required this.ambilKategori}) : super(const KategoriInitial());

  Future<void> muat() async {
    emit(const KategoriLoading());
    try {
      final daftar = await ambilKategori();
      emit(KategoriLoaded(daftar));
    } catch (e) {
      emit(KategoriError(e.toString()));
    }
  }

  // buat layar catat, cek kelompok kakeibo kategori terpilih
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
