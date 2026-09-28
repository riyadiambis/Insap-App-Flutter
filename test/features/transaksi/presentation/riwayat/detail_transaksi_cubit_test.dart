import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_detail_transaksi.dart';
import 'package:insap/features/transaksi/domain/usecases/hapus_transaksi.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/detail_transaksi_cubit.dart';
import 'package:insap/features/transaksi/presentation/riwayat/cubit/detail_transaksi_state.dart';

class _FakeTransaksiRepository implements TransaksiRepository {
  TransaksiEntity? detail;
  int idTerhapus = 0;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => detail;

  @override
  Future<int> hapus(int id) async {
    idTerhapus = id;
    return 1;
  }

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
  late AmbilDetailTransaksi ambilDetail;
  late HapusTransaksi hapusTransaksi;
  late DetailTransaksiCubit cubit;

  const tTransaksi = TransaksiEntity(
    id: 10,
    jumlah: 50000,
    kategoriId: 1,
    tanggal: '2026-09-28',
    catatan: 'Buku catatan',
    dibuatPada: '2026-09-28T14:00:00.000',
  );

  setUp(() {
    repo = _FakeTransaksiRepository();
    ambilDetail = AmbilDetailTransaksi(repo);
    hapusTransaksi = HapusTransaksi(repo);
    cubit = DetailTransaksiCubit(
      ambilDetailTransaksi: ambilDetail,
      hapusTransaksi: hapusTransaksi,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('state awal adalah DetailTransaksiInitial', () {
    expect(cubit.state, const DetailTransaksiInitial());
  });

  test('muat berhasil mengubah state menjadi DetailTransaksiLoaded', () async {
    repo.detail = tTransaksi;

    await cubit.muat(10);

    expect(cubit.state, const DetailTransaksiLoaded(tTransaksi));
  });

  test('muat yang tidak ditemukan mengubah state menjadi DetailTransaksiError', () async {
    repo.detail = null;

    await cubit.muat(999);

    expect(
      cubit.state,
      const DetailTransaksiError('Transaksi ini sudah tidak ada'),
    );
  });

  test('hapus ketika data loaded berhasil menghapus transaksi', () async {
    repo.detail = tTransaksi;
    await cubit.muat(10);

    final hasil = await cubit.hapus();

    expect(hasil, isTrue);
    expect(repo.idTerhapus, 10);
  });
}
