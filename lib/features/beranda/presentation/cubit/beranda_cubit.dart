import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../pengaturan/domain/usecases/ambil_target_bulanan.dart';
import '../../../pengaturan/domain/usecases/hitung_perbandingan_target.dart';
import '../../../pengaturan/domain/usecases/simpan_target_bulanan.dart';
import '../../../transaksi/domain/entities/rincian_pengeluaran_entity.dart';
import '../../../transaksi/domain/usecases/ambil_rincian_kategori.dart';
import '../../../transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'beranda_state.dart';

// beranda cuma punya presentation, datanya dari use case fitur transaksi & pengaturan
class BerandaCubit extends Cubit<BerandaState> {
  final AmbilRingkasanPekan ambilRingkasanPekan;
  // dibuat opsional supaya tes lama yang membuat BerandaCubit (termasuk tes riwayat milik Dafa) tidak perlu diubah
  final AmbilRincianKategori? ambilRincianKategori;
  final AmbilTargetBulanan? ambilTargetBulanan;
  final SimpanTargetBulanan? simpanTargetBulanan;
  final HitungPerbandinganTarget hitungPerbandinganTarget;

  BerandaCubit({
    required this.ambilRingkasanPekan,
    this.ambilRincianKategori,
    this.ambilTargetBulanan,
    this.simpanTargetBulanan,
    this.hitungPerbandinganTarget = const HitungPerbandinganTarget(),
  }) : super(const BerandaInitial());

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
      final target =
          ambilTargetBulanan != null ? await ambilTargetBulanan!() : null;
      final perbandingan = hitungPerbandinganTarget(
        totalBulanIni: rincian.totalBulanIni,
        targetBulanan: target,
      );

      emit(BerandaLoaded(
        ringkasan,
        rincian,
        targetBulanan: target,
        perbandinganTarget: perbandingan,
      ));
    } catch (e) {
      emit(BerandaError(e.toString()));
    }
  }

  Future<void> ubahTarget(int targetBaru) async {
    if (simpanTargetBulanan != null) {
      await simpanTargetBulanan!(targetBaru);
    }
    await muatRingkasan();
  }
}

