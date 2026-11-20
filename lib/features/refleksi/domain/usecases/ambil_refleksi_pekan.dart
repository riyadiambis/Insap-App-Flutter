import 'package:equatable/equatable.dart';

import '../../../../core/utils/iso_week.dart';
import '../../../kategori/domain/entities/kategori_entity.dart';
import '../../../kategori/domain/repositories/kategori_repository.dart';
import '../../../pengaturan/domain/usecases/ambil_target_bulanan.dart';
import '../../../transaksi/domain/entities/transaksi_entity.dart';
import '../../../transaksi/domain/repositories/transaksi_repository.dart';
import '../entities/agregat_kakeibo_entity.dart';
import '../entities/refleksi_mingguan_entity.dart';
import '../repositories/refleksi_repository.dart';

class RincianKategoriRefleksi extends Equatable {
  final int kategoriId;
  final String nama;
  final String ikon;
  final String warna;
  final int total;

  const RincianKategoriRefleksi({
    required this.kategoriId,
    required this.nama,
    required this.ikon,
    required this.warna,
    required this.total,
  });

  @override
  List<Object?> get props => [kategoriId, nama, ikon, warna, total];
}

class DataRefleksiPekan extends Equatable {
  final int tahun;
  final int mingguKe;
  final DateTime awalPekan;
  final DateTime akhirPekan;
  final DateTime? tanggalAcuan;
  final AgregatKakeiboEntity agregat;
  final int totalBulanIni;
  final int totalBulanLalu;
  final List<RincianKategoriRefleksi> kategoriPekanIni;
  final List<RincianKategoriRefleksi> kategoriBulanIni;
  final RefleksiMingguanEntity? refleksiTersimpan;
  final int? targetPekanIni;
  final int? targetPekanDepan;
  final int? targetBulanan;
  final RefleksiMingguanEntity? refleksiPekanLalu;

  const DataRefleksiPekan({
    required this.tahun,
    required this.mingguKe,
    required this.awalPekan,
    required this.akhirPekan,
    this.tanggalAcuan,
    required this.agregat,
    this.totalBulanIni = 0,
    this.totalBulanLalu = 0,
    this.kategoriPekanIni = const [],
    this.kategoriBulanIni = const [],
    this.refleksiTersimpan,
    this.targetPekanIni,
    this.targetPekanDepan,
    this.targetBulanan,
    this.refleksiPekanLalu,
  });

  // selisih realisasi pekan ini terhadap target pekan ini (positif = lewat target)
  int? get selisihTarget =>
      targetPekanIni != null ? agregat.totalPekanIni - targetPekanIni! : null;

  @override
  List<Object?> get props => [
    tahun,
    mingguKe,
    awalPekan,
    akhirPekan,
    tanggalAcuan,
    agregat,
    totalBulanIni,
    totalBulanLalu,
    kategoriPekanIni,
    kategoriBulanIni,
    refleksiTersimpan,
    targetPekanIni,
    targetPekanDepan,
    targetBulanan,
    refleksiPekanLalu,
  ];
}

// F-08: hitung agregat 4 kelompok Kakeibo, porsi pengen, dan ambil catatan refleksi pekan berjalan
class AmbilRefleksiPekan {
  final RefleksiRepository refleksiRepository;
  final TransaksiRepository transaksiRepository;
  final KategoriRepository kategoriRepository;
  final AmbilTargetBulanan? ambilTargetBulanan;
  final DateTime Function() sekarang;

  AmbilRefleksiPekan({
    required this.refleksiRepository,
    required this.transaksiRepository,
    required this.kategoriRepository,
    this.ambilTargetBulanan,
    DateTime Function()? sekarang,
  }) : sekarang = sekarang ?? DateTime.now;

  Future<DataRefleksiPekan> call([DateTime? tanggalAcuan]) async {
    final DateTime acuan = tanggalAcuan ?? sekarang();
    final RentangMinggu pekanIni = rentangMingguIso(acuan);
    final RentangMinggu pekanLalu = rentangMingguIso(
      acuan.subtract(const Duration(days: 7)),
    );

    final int tahun = pekanIni.awal.add(const Duration(days: 3)).year;
    final int mingguKe = isoWeekNumber(acuan);

    final List<TransaksiEntity> daftarPekanIni = await transaksiRepository
        .ambilDaftar(
          tanggalMulai: formatTanggalIso(pekanIni.awal),
          tanggalAkhir: formatTanggalIso(pekanIni.akhir),
        );

    final List<TransaksiEntity> daftarPekanLalu = await transaksiRepository
        .ambilDaftar(
          tanggalMulai: formatTanggalIso(pekanLalu.awal),
          tanggalAkhir: formatTanggalIso(pekanLalu.akhir),
        );

    final List<KategoriEntity> daftarKategori = await kategoriRepository
        .ambilSemua();

    // petakan id kategori ke kelompok kakeibo
    final Map<int, String> petaKelompok = {
      for (final k in daftarKategori)
        if (k.id != null) k.id!: k.kelompokKakeibo,
    };

    int hitungTotalKelompok(String kelompok) {
      return daftarPekanIni
          .where((t) => (petaKelompok[t.kategoriId] ?? 'ekstra') == kelompok)
          .fold<int>(0, (sum, t) => sum + t.jumlah);
    }

    final int totalEsensial = hitungTotalKelompok('esensial');
    final int totalOpsional = hitungTotalKelompok('opsional');
    final int totalHiburan = hitungTotalKelompok('hiburan');
    final int totalEkstra = hitungTotalKelompok('ekstra');

    final int totalPekanIni = daftarPekanIni.fold<int>(
      0,
      (sum, t) => sum + t.jumlah,
    );
    final int totalPekanLalu = daftarPekanLalu.fold<int>(
      0,
      (sum, t) => sum + t.jumlah,
    );

    final int totalPengen = daftarPekanIni
        .where((t) => t.tipeKebutuhan == 'pengen')
        .fold<int>(0, (sum, t) => sum + t.jumlah);

    // cegah pembagian nol saat pekan belum ada transaksi (Jebakan 6)
    int hitungPersen(int bagian, int total) {
      if (total <= 0) return 0;
      return ((bagian * 100) / total).round();
    }

    final agregat = AgregatKakeiboEntity(
      totalEsensial: totalEsensial,
      totalOpsional: totalOpsional,
      totalHiburan: totalHiburan,
      totalEkstra: totalEkstra,
      totalPekanIni: totalPekanIni,
      totalPekanLalu: totalPekanLalu,
      totalPengen: totalPengen,
      persentasePengen: hitungPersen(totalPengen, totalPekanIni),
      persenEsensial: hitungPersen(totalEsensial, totalPekanIni),
      persenOpsional: hitungPersen(totalOpsional, totalPekanIni),
      persenHiburan: hitungPersen(totalHiburan, totalPekanIni),
      persenEkstra: hitungPersen(totalEkstra, totalPekanIni),
    );

    final refleksiTersimpan = await refleksiRepository.ambilPerMinggu(
      tahun,
      mingguKe,
    );
    final targetDariPengaturan = await refleksiRepository.bacaTargetPekanDepan(
      tahun: tahun,
      mingguKe: mingguKe,
    );

    // bila refleksi pekan ini sudah disimpan, pakai target_pengeluaran dari baris itu.
    // bila belum pernah disimpan, salin dari target yang dicadangkan tepat dari pekan sebelumnya.
    final int? targetPekanIni = refleksiTersimpan != null
        ? refleksiTersimpan.targetPengeluaran
        : targetDariPengaturan;

    // Ambil refleksi pekan lalu untuk Kartu Pekan Lalu (K3)
    final int tahunLalu = pekanLalu.awal.add(const Duration(days: 3)).year;
    final int mingguLalu = isoWeekNumber(acuan.subtract(const Duration(days: 7)));
    final refleksiPekanLalu = await refleksiRepository.ambilPerMinggu(
      tahunLalu,
      mingguLalu,
    );

    // Ambil target pekan depan yang sudah disimpan saat refleksi pekan ini diisi
    final DateTime acuanDepan = pekanIni.awal.add(const Duration(days: 7));
    final RentangMinggu pekanDepan = rentangMingguIso(acuanDepan);
    final int tahunDepan = pekanDepan.awal.add(const Duration(days: 3)).year;
    final int mingguDepan = isoWeekNumber(acuanDepan);
    final targetPekanDepan = await refleksiRepository.bacaTargetPekanDepan(
      tahun: tahunDepan,
      mingguKe: mingguDepan,
    );

    // Target bulanan untuk teks bantu per pekan (K2)
    final int? targetBulanan =
        ambilTargetBulanan != null ? await ambilTargetBulanan!() : null;

    // Agregat bulan ini & bulan lalu serta rincian per kategori untuk HalamanRefleksi (h17)
    final DateTime awalBulanIni = DateTime(acuan.year, acuan.month, 1);
    final DateTime akhirBulanIni = DateTime(acuan.year, acuan.month + 1, 0);
    final DateTime awalBulanLalu = DateTime(acuan.year, acuan.month - 1, 1);
    final DateTime akhirBulanLalu = DateTime(acuan.year, acuan.month, 0);

    final List<TransaksiEntity> daftarBulanIni = await transaksiRepository
        .ambilDaftar(
          tanggalMulai: formatTanggalIso(awalBulanIni),
          tanggalAkhir: formatTanggalIso(akhirBulanIni),
        );
    final List<TransaksiEntity> daftarBulanLalu = await transaksiRepository
        .ambilDaftar(
          tanggalMulai: formatTanggalIso(awalBulanLalu),
          tanggalAkhir: formatTanggalIso(akhirBulanLalu),
        );

    final int totalBulanIni = daftarBulanIni.fold<int>(
      0,
      (sum, t) => sum + t.jumlah,
    );
    final int totalBulanLalu = daftarBulanLalu.fold<int>(
      0,
      (sum, t) => sum + t.jumlah,
    );

    final Map<int, KategoriEntity> petaKategoriById = {
      for (final k in daftarKategori)
        if (k.id != null) k.id!: k,
    };

    List<RincianKategoriRefleksi> kelompokkanKategori(
      List<TransaksiEntity> daftar,
    ) {
      final Map<int, int> sumPerKategori = {};
      for (final t in daftar) {
        sumPerKategori[t.kategoriId] =
            (sumPerKategori[t.kategoriId] ?? 0) + t.jumlah;
      }
      final list = sumPerKategori.entries.map((e) {
        final kat = petaKategoriById[e.key];
        return RincianKategoriRefleksi(
          kategoriId: e.key,
          nama: kat?.nama ?? 'lainnya',
          ikon: kat?.ikon ?? 'more_horiz',
          warna: kat?.warna ?? '#5B7793',
          total: e.value,
        );
      }).toList();

      list.sort((a, b) {
        final cmp = b.total.compareTo(a.total);
        if (cmp != 0) return cmp;
        return a.kategoriId.compareTo(b.kategoriId);
      });
      return list;
    }

    return DataRefleksiPekan(
      tahun: tahun,
      mingguKe: mingguKe,
      awalPekan: pekanIni.awal,
      akhirPekan: pekanIni.akhir,
      tanggalAcuan: acuan,
      agregat: agregat,
      totalBulanIni: totalBulanIni,
      totalBulanLalu: totalBulanLalu,
      kategoriPekanIni: kelompokkanKategori(daftarPekanIni),
      kategoriBulanIni: kelompokkanKategori(daftarBulanIni),
      refleksiTersimpan: refleksiTersimpan,
      targetPekanIni: targetPekanIni,
      targetPekanDepan: targetPekanDepan,
      targetBulanan: targetBulanan,
      refleksiPekanLalu: refleksiPekanLalu,
    );
  }
}
