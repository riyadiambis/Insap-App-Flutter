import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';

/// Repository palsu buatan sendiri, mengimplementasikan kontrak di
/// domain/. Tidak memakai mockito, mocktail, atau bloc_test.
class _FakeTransaksiRepository implements TransaksiRepository {
  int totalIni = 0;
  int totalLalu = 0;
  int kuota = 10;
  List<TransaksiEntity> terakhir = const [];

  String? tanggalMulaiIni;
  String? tanggalAkhirIni;
  String? tanggalMulaiLalu;
  String? tanggalAkhirLalu;

  @override
  Future<int> totalMingguIni(String tanggalMulai, String tanggalAkhir) async {
    tanggalMulaiIni = tanggalMulai;
    tanggalAkhirIni = tanggalAkhir;
    return totalIni;
  }

  @override
  Future<int> totalRentang(String tanggalMulai, String tanggalAkhir) async {
    tanggalMulaiLalu = tanggalMulai;
    tanggalAkhirLalu = tanggalAkhir;
    return totalLalu;
  }

  @override
  Future<int> ambilKuotaPindai() async => kuota;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => terakhir;

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async =>
      const [];

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;
}

void main() {
  final regexTanggalIso = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  test(
    'mengirim rentang pekan sebagai yyyy-MM-dd, bukan ISO lengkap (Jebakan 1)',
    () async {
      final fake = _FakeTransaksiRepository();
      final usecase = AmbilRingkasanPekan(fake);

      await usecase();

      expect(fake.tanggalMulaiIni, matches(regexTanggalIso));
      expect(fake.tanggalAkhirIni, matches(regexTanggalIso));
      expect(fake.tanggalMulaiLalu, matches(regexTanggalIso));
      expect(fake.tanggalAkhirLalu, matches(regexTanggalIso));
    },
  );

  test('pekan lalu persis 7 hari sebelum pekan ini', () async {
    final fake = _FakeTransaksiRepository();
    final usecase = AmbilRingkasanPekan(fake);

    await usecase();

    final awalIni = DateTime.parse(fake.tanggalMulaiIni!);
    final awalLalu = DateTime.parse(fake.tanggalMulaiLalu!);
    expect(awalIni.difference(awalLalu).inDays, 7);
  });

  test('menggabungkan total, kuota, dan transaksi terakhir dari repository', () async {
    final fake = _FakeTransaksiRepository()
      ..totalIni = 150000
      ..totalLalu = 100000
      ..kuota = 7
      ..terakhir = const [
        TransaksiEntity(
          jumlah: 15000,
          kategoriId: 1,
          tanggal: '2026-09-21',
          dibuatPada: '2026-09-21T10:00:00',
        ),
      ];
    final usecase = AmbilRingkasanPekan(fake);

    final hasil = await usecase();

    expect(hasil.totalMingguIni, 150000);
    expect(hasil.totalMingguLalu, 100000);
    expect(hasil.selisihMingguan, 50000);
    expect(hasil.kuotaPindai, 7);
    expect(hasil.transaksiTerakhir.length, 1);
  });

  test(
    'selisihMingguan tetap negatif (tidak diambil absolut) saat pekan ini lebih hemat',
    () async {
      // Jebakan 2 di ISSUE-02: .abs() adalah urusan pemformatan tampilan,
      // bukan urusan use case ini. Nilai domain harus tetap bertanda.
      final fake = _FakeTransaksiRepository()
        ..totalIni = 50000
        ..totalLalu = 120000;
      final usecase = AmbilRingkasanPekan(fake);

      final hasil = await usecase();

      expect(hasil.selisihMingguan, -70000);
    },
  );
}
