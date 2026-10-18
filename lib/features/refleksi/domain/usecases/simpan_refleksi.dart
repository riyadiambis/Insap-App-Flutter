import '../../../transaksi/domain/repositories/transaksi_repository.dart';
import '../../../../core/utils/iso_week.dart';
import '../entities/refleksi_mingguan_entity.dart';
import '../repositories/refleksi_repository.dart';

// F-08: simpan atau perbarui refleksi pekan berjalan dan simpan target pekan depan
class SimpanRefleksi {
  final RefleksiRepository repository;
  final TransaksiRepository? transaksiRepository;
  final DateTime Function() sekarang;

  SimpanRefleksi(
    this.repository, {
    this.transaksiRepository,
    DateTime Function()? sekarang,
  }) : sekarang = sekarang ?? DateTime.now;

  Future<RefleksiMingguanEntity> call({
    required String catatanRefleksi,
    int realisasi = 0,
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
    if (targetPekanDepan != null && targetPekanDepan < 0) {
      throw ArgumentError('Target pekan depan tidak boleh negatif.');
    }

    final DateTime acuan = tanggalAcuan ?? sekarang();
    final RentangMinggu pekanIni = rentangMingguIso(acuan);
    final int tahunTarget =
        tahun ?? pekanIni.awal.add(const Duration(days: 3)).year;
    final int mingguTarget = mingguKe ?? isoWeekNumber(acuan);

    final existing = await repository.ambilPerMinggu(tahunTarget, mingguTarget);

    // salin target pekan ini dari kunci target_pekan_depan jika belum pernah disimpan
    final int? targetPekanIni =
        targetPengeluaranPekanIni ??
        (existing != null
            ? existing.targetPengeluaran
            : await repository.bacaTargetPekanDepan(
                tahun: tahunTarget,
                mingguKe: mingguTarget,
              ));

    // hitung ulang realisasi dari transaksi di basis data untuk pekan tersebut
    int realisasiFinal = realisasi;
    if (transaksiRepository != null) {
      final daftarTransaksi = await transaksiRepository!.ambilDaftar(
        tanggalMulai: formatTanggalIso(pekanIni.awal),
        tanggalAkhir: formatTanggalIso(pekanIni.akhir),
      );
      realisasiFinal = daftarTransaksi.fold<int>(0, (sum, t) => sum + t.jumlah);
    }

    if (realisasiFinal < 0) {
      throw ArgumentError('Realisasi pengeluaran tidak boleh negatif.');
    }

    final String waktuSimpan = acuan.toIso8601String();

    final entity = RefleksiMingguanEntity(
      id: existing?.id,
      tahun: tahunTarget,
      mingguKe: mingguTarget,
      targetPengeluaran: targetPekanIni,
      realisasi: realisasiFinal,
      catatanRefleksi: catatanBersih,
      dibuatPada: waktuSimpan,
    );

    final idTersimpan = await repository.simpanRefleksi(entity);

    // Simpan target bersama pekan ISO tujuannya (tepat pekan berikutnya),
    // atau hapus dari pengaturan bila kolom target dikosongkan
    if (targetPekanDepan != null && targetPekanDepan > 0) {
      final DateTime pekanDepan = pekanIni.awal.add(const Duration(days: 7));
      final int tahunDepan = pekanDepan.add(const Duration(days: 3)).year;
      final int mingguDepan = isoWeekNumber(pekanDepan);
      await repository.simpanTargetPekanDepan(
        targetPekanDepan,
        tahunTujuan: tahunDepan,
        mingguTujuan: mingguDepan,
      );
    } else {
      await repository.simpanTargetPekanDepan(null);
    }

    return entity.copyWith(id: existing?.id ?? idTersimpan);
  }
}
