import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/transaksi/domain/entities/total_kategori_entity.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_rincian_kategori.dart';

class _FakeTransaksiRepository implements TransaksiRepository {
  List<TransaksiEntity> dataPekan = const [];
  List<TransaksiEntity> dataBulan = const [];

  String? tanggalMulaiPekan;
  String? tanggalAkhirPekan;
  String? tanggalMulaiBulan;
  String? tanggalAkhirBulan;

  int _panggilan = 0;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    _panggilan++;
    if (_panggilan == 1) {
      tanggalMulaiPekan = tanggalMulai;
      tanggalAkhirPekan = tanggalAkhir;
      return dataPekan;
    } else {
      tanggalMulaiBulan = tanggalMulai;
      tanggalAkhirBulan = tanggalAkhir;
      return dataBulan;
    }
  }

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String tanggalMulai, String tanggalAkhir) async =>
      0;

  @override
  Future<int> totalRentang(String tanggalMulai, String tanggalAkhir) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;
}

void main() {
  test(
    'pengelompokan dan urutan dari terbesar, termasuk kasus total sama',
    () async {
      final fake = _FakeTransaksiRepository()
        ..dataPekan = const [
          TransaksiEntity(
            jumlah: 10000,
            kategoriId: 3,
            tanggal: '2026-10-14',
            dibuatPada: '2026-10-14T08:00:00',
          ),
          TransaksiEntity(
            jumlah: 15000,
            kategoriId: 1,
            tanggal: '2026-10-14',
            dibuatPada: '2026-10-14T09:00:00',
          ),
          TransaksiEntity(
            jumlah: 50000,
            kategoriId: 2,
            tanggal: '2026-10-15',
            dibuatPada: '2026-10-15T10:00:00',
          ),
          TransaksiEntity(
            jumlah: 15000,
            kategoriId: 3,
            tanggal: '2026-10-16',
            dibuatPada: '2026-10-16T11:00:00',
          ),
          TransaksiEntity(
            jumlah: 10000,
            kategoriId: 1,
            tanggal: '2026-10-16',
            dibuatPada: '2026-10-16T12:00:00',
          ),
          TransaksiEntity(
            jumlah: 5000,
            kategoriId: 4,
            tanggal: '2026-10-17',
            dibuatPada: '2026-10-17T13:00:00',
          ),
        ];

      final usecase = AmbilRincianKategori(fake);
      final hasil = await usecase();

      expect(hasil.kategoriPekanIni, const [
        TotalKategoriEntity(kategoriId: 2, total: 50000),
        TotalKategoriEntity(kategoriId: 1, total: 25000),
        TotalKategoriEntity(kategoriId: 3, total: 25000),
        TotalKategoriEntity(kategoriId: 4, total: 5000),
      ]);
    },
  );

  test(
    'totalBulanIni sama dengan jumlah seluruh transaksi bulan ini',
    () async {
      final fake = _FakeTransaksiRepository()
        ..dataBulan = const [
          TransaksiEntity(
            jumlah: 30000,
            kategoriId: 1,
            tanggal: '2026-10-02',
            dibuatPada: '2026-10-02T08:00:00',
          ),
          TransaksiEntity(
            jumlah: 45000,
            kategoriId: 2,
            tanggal: '2026-10-10',
            dibuatPada: '2026-10-10T09:00:00',
          ),
          TransaksiEntity(
            jumlah: 25000,
            kategoriId: 1,
            tanggal: '2026-10-20',
            dibuatPada: '2026-10-20T10:00:00',
          ),
        ];

      final usecase = AmbilRincianKategori(fake);
      final hasil = await usecase();

      expect(hasil.totalBulanIni, 100000);
    },
  );

  test(
    'rentang bulan untuk 15 Oktober 2026: 2026-10-01 sampai 2026-10-31',
    () async {
      final fake = _FakeTransaksiRepository();
      final usecase = AmbilRincianKategori(
        fake,
        sekarang: () => DateTime(2026, 10, 15),
      );

      await usecase();

      expect(fake.tanggalMulaiBulan, '2026-10-01');
      expect(fake.tanggalAkhirBulan, '2026-10-31');
    },
  );

  test('rentang bulan Desember: 2026-12-01 sampai 2026-12-31', () async {
    final fake = _FakeTransaksiRepository();
    final usecase = AmbilRincianKategori(
      fake,
      sekarang: () => DateTime(2026, 12, 5),
    );

    await usecase();

    expect(fake.tanggalMulaiBulan, '2026-12-01');
    expect(fake.tanggalAkhirBulan, '2026-12-31');
  });

  test('Februari tahun kabisat: 2028-02-01 sampai 2028-02-29', () async {
    final fake = _FakeTransaksiRepository();
    final usecase = AmbilRincianKategori(
      fake,
      sekarang: () => DateTime(2028, 2, 10),
    );

    await usecase();

    expect(fake.tanggalMulaiBulan, '2028-02-01');
    expect(fake.tanggalAkhirBulan, '2028-02-29');
  });

  test('tidak ada transaksi: total 0 dan kedua list kosong', () async {
    final fake = _FakeTransaksiRepository();
    final usecase = AmbilRincianKategori(fake);

    final hasil = await usecase();

    expect(hasil.totalBulanIni, 0);
    expect(hasil.kategoriPekanIni, isEmpty);
    expect(hasil.kategoriBulanIni, isEmpty);
  });
}
