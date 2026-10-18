import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/refleksi/domain/entities/refleksi_mingguan_entity.dart';
import 'package:insap/features/refleksi/domain/repositories/refleksi_repository.dart';
import 'package:insap/features/refleksi/domain/usecases/ambil_refleksi_pekan.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';

class _FakeKategoriRepository implements KategoriRepository {
  @override
  Future<List<KategoriEntity>> ambilSemua() async => const [
    KategoriEntity(
      id: 1,
      nama: 'makan',
      ikon: 'restaurant',
      warna: '#E8734A',
      kelompokKakeibo: 'esensial',
      bawaan: 1,
      urutan: 1,
    ),
    KategoriEntity(
      id: 5,
      nama: 'jajan daring',
      ikon: 'shopping_bag',
      warna: '#8B5FBF',
      kelompokKakeibo: 'opsional',
      bawaan: 1,
      urutan: 5,
    ),
    KategoriEntity(
      id: 6,
      nama: 'nongkrong',
      ikon: 'local_cafe',
      warna: '#FFB020',
      kelompokKakeibo: 'hiburan',
      bawaan: 1,
      urutan: 6,
    ),
    KategoriEntity(
      id: 8,
      nama: 'darurat',
      ikon: 'medical_services',
      warna: '#1F9254',
      kelompokKakeibo: 'ekstra',
      bawaan: 1,
      urutan: 8,
    ),
  ];
}

class _FakeTransaksiRepository implements TransaksiRepository {
  List<TransaksiEntity> daftarPekanIni = const [];
  List<TransaksiEntity> daftarPekanLalu = const [];

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    // pekan ini: 12 - 18 Okt 2026 (2026-10-12 s.d. 2026-10-18)
    if (tanggalMulai == '2026-10-12') {
      return daftarPekanIni;
    }
    return daftarPekanLalu;
  }

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async =>
      List.generate(daftarTransaksi.length, (i) => i + 1);
}

class _FakeRefleksiRepository implements RefleksiRepository {
  RefleksiMingguanEntity? refleksiTersimpan;
  int? targetPekanDepan;

  @override
  Future<RefleksiMingguanEntity?> ambilPerMinggu(
    int tahun,
    int mingguKe,
  ) async {
    return refleksiTersimpan;
  }

  @override
  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi) async => 1;

  @override
  Future<int?> bacaTargetPekanDepan({int? tahun, int? mingguKe}) async =>
      targetPekanDepan;

  @override
  Future<void> simpanTargetPekanDepan(
    int? target, {
    int? tahunTujuan,
    int? mingguTujuan,
  }) async {
    targetPekanDepan = target;
  }
}

void main() {
  late _FakeKategoriRepository fakeKategoriRepo;
  late _FakeTransaksiRepository fakeTransaksiRepo;
  late _FakeRefleksiRepository fakeRefleksiRepo;
  late AmbilRefleksiPekan useCase;

  // Minggu 18 Oktober 2026 adalah pekan ISO ke-42 (12 - 18 Okt 2026)
  final tanggalAcuan = DateTime(2026, 10, 18);

  setUp(() {
    fakeKategoriRepo = _FakeKategoriRepository();
    fakeTransaksiRepo = _FakeTransaksiRepository();
    fakeRefleksiRepo = _FakeRefleksiRepository();
    useCase = AmbilRefleksiPekan(
      refleksiRepository: fakeRefleksiRepo,
      transaksiRepository: fakeTransaksiRepo,
      kategoriRepository: fakeKategoriRepo,
      sekarang: () => tanggalAcuan,
    );
  });

  test('memisahkan transaksi ke 4 kelompok Kakeibo, menghitung porsi pengen, dan perbandingan pekan lalu', () async {
    fakeTransaksiRepo.daftarPekanIni = const [
      TransaksiEntity(
        id: 1,
        jumlah: 50000,
        kategoriId: 1, // esensial
        tanggal: '2026-10-13',
        dibuatPada: '2026-10-13T10:00:00',
      ),
      TransaksiEntity(
        id: 2,
        jumlah: 20000,
        kategoriId: 5, // opsional
        tanggal: '2026-10-14',
        tipeKebutuhan: 'pengen',
        dibuatPada: '2026-10-14T12:00:00',
      ),
      TransaksiEntity(
        id: 3,
        jumlah: 20000,
        kategoriId: 6, // hiburan
        tanggal: '2026-10-15',
        tipeKebutuhan: 'pengen',
        dibuatPada: '2026-10-15T15:00:00',
      ),
      TransaksiEntity(
        id: 4,
        jumlah: 10000,
        kategoriId: 8, // ekstra
        tanggal: '2026-10-16',
        dibuatPada: '2026-10-16T18:00:00',
      ),
    ];

    fakeTransaksiRepo.daftarPekanLalu = const [
      TransaksiEntity(
        id: 5,
        jumlah: 80000,
        kategoriId: 1,
        tanggal: '2026-10-08',
        dibuatPada: '2026-10-08T09:00:00',
      ),
    ];

    final hasil = await useCase();

    expect(hasil.tahun, 2026);
    expect(hasil.mingguKe, 42);
    expect(hasil.agregat.totalEsensial, 50000);
    expect(hasil.agregat.totalOpsional, 20000);
    expect(hasil.agregat.totalHiburan, 20000);
    expect(hasil.agregat.totalEkstra, 10000);
    expect(hasil.agregat.totalPekanIni, 100000);
    expect(hasil.agregat.totalPekanLalu, 80000);
    expect(hasil.agregat.selisihPekanLalu, 20000);
    expect(hasil.agregat.totalPengen, 40000);
    expect(hasil.agregat.persentasePengen, 40);
    expect(hasil.agregat.persenEsensial, 50);
    expect(hasil.agregat.persenOpsional, 20);
    expect(hasil.agregat.persenHiburan, 20);
    expect(hasil.agregat.persenEkstra, 10);
  });

  test('pekan tanpa transaksi menghasilkan seluruh total 0 dan persentase 0 tanpa galat pembagian nol', () async {
    final hasil = await useCase();

    expect(hasil.agregat.totalPekanIni, 0);
    expect(hasil.agregat.totalPekanLalu, 0);
    expect(hasil.agregat.totalEsensial, 0);
    expect(hasil.agregat.totalOpsional, 0);
    expect(hasil.agregat.totalHiburan, 0);
    expect(hasil.agregat.totalEkstra, 0);
    expect(hasil.agregat.totalPengen, 0);
    expect(hasil.agregat.persentasePengen, 0);
    expect(hasil.agregat.adaTransaksi, isFalse);
    expect(hasil.targetPekanIni, isNull);
  });

  test('membaca target pekan ini dari kunci target_pekan_depan bila refleksi pekan ini belum disimpan', () async {
    fakeRefleksiRepo.targetPekanDepan = 350000;

    final hasil = await useCase();

    expect(hasil.refleksiTersimpan, isNull);
    expect(hasil.targetPekanIni, 350000);
    expect(hasil.targetPekanDepan, 350000);
  });

  test('memakai target_pengeluaran dari refleksiTersimpan bila pekan ini sudah pernah disimpan', () async {
    fakeRefleksiRepo.refleksiTersimpan = const RefleksiMingguanEntity(
      id: 1,
      tahun: 2026,
      mingguKe: 42,
      targetPengeluaran: 350000,
      realisasi: 300000,
      catatanRefleksi: 'Bawa botol minum dari kos',
      dibuatPada: '2026-10-18T19:00:00',
    );
    fakeRefleksiRepo.targetPekanDepan = 280000;

    final hasil = await useCase();

    expect(hasil.refleksiTersimpan, isNotNull);
    expect(hasil.targetPekanIni, 350000);
    expect(hasil.targetPekanDepan, 280000);
  });
}
