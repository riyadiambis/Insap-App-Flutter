import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_detail_transaksi.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_riwayat.dart';
import 'package:insap/features/transaksi/domain/usecases/hapus_transaksi.dart';

// Repository palsu buatan sendiri, tanpa mockito atau mocktail
class _FakeTransaksiRepository implements TransaksiRepository {
  String? tanggalMulaiTerpanggil;
  String? tanggalAkhirTerpanggil;
  int? kategoriIdTerpanggil;
  int? idTerhapus;
  int? idDiambil;

  List<TransaksiEntity> daftarKembalian = [];
  TransaksiEntity? detailKembalian;
  int jumlahTerhapusKembalian = 1;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    tanggalMulaiTerpanggil = tanggalMulai;
    tanggalAkhirTerpanggil = tanggalAkhir;
    kategoriIdTerpanggil = kategoriId;
    return daftarKembalian;
  }

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async {
    idDiambil = id;
    return detailKembalian;
  }

  @override
  Future<int> hapus(int id) async {
    idTerhapus = id;
    return jumlahTerhapusKembalian;
  }

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String tanggalMulai, String tanggalAkhir) async => 0;

  @override
  Future<int> totalRentang(String tanggalMulai, String tanggalAkhir) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;
}

void main() {
  late _FakeTransaksiRepository repo;
  late AmbilRiwayat ambilRiwayat;
  late HapusTransaksi hapusTransaksi;
  late AmbilDetailTransaksi ambilDetailTransaksi;

  const tTransaksi = TransaksiEntity(
    id: 1,
    jumlah: 15000,
    kategoriId: 1,
    tanggal: '2026-09-28',
    dibuatPada: '2026-09-28T10:00:00.000',
  );

  setUp(() {
    repo = _FakeTransaksiRepository();
    ambilRiwayat = AmbilRiwayat(repo);
    hapusTransaksi = HapusTransaksi(repo);
    ambilDetailTransaksi = AmbilDetailTransaksi(repo);
  });

  group('AmbilRiwayat', () {
    test('mengirim parameter filter ke repository dan mengembalikan daftar transaksi', () async {
      repo.daftarKembalian = [tTransaksi];

      final hasil = await ambilRiwayat(
        tanggalMulai: '2026-09-01',
        tanggalAkhir: '2026-09-28',
        kategoriId: 2,
      );

      expect(repo.tanggalMulaiTerpanggil, '2026-09-01');
      expect(repo.tanggalAkhirTerpanggil, '2026-09-28');
      expect(repo.kategoriIdTerpanggil, 2);
      expect(hasil, [tTransaksi]);
    });

    test('bisa dipanggil tanpa filter (seluruh parameter null)', () async {
      repo.daftarKembalian = [tTransaksi];

      final hasil = await ambilRiwayat();

      expect(repo.tanggalMulaiTerpanggil, isNull);
      expect(repo.tanggalAkhirTerpanggil, isNull);
      expect(repo.kategoriIdTerpanggil, isNull);
      expect(hasil, [tTransaksi]);
    });
  });

  group('HapusTransaksi', () {
    test('meneruskan id ke repository.hapus dan mengembalikan jumlah baris terhapus', () async {
      repo.jumlahTerhapusKembalian = 1;

      final hasil = await hapusTransaksi(42);

      expect(repo.idTerhapus, 42);
      expect(hasil, 1);
    });
  });

  group('AmbilDetailTransaksi', () {
    test('meneruskan id ke repository.ambilSatu dan mengembalikan transaksi yang cocok', () async {
      repo.detailKembalian = tTransaksi;

      final hasil = await ambilDetailTransaksi(1);

      expect(repo.idDiambil, 1);
      expect(hasil, tTransaksi);
    });

    test('mengembalikan null jika transaksi tidak ditemukan', () async {
      repo.detailKembalian = null;

      final hasil = await ambilDetailTransaksi(999);

      expect(repo.idDiambil, 999);
      expect(hasil, isNull);
    });
  });
}
