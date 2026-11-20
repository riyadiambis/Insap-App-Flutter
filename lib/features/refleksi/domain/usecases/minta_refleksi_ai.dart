import '../../../../core/utils/iso_week.dart';
import '../../../kategori/domain/entities/kategori_entity.dart';
import '../../../kategori/domain/repositories/kategori_repository.dart';
import '../../../pengaturan/domain/usecases/ambil_target_bulanan.dart';
import '../../../transaksi/domain/entities/transaksi_entity.dart';
import '../../../transaksi/domain/repositories/transaksi_repository.dart';
import '../entities/refleksi_ai_entity.dart';
import '../repositories/refleksi_ai_repository.dart';

/// Usecase untuk meminta atau mengambil saran refleksi mingguan AI.
/// Hanya mengirim ringkasan agregat tanpa catatan, nama barang, atau nama toko.
class MintaRefleksiAi {
  final RefleksiAiRepository refleksiAiRepository;
  final TransaksiRepository transaksiRepository;
  final KategoriRepository kategoriRepository;
  final AmbilTargetBulanan ambilTargetBulanan;
  final DateTime Function() sekarang;

  MintaRefleksiAi({
    required this.refleksiAiRepository,
    required this.transaksiRepository,
    required this.kategoriRepository,
    required this.ambilTargetBulanan,
    DateTime Function()? sekarang,
  }) : sekarang = sekarang ?? DateTime.now;

  Future<HasilRefleksiAi> call([DateTime? tanggalAcuan]) async {
    final DateTime acuan = tanggalAcuan ?? sekarang();
    final RentangMinggu pekanIni = rentangMingguIso(acuan);
    final RentangMinggu pekanLalu = rentangMingguIso(
      acuan.subtract(const Duration(days: 7)),
    );

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
    final int? targetBulanan = await ambilTargetBulanan();

    final int totalPekanIni = daftarPekanIni.fold<int>(
      0,
      (sum, t) => sum + t.jumlah,
    );
    final int totalPekanLalu = daftarPekanLalu.fold<int>(
      0,
      (sum, t) => sum + t.jumlah,
    );

    final evaluasi = EvaluasiHematBoncos.hitung(
      totalPekanIni: totalPekanIni,
      targetBulanan: targetBulanan,
      totalPekanLalu: totalPekanLalu,
    );

    // Agregasi per kategori tanpa menyertakan catatan/namaToko/barang.
    final Map<int, int> sumIni = {};
    final Map<int, int> countIni = {};
    for (final t in daftarPekanIni) {
      sumIni[t.kategoriId] = (sumIni[t.kategoriId] ?? 0) + t.jumlah;
      countIni[t.kategoriId] = (countIni[t.kategoriId] ?? 0) + 1;
    }

    final Map<int, int> sumLalu = {};
    for (final t in daftarPekanLalu) {
      sumLalu[t.kategoriId] = (sumLalu[t.kategoriId] ?? 0) + t.jumlah;
    }

    final Map<int, KategoriEntity> petaKategoriById = {
      for (final k in daftarKategori)
        if (k.id != null) k.id!: k,
    };
    final Map<String, KategoriEntity> petaKategoriByNama = {
      for (final k in daftarKategori) k.nama.trim().toLowerCase(): k,
    };

    final Set<int> semuaId = {...sumIni.keys, ...sumLalu.keys};
    final List<AgregatKategoriAi> daftarAgregatKategori = semuaId.map((id) {
      final kat = petaKategoriById[id];
      return AgregatKategoriAi(
        nama: (kat?.nama ?? 'lainnya').trim().toLowerCase(),
        totalPekanIni: sumIni[id] ?? 0,
        totalPekanLalu: sumLalu[id] ?? 0,
        jumlahTransaksi: countIni[id] ?? 0,
      );
    }).toList();

    daftarAgregatKategori.sort((a, b) {
      final cmp = b.totalPekanIni.compareTo(a.totalPekanIni);
      if (cmp != 0) return cmp;
      return b.totalPekanLalu.compareTo(a.totalPekanLalu);
    });

    final input = RingkasanRefleksiAiInput(
      rentangPekan: formatRentangTanggal(pekanIni.awal, pekanIni.akhir),
      tanggalSeninIso: formatTanggalIso(pekanIni.awal),
      totalPekanIni: totalPekanIni,
      targetPekanan: evaluasi.pakaiTarget ? evaluasi.pembanding : null,
      totalPekanLalu: totalPekanLalu,
      daftarKategori: daftarAgregatKategori,
    );

    final List<SaranRefleksiAi> saranMentah = await refleksiAiRepository
        .ambilAtauMintaSaran(input);

    final List<SaranRefleksiItem> saranItem = saranMentah.map((s) {
      final kat = petaKategoriByNama[s.kategori.trim().toLowerCase()];
      return SaranRefleksiItem(
        kategori: s.kategori,
        teks: s.teks,
        ikon: kat?.ikon,
        warna: kat?.warna,
      );
    }).toList();

    return HasilRefleksiAi(
      rentangPekan: input.rentangPekan,
      evaluasi: evaluasi,
      saran: saranItem,
    );
  }
}
