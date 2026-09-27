import '../../../../core/utils/iso_week.dart';
import '../entities/ringkasan_pekan_entity.dart';
import '../repositories/transaksi_repository.dart';

/// Use case F-05: hitung ringkasan pekan berjalan untuk layar beranda.
///
/// Memakai [rentangMingguIso] untuk menentukan rentang pekan ISO 8601
/// (Senin sampai Minggu) berjalan dan pekan sebelumnya, lalu memformat
/// tanggalnya lewat [formatTanggalIso] sebelum dikirim ke repository
/// (Jebakan 1, ISSUE-02).
class AmbilRingkasanPekan {
  final TransaksiRepository repository;

  AmbilRingkasanPekan(this.repository);

  Future<RingkasanPekanEntity> call() async {
    final DateTime sekarang = DateTime.now();
    final RentangMinggu pekanIni = rentangMingguIso(sekarang);
    final RentangMinggu pekanLalu = rentangMingguIso(
      sekarang.subtract(const Duration(days: 7)),
    );

    final int totalMingguIni = await repository.totalMingguIni(
      formatTanggalIso(pekanIni.awal),
      formatTanggalIso(pekanIni.akhir),
    );
    final int totalMingguLalu = await repository.totalRentang(
      formatTanggalIso(pekanLalu.awal),
      formatTanggalIso(pekanLalu.akhir),
    );
    final int kuotaPindai = await repository.ambilKuotaPindai();
    final transaksiTerakhir = await repository.ambilTerakhir(3);

    return RingkasanPekanEntity(
      totalMingguIni: totalMingguIni,
      totalMingguLalu: totalMingguLalu,
      selisihMingguan: totalMingguIni - totalMingguLalu,
      kuotaPindai: kuotaPindai,
      transaksiTerakhir: transaksiTerakhir,
    );
  }
}
