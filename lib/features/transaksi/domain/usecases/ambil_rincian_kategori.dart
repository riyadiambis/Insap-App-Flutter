import '../../../../core/utils/iso_week.dart';
import '../entities/rincian_pengeluaran_entity.dart';
import '../entities/total_kategori_entity.dart';
import '../entities/transaksi_entity.dart';
import '../repositories/transaksi_repository.dart';

// F-05: hitung rincian pengeluaran per kategori untuk pekan dan bulan ini
class AmbilRincianKategori {
  final TransaksiRepository repository;
  final DateTime Function() sekarang;

  AmbilRincianKategori(this.repository, {DateTime Function()? sekarang})
      : sekarang = sekarang ?? DateTime.now;

  Future<RincianPengeluaranEntity> call() async {
    final DateTime hariIni = sekarang();
    final RentangMinggu pekanIni = rentangMingguIso(hariIni);
    final DateTime awalBulan = DateTime(hariIni.year, hariIni.month, 1);
    final DateTime akhirBulan = DateTime(hariIni.year, hariIni.month + 1, 0);

    final List<TransaksiEntity> daftarPekan = await repository.ambilDaftar(
      tanggalMulai: formatTanggalIso(pekanIni.awal),
      tanggalAkhir: formatTanggalIso(pekanIni.akhir),
    );

    final List<TransaksiEntity> daftarBulan = await repository.ambilDaftar(
      tanggalMulai: formatTanggalIso(awalBulan),
      tanggalAkhir: formatTanggalIso(akhirBulan),
    );

    final List<TotalKategoriEntity> kategoriPekanIni =
        _kelompokkanDanUrut(daftarPekan);
    final List<TotalKategoriEntity> kategoriBulanIni =
        _kelompokkanDanUrut(daftarBulan);

    final int totalBulanIni = kategoriBulanIni.fold<int>(
      0,
      (sum, item) => sum + item.total,
    );

    return RincianPengeluaranEntity(
      totalBulanIni: totalBulanIni,
      kategoriPekanIni: kategoriPekanIni,
      kategoriBulanIni: kategoriBulanIni,
    );
  }

  List<TotalKategoriEntity> _kelompokkanDanUrut(List<TransaksiEntity> daftar) {
    final map = daftar.fold<Map<int, int>>({}, (acc, t) {
      acc[t.kategoriId] = (acc[t.kategoriId] ?? 0) + t.jumlah;
      return acc;
    });

    final list = map.entries
        .map((e) => TotalKategoriEntity(kategoriId: e.key, total: e.value))
        .toList();

    list.sort((a, b) {
      final cmp = b.total.compareTo(a.total);
      if (cmp != 0) return cmp;
      return a.kategoriId.compareTo(b.kategoriId);
    });

    return list;
  }
}
