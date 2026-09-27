import '../../domain/entities/transaksi_entity.dart';
import '../../domain/repositories/transaksi_repository.dart';
import '../datasources/transaksi_local_datasource.dart';
import '../models/transaksi_model.dart';

class TransaksiRepositoryImpl implements TransaksiRepository {
  final TransaksiLocalDataSource _dataSource;

  TransaksiRepositoryImpl({TransaksiLocalDataSource? dataSource})
      : _dataSource = dataSource ?? TransaksiLocalDataSource();

  @override
  Future<int> simpan(TransaksiEntity transaksi) {
    return _dataSource.simpan(_toModel(transaksi));
  }

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) {
    return _dataSource.ambilTerakhir(batas);
  }

  @override
  Future<int> totalRentang(String tanggalMulai, String tanggalAkhir) {
    return _dataSource.totalRentang(tanggalMulai, tanggalAkhir);
  }

  @override
  Future<int> totalMingguIni(String tanggalMulai, String tanggalAkhir) {
    return totalRentang(tanggalMulai, tanggalAkhir);
  }

  @override
  Future<int> ambilKuotaPindai() {
    return _dataSource.ambilKuotaPindai();
  }

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) {
    return _dataSource.ambilDaftar(
      tanggalMulai: tanggalMulai,
      tanggalAkhir: tanggalAkhir,
      kategoriId: kategoriId,
    );
  }

  @override
  Future<TransaksiEntity?> ambilSatu(int id) {
    return _dataSource.ambilSatu(id);
  }

  @override
  Future<int> hapus(int id) {
    return _dataSource.hapus(id);
  }

  TransaksiModel _toModel(TransaksiEntity transaksi) {
    if (transaksi is TransaksiModel) return transaksi;
    return TransaksiModel(
      id: transaksi.id,
      jumlah: transaksi.jumlah,
      kategoriId: transaksi.kategoriId,
      tanggal: transaksi.tanggal,
      catatan: transaksi.catatan,
      tipeKebutuhan: transaksi.tipeKebutuhan,
      sumber: transaksi.sumber,
      namaToko: transaksi.namaToko,
      dibuatPada: transaksi.dibuatPada,
    );
  }
}
