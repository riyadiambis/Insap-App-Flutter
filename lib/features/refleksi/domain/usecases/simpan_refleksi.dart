import '../../../../core/utils/iso_week.dart';
import '../entities/refleksi_mingguan_entity.dart';
import '../repositories/refleksi_repository.dart';

// F-08: simpan atau perbarui refleksi pekan berjalan dan simpan target pekan depan
class SimpanRefleksi {
  final RefleksiRepository repository;
  final DateTime Function() sekarang;

  SimpanRefleksi(this.repository, {DateTime Function()? sekarang})
    : sekarang = sekarang ?? DateTime.now;

  Future<RefleksiMingguanEntity> call({
    required String catatanRefleksi,
    required int realisasi,
    int? targetPekanDepan,
    int? targetPengeluaranPekanIni,
    DateTime? tanggalAcuan,
    int? tahun,
    int? mingguKe,
  }) async {
    final catatanBersih = catatanRefleksi.trim();
    if (catatanBersih.isEmpty) {
      throw ArgumentError('Catatan perbaikan tidak boleh kosong.');
    }
    if (realisasi < 0) {
      throw ArgumentError('Realisasi pengeluaran tidak boleh negatif.');
    }
    if (targetPekanDepan != null && targetPekanDepan < 0) {
      throw ArgumentError('Target pekan depan tidak boleh negatif.');
    }

    final DateTime acuan = tanggalAcuan ?? sekarang();
    final RentangMinggu pekanIni = rentangMingguIso(acuan);
    final int tahunTarget =
        tahun ?? pekanIni.awal.add(const Duration(days: 3)).year;
    final int mingguTarget = mingguKe ?? isoWeekNumber(acuan);

    final existing = await repository.ambilPerMinggu(tahunTarget, mingguTarget);

    // salin target pekan ini dari kunci target_pekan_depan sebelum kunci itu
    // diperbarui dengan target baru untuk pekan berikutnya (Jawaban PM 1)
    final int? targetPekanIni =
        targetPengeluaranPekanIni ??
        (existing != null
            ? existing.targetPengeluaran
            : await repository.bacaTargetPekanDepan());

    final String waktuSimpan = acuan.toIso8601String();

    final entity = RefleksiMingguanEntity(
      id: existing?.id,
      tahun: tahunTarget,
      mingguKe: mingguTarget,
      targetPengeluaran: targetPekanIni,
      realisasi: realisasi,
      catatanRefleksi: catatanBersih,
      dibuatPada: waktuSimpan,
    );

    final idTersimpan = await repository.simpanRefleksi(entity);

    if (targetPekanDepan != null && targetPekanDepan > 0) {
      await repository.simpanTargetPekanDepan(targetPekanDepan);
    }

    return entity.copyWith(id: existing?.id ?? idTersimpan);
  }
}
