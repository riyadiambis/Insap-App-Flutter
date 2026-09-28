import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_riwayat.dart';
import 'package:insap/features/transaksi/domain/usecases/hapus_transaksi.dart';
import 'package:insap/features/transaksi/domain/usecases/tambah_transaksi.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/riwayat_state.dart';

// Repository palsu buatan sendiri, tanpa dependensi mock eksternal
class _FakeTransaksiRepository implements TransaksiRepository {
  List<TransaksiEntity> daftar = [];
  int idTerhapus = 0;
  TransaksiEntity? transaksiTersimpan;
  String? tanggalMulaiTerpanggil;
  String? tanggalAkhirTerpanggil;
  int? kategoriIdTerpanggil;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    tanggalMulaiTerpanggil = tanggalMulai;
    tanggalAkhirTerpanggil = tanggalAkhir;
    kategoriIdTerpanggil = kategoriId;
    return daftar;
  }

  @override
  Future<int> hapus(int id) async {
    idTerhapus = id;
    return 1;
  }

  @override
  Future<int> simpan(TransaksiEntity transaksi) async {
    transaksiTersimpan = transaksi;
    return 1;
  }

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

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
  late TambahTransaksi tambahTransaksi;
  late RiwayatCubit cubit;

  const tTransaksi = TransaksiEntity(
    id: 1,
    jumlah: 25000,
    kategoriId: 2,
    tanggal: '2026-09-28',
    dibuatPada: '2026-09-28T12:00:00.000',
  );

  setUp(() {
    repo = _FakeTransaksiRepository();
    ambilRiwayat = AmbilRiwayat(repo);
    hapusTransaksi = HapusTransaksi(repo);
    tambahTransaksi = TambahTransaksi(repo);
    cubit = RiwayatCubit(
      ambilRiwayat: ambilRiwayat,
      hapusTransaksi: hapusTransaksi,
      tambahTransaksi: tambahTransaksi,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('state awal memiliki status initial dan daftar kosong', () {
    expect(cubit.state.status, RiwayatStatus.initial);
    expect(cubit.state.daftarTransaksi, isEmpty);
    expect(cubit.state.isFilterAktif, isFalse);
  });

  test('muatRiwayat memuat daftar transaksi dan mengubah status ke loaded', () async {
    repo.daftar = [tTransaksi];

    await cubit.muatRiwayat();

    expect(cubit.state.status, RiwayatStatus.loaded);
    expect(cubit.state.daftarTransaksi, [tTransaksi]);
  });

  test('terapkanFilter menyimpan filter pada state dan mengambil data yang sesuai', () async {
    repo.daftar = [tTransaksi];

    await cubit.terapkanFilter(
      tanggalMulai: '2026-09-01',
      tanggalAkhir: '2026-09-28',
      kategoriId: 2,
    );

    expect(cubit.state.filterTanggalMulai, '2026-09-01');
    expect(cubit.state.filterTanggalAkhir, '2026-09-28');
    expect(cubit.state.filterKategoriId, 2);
    expect(cubit.state.isFilterAktif, isTrue);
    expect(repo.kategoriIdTerpanggil, 2);
  });

  test('resetFilter membersihkan filter dan memuat ulang', () async {
    await cubit.terapkanFilter(kategoriId: 2);
    expect(cubit.state.isFilterAktif, isTrue);

    await cubit.resetFilter();

    expect(cubit.state.filterTanggalMulai, isNull);
    expect(cubit.state.filterKategoriId, isNull);
    expect(cubit.state.isFilterAktif, isFalse);
  });

  test('hapus memanggil hapusTransaksi dan memuat ulang', () async {
    await cubit.hapus(tTransaksi);

    expect(repo.idTerhapus, 1);
  });

  test('batalHapus memanggil tambahTransaksi untuk menyimpan kembali data', () async {
    await cubit.batalHapus(tTransaksi);

    expect(repo.transaksiTersimpan, tTransaksi);
  });
}
