import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/refleksi/domain/entities/refleksi_mingguan_entity.dart';
import 'package:insap/features/refleksi/domain/repositories/refleksi_repository.dart';
import 'package:insap/features/refleksi/domain/usecases/simpan_refleksi.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';

class _InMemoryRefleksiRepository implements RefleksiRepository {
  final Map<String, RefleksiMingguanEntity> _rows = {};
  int? targetPekanDepan;
  int? tahunTujuan;
  int? mingguTujuan;
  int _nextId = 1;

  int get jumlahBaris => _rows.length;

  @override
  Future<RefleksiMingguanEntity?> ambilPerMinggu(
    int tahun,
    int mingguKe,
  ) async {
    return _rows['$tahun-$mingguKe'];
  }

  @override
  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi) async {
    final key = '${refleksi.tahun}-${refleksi.mingguKe}';
    final existing = _rows[key];
    final id = existing?.id ?? refleksi.id ?? _nextId++;
    _rows[key] = refleksi.copyWith(id: id);
    return id;
  }

  @override
  Future<int?> bacaTargetPekanDepan({int? tahun, int? mingguKe}) async {
    if (tahun != null && mingguKe != null) {
      if (tahun == tahunTujuan && mingguKe == mingguTujuan) {
        return targetPekanDepan;
      }
      return null;
    }
    return targetPekanDepan;
  }

  @override
  Future<void> simpanTargetPekanDepan(
    int? target, {
    int? tahunTujuan,
    int? mingguTujuan,
  }) async {
    targetPekanDepan = target;
    this.tahunTujuan = tahunTujuan;
    this.mingguTujuan = mingguTujuan;
  }
}

class _FakeTransaksiRepo implements TransaksiRepository {
  final List<TransaksiEntity> list = [];

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
    String? tipeKebutuhan,
  }) async {
    return list.where((t) {
      if (tanggalMulai != null && t.tanggal.compareTo(tanggalMulai) < 0) {
        return false;
      }
      if (tanggalAkhir != null && t.tanggal.compareTo(tanggalAkhir) > 0) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<int> simpan(TransaksiEntity transaksi) async {
    list.add(transaksi);
    return list.length;
  }

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async {
    list.addAll(daftarTransaksi);
    return List.generate(daftarTransaksi.length, (i) => i + 1);
  }

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => [];

  @override
  Future<int> totalMingguIni(String tanggalMulai, String tanggalAkhir) async =>
      0;

  @override
  Future<int> totalRentang(String tanggalMulai, String tanggalAkhir) async => 0;
}

void main() {
  late _InMemoryRefleksiRepository repo;
  late _FakeTransaksiRepo transaksiRepo;
  late SimpanRefleksi useCase;
  final tanggalAcuan = DateTime(2026, 10, 18); // pekan ke-42 tahun 2026

  setUp(() {
    repo = _InMemoryRefleksiRepository();
    transaksiRepo = _FakeTransaksiRepo();
    useCase = SimpanRefleksi(
      repo,
      transaksiRepository: transaksiRepo,
      sekarang: () => tanggalAcuan,
    );
  });

  test('menyimpan catatan refleksi baru, menyalin target pekan ini dari pengaturan, dan memperbarui target_pekan_depan', () async {
    repo.targetPekanDepan = 350000;
    repo.tahunTujuan = 2026;
    repo.mingguTujuan = 42;

    final tersimpan = await useCase(
      catatanRefleksi: 'Kurangi beli kopi kekinian saat nugas',
      realisasi: 320000,
      targetPekanDepan: 300000,
    );

    expect(tersimpan.tahun, 2026);
    expect(tersimpan.mingguKe, 42);
    expect(tersimpan.targetPengeluaran, 350000);
    expect(tersimpan.catatanRefleksi, 'Kurangi beli kopi kekinian saat nugas');
    expect(repo.targetPekanDepan, 300000);
    expect(repo.tahunTujuan, 2026);
    expect(repo.mingguTujuan, 43); // pekan ISO tepat berikutnya
    expect(repo.jumlahBaris, 1);
  });

  group('Tahap 1: Skenario A, B, C Target Pekan Depan', () {
    test('Skenario A (normal): target disimpan dan terbawa tepat ke pekan ISO berikutnya', () async {
      await useCase(
        catatanRefleksi: 'Catatan pekan 42',
        targetPekanDepan: 500000,
        tanggalAcuan: DateTime(2026, 10, 18), // Pekan 42
      );

      // Cek apakah terbawa ke pekan 43
      final targetPekan43 = await repo.bacaTargetPekanDepan(
        tahun: 2026,
        mingguKe: 43,
      );
      expect(targetPekan43, 500000);
    });

    test('Skenario B (dikosongkan): kolom target null/kosong menghapus target lama sehingga tidak terbawa', () async {
      // Ada target lama di pekan sebelumnya
      repo.targetPekanDepan = 400000;
      repo.tahunTujuan = 2026;
      repo.mingguTujuan = 43;

      // Pengguna mengosongkan kolom target saat simpan refleksi pekan 42
      await useCase(
        catatanRefleksi: 'Hapus target untuk pekan depan',
        targetPekanDepan: null,
        tanggalAcuan: DateTime(2026, 10, 18),
      );

      expect(repo.targetPekanDepan, isNull);
      final targetPekan43 = await repo.bacaTargetPekanDepan(
        tahun: 2026,
        mingguKe: 43,
      );
      expect(targetPekan43, isNull);
    });

    test('Skenario C (satu pekan dilewati): jika pekan 43 tidak diisi refleksi, target tidak terbawa ke pekan 44', () async {
      // Target ditetapkan saat refleksi pekan 42 untuk pekan 43
      await useCase(
        catatanRefleksi: 'Target untuk pekan depan saja',
        targetPekanDepan: 450000,
        tanggalAcuan: DateTime(2026, 10, 18), // Pekan 42
      );

      // Pekan 43 terbawa
      expect(await repo.bacaTargetPekanDepan(tahun: 2026, mingguKe: 43), 450000);

      // Tapi di pekan 44 (melewati pekan 43 tanpa refleksi), target tidak terbawa
      final targetPekan44 = await repo.bacaTargetPekanDepan(
        tahun: 2026,
        mingguKe: 44,
      );
      expect(targetPekan44, isNull);
    });
  });

  group('Tahap 2: Realisasi segar dari DB dan pekan yang sedang ditampilkan', () {
    test('halaman dibuka Minggu 23.59, disimpan Senin 00.01: baris tersimpan tetap pekan Minggu itu dengan realisasi pekan itu', () async {
      // Waktu Minggu 18 Okt 2026 pukul 23:59 (Pekan 42)
      final mingguMalam = DateTime(2026, 10, 18, 23, 59);
      // Waktu saat tombol simpan ditekan: Senin 19 Okt 2026 pukul 00:01 (Pekan 43)
      DateTime waktuSekarang = DateTime(2026, 10, 19, 0, 1);

      final useCaseDenganJam = SimpanRefleksi(
        repo,
        transaksiRepository: transaksiRepo,
        sekarang: () => waktuSekarang,
      );

      // Transaksi di hari Minggu (pekan 42) bernilai total Rp125.000
      await transaksiRepo.simpan(
        TransaksiEntity(
          id: 1,
          jumlah: 75000,
          kategoriId: 1,
          tanggal: '2026-10-15',
          tipeKebutuhan: 'butuh',
          dibuatPada: '2026-10-15T10:00:00',
        ),
      );
      await transaksiRepo.simpan(
        TransaksiEntity(
          id: 2,
          jumlah: 50000,
          kategoriId: 2,
          tanggal: '2026-10-18',
          tipeKebutuhan: 'pengen',
          dibuatPada: '2026-10-18T20:00:00',
        ),
      );

      // Simpan refleksi dengan pekan yang sedang ditampilkan di layar (pekan 42)
      final hasil = await useCaseDenganJam(
        catatanRefleksi: 'Refleksi ditulis Minggu malam disimpan Senin pagi',
        tanggalAcuan: mingguMalam, // pekan yang ditampilkan
        tahun: 2026,
        mingguKe: 42,
      );

      // Baris yang tersimpan HARUS tetap pekan 42 (Minggu), bukan pekan 43 (Senin)
      expect(hasil.tahun, 2026);
      expect(hasil.mingguKe, 42);

      // Realisasi dihitung ulang segar dari DB untuk pekan 42 = 75000 + 50000 = 125000
      expect(hasil.realisasi, 125000);

      // Verifikasi baris di repository tersimpan pada kunci pekan 42
      final tersimpan = await repo.ambilPerMinggu(2026, 42);
      expect(tersimpan, isNotNull);
      expect(tersimpan!.realisasi, 125000);

      // Pekan 43 belum ada refleksi
      final pekan43 = await repo.ambilPerMinggu(2026, 43);
      expect(pekan43, isNull);
    });

    test('penyuntingan pada pekan berjalan memperbarui baris yang sama tanpa membuat entri ganda', () async {
      repo.targetPekanDepan = 350000;
      repo.tahunTujuan = 2026;
      repo.mingguTujuan = 42;

      final pertama = await useCase(
        catatanRefleksi: 'Catatan awal',
        targetPekanDepan: 300000,
      );

      final kedua = await useCase(
        catatanRefleksi: 'Catatan diperbarui akhir pekan',
        targetPekanDepan: 280000,
      );

      expect(repo.jumlahBaris, 1);
      expect(kedua.id, pertama.id);
      expect(kedua.targetPengeluaran, 350000);
      expect(kedua.catatanRefleksi, 'Catatan diperbarui akhir pekan');
      expect(repo.targetPekanDepan, 280000);
      expect(repo.mingguTujuan, 43);
    });
  });

  test('menolak catatan refleksi kosong', () async {
    expect(
      () => useCase(catatanRefleksi: '   ', realisasi: 100000),
      throwsArgumentError,
    );
  });
}
