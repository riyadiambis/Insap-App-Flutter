import '../../../../core/utils/iso_week.dart';
import '../entities/ringkasan_pekan_entity.dart';
import '../repositories/transaksi_repository.dart';

// F-05: hitung ringkasan pekan buat beranda. pakai rentangMingguIso buat
// rentang pekan ini & pekan lalu, tanggalnya diformat yyyy-MM-dd dulu
// sebelum dikirim ke repository (Jebakan 1, ISSUE-02)
class AmbilRingkasanPekan {
  final TransaksiRepository repository;

  // bawaannya DateTime.now, bisa diganti pas testing biar tanggal acuan
  // tetap
  final DateTime Function() sekarang;

  AmbilRingkasanPekan(this.repository, {DateTime Function()? sekarang})
      : sekarang = sekarang ?? DateTime.now;

  Future<RingkasanPekanEntity> call() async {
    final DateTime hariIni = sekarang();
    final RentangMinggu pekanIni = rentangMingguIso(hariIni);
    final RentangMinggu pekanLalu = rentangMingguIso(
      hariIni.subtract(const Duration(days: 7)),
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
