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

class DataRefleksiPekan extends Equatable {
  final int tahun;
  final int mingguKe;
  final DateTime awalPekan;
  final DateTime akhirPekan;
  final AgregatKakeiboEntity agregat;
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
    required this.agregat,
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
    agregat,
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

    return DataRefleksiPekan(
      tahun: tahun,
      mingguKe: mingguKe,
      awalPekan: pekanIni.awal,
      akhirPekan: pekanIni.akhir,
      agregat: agregat,
      refleksiTersimpan: refleksiTersimpan,
      targetPekanIni: targetPekanIni,
      targetPekanDepan: targetPekanDepan,
      targetBulanan: targetBulanan,
      refleksiPekanLalu: refleksiPekanLalu,
    );
  }
}
