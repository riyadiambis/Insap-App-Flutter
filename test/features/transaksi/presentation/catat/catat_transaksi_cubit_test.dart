import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/utils/iso_week.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/tambah_transaksi.dart';
import 'package:insap/features/transaksi/presentation/catat/cubit/catat_transaksi_cubit.dart';
import 'package:insap/features/transaksi/presentation/catat/cubit/catat_transaksi_state.dart';

class _FakeTransaksiRepository implements TransaksiRepository {
  TransaksiEntity? transaksiTersimpan;

  @override
  Future<int> simpan(TransaksiEntity transaksi) async {
    transaksiTersimpan = transaksi;
    return 1;
  }

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

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
  late _FakeTransaksiRepository repo;
  late TambahTransaksi tambahTransaksi;
  late CatatTransaksiCubit cubit;

  setUp(() {
    repo = _FakeTransaksiRepository();
    tambahTransaksi = TambahTransaksi(repo);
    cubit = CatatTransaksiCubit(tambahTransaksi: tambahTransaksi);
  });

  tearDown(() {
    cubit.close();
  });

  group('CatatTransaksiCubit', () {
    test('state awal memiliki status awal dan tanggal hari ini', () {
      expect(cubit.state.status, StatusCatatTransaksi.awal);
      expect(cubit.state.nominal, 0);
      expect(cubit.state.kategoriId, isNull);
      expect(cubit.state.tanggal, formatTanggalIso(DateTime.now()));
    });

    test('setelah reset(), status kembali awal', () async {
      // Simulasikan pengisian form dan simpan berhasil
      cubit.ubahNominal(50000);
      cubit.pilihKategori(2);
      cubit.pilihTipeKebutuhan('butuh');
      cubit.ubahCatatan('Makan siang');

      await cubit.simpan();
      expect(cubit.state.status, StatusCatatTransaksi.berhasil);
      expect(cubit.state.nominal, 50000);
      expect(cubit.state.kategoriId, 2);

      // Panggil reset()
      cubit.reset();

      // Verifikasi status kembali awal
      expect(cubit.state.status, StatusCatatTransaksi.awal);
      expect(cubit.state.nominal, 0);
      expect(cubit.state.catatan, isNull);
      expect(cubit.state.tipeKebutuhan, isNull);
      expect(cubit.state.pesanKesalahan, isNull);
      expect(cubit.state.tanggal, formatTanggalIso(DateTime.now()));
      // Kategori awal tetap mengikuti aturan "kategori terakhir dipakai" (FITUR-01)
      expect(cubit.state.kategoriId, 2);
    });

    test('simpan kedua kali setelah reset berjalan normal', () async {
      // Simpan pertama
      cubit.ubahNominal(35000);
      cubit.pilihKategori(1);
      await cubit.simpan();
      expect(cubit.state.status, StatusCatatTransaksi.berhasil);

      // Reset setelah simpan pertama
      cubit.reset();
      expect(cubit.state.status, StatusCatatTransaksi.awal);
      expect(cubit.state.kategoriId, 1);

      // Simpan kedua dengan nominal baru dan kategori yang sama (terakhir dipakai)
      cubit.ubahNominal(20000);
      await cubit.simpan();
      expect(cubit.state.status, StatusCatatTransaksi.berhasil);
      expect(repo.transaksiTersimpan?.jumlah, 20000);
      expect(repo.transaksiTersimpan?.kategoriId, 1);
    });
  });
}
