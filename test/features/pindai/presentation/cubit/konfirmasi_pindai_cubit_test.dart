import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/pindai/domain/entities/barang_pindai.dart';
import 'package:insap/features/pindai/domain/entities/hasil_pindai_entity.dart';
import 'package:insap/features/pindai/domain/usecases/simpan_transaksi_pindai.dart';
import 'package:insap/features/pindai/presentation/cubit/konfirmasi_pindai_cubit.dart';
import 'package:insap/features/pindai/presentation/cubit/konfirmasi_pindai_state.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';

class _FakeTransaksiRepository implements TransaksiRepository {
  List<TransaksiEntity> tersimpan = [];
  bool throwOnSimpanBanyak = false;

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async {
    if (throwOnSimpanBanyak) {
      throw Exception('Database lock error');
    }
    tersimpan.addAll(daftarTransaksi);
    return List.generate(daftarTransaksi.length, (i) => i + 1);
  }

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => [];

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async =>
      [];

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 1;
}

void main() {
  group('KonfirmasiPindaiCubit', () {
    late _FakeTransaksiRepository repo;
    late SimpanTransaksiPindai simpanUseCase;

    setUp(() {
      repo = _FakeTransaksiRepository();
      simpanUseCase = SimpanTransaksiPindai(repo);
    });

    final hasilAwal = HasilPindaiEntity(
      adalahStruk: true,
      namaToko: 'Indomaret Sempaja',
      tanggal: '2026-10-18',
      total: 50000,
      kategoriUsulan: 'makan',
      keyakinan: 0.95,
      barang: const [
        BarangPindai(nama: 'Susu', harga: 10000, kategoriId: 1),
        BarangPindai(nama: 'Roti', harga: 15000, kategoriId: 1),
        BarangPindai(nama: 'Bensin', harga: 20000, kategoriId: 2),
        BarangPindai(
          nama: 'Pajak/diskon/pembulatan',
          harga: 5000,
          kategoriId: 1,
          adalahSelisih: true,
        ),
      ],
    );

    test('inisialisasi state dengan benar', () {
      final cubit = KonfirmasiPindaiCubit(
        simpanTransaksiPindai: simpanUseCase,
        hasilPindai: hasilAwal,
      );

      expect(cubit.state.daftarBarang.length, 4);
      expect(cubit.state.namaToko, 'Indomaret Sempaja');
      expect(cubit.state.tanggal, '2026-10-18');
      expect(cubit.state.totalStruk, 50000);
      expect(cubit.state.totalDipilih, 50000);
      expect(cubit.state.bolehSimpan, isTrue);
    });

    test('centang dan hapus centang mengubah totalDipilih', () {
      final cubit = KonfirmasiPindaiCubit(
        simpanTransaksiPindai: simpanUseCase,
        hasilPindai: hasilAwal,
      );

      // Hapus centang Roti (harga 15.000)
      cubit.centang(1, false);

      expect(cubit.state.daftarBarang[1].dicentang, isFalse);
      expect(cubit.state.totalDipilih, 35000);
      expect(cubit.state.jumlahBarangDicentang, 3);
    });

    test('ubahHarga memperbarui subtotal dan totalDipilih', () {
      final cubit = KonfirmasiPindaiCubit(
        simpanTransaksiPindai: simpanUseCase,
        hasilPindai: hasilAwal,
      );

      // Ubah harga Susu dari 10.000 jadi 12.000
      cubit.ubahHarga(0, 12000);

      expect(cubit.state.daftarBarang[0].harga, 12000);
      expect(cubit.state.totalDipilih, 52000);
    });

    test('ubahKategori memindahkan barang ke kelompok baru', () {
      final cubit = KonfirmasiPindaiCubit(
        simpanTransaksiPindai: simpanUseCase,
        hasilPindai: hasilAwal,
      );

      // Pindahkan Susu dari kategori 1 (makan) ke kategori 2 (transport)
      cubit.ubahKategori(0, 2);

      expect(cubit.state.daftarBarang[0].kategoriId, 2);
      final kelompok2 =
          cubit.state.kelompokList.firstWhere((k) => k.kategoriId == 2);
      expect(kelompok2.items.length, 2); // Bensin + Susu
    });

    test('kelompok dengan subtotal <= 0 menahan simpan (bolehSimpan false)', () {
      final hasilMinus = HasilPindaiEntity(
        adalahStruk: true,
        total: 10000,
        keyakinan: 0.9,
        barang: const [
          BarangPindai(
            nama: 'Diskon Besar',
            harga: -15000,
            kategoriId: 1,
            adalahSelisih: true,
          ),
          BarangPindai(
            nama: 'Barang Kecil',
            harga: 5000,
            kategoriId: 1,
          ),
        ],
      );

      final cubit = KonfirmasiPindaiCubit(
        simpanTransaksiPindai: simpanUseCase,
        hasilPindai: hasilMinus,
      );

      expect(cubit.state.adaKelompokGalat, isTrue);
      expect(cubit.state.bolehSimpan, isFalse);
    });

    test('semua tidak dicentang menahan simpan (bolehSimpan false)', () {
      final cubit = KonfirmasiPindaiCubit(
        simpanTransaksiPindai: simpanUseCase,
        hasilPindai: hasilAwal,
      );

      for (int i = 0; i < 4; i++) {
        cubit.centang(i, false);
      }

      expect(cubit.state.jumlahBarangDicentang, 0);
      expect(cubit.state.bolehSimpan, isFalse);
    });

    test('simpanSemua memecah transaksi per kategori dan mengecualikan nama selisih dari catatan', () async {
      final cubit = KonfirmasiPindaiCubit(
        simpanTransaksiPindai: simpanUseCase,
        hasilPindai: hasilAwal,
      );

      // Set tipe kebutuhan untuk kategori 2
      cubit.ubahTipeKebutuhan(2, 'butuh');

      final sukses = await cubit.simpanSemua();

      expect(sukses, isTrue);
      expect(cubit.state.status, KonfirmasiPindaiStatus.sukses);
      expect(cubit.state.jumlahTransaksiTersimpan, 2); // 2 kelompok (makan & transport)
      expect(repo.tersimpan.length, 2);

      final trxMakan = repo.tersimpan.firstWhere((t) => t.kategoriId == 1);
      final trxTransport = repo.tersimpan.firstWhere((t) => t.kategoriId == 2);

      // Subtotal makan = 10.000 + 15.000 + 5.000 (selisih) = 30.000
      expect(trxMakan.jumlah, 30000);
      // Catatan makan hanya 'Susu, Roti' (selisih tidak masuk catatan)
      expect(trxMakan.catatan, 'Susu, Roti');
      expect(trxMakan.sumber, 'pindai');
      expect(trxMakan.namaToko, 'Indomaret Sempaja');

      // Subtotal transport = 20.000
      expect(trxTransport.jumlah, 20000);
      expect(trxTransport.catatan, 'Bensin');
      expect(trxTransport.tipeKebutuhan, 'butuh');
      expect(trxTransport.sumber, 'pindai');
    });

    test('simpanSemua memotong catatan jika melebihi 100 karakter', () async {
      final namaPanjang = 'A' * 60;
      final namaPanjang2 = 'B' * 60;

      final hasilNamaPanjang = HasilPindaiEntity(
        adalahStruk: true,
        total: 20000,
        keyakinan: 0.9,
        barang: [
          BarangPindai(nama: namaPanjang, harga: 10000, kategoriId: 1),
          BarangPindai(nama: namaPanjang2, harga: 10000, kategoriId: 1),
        ],
      );

      final cubit = KonfirmasiPindaiCubit(
        simpanTransaksiPindai: simpanUseCase,
        hasilPindai: hasilNamaPanjang,
      );

      final sukses = await cubit.simpanSemua();

      expect(sukses, isTrue);
      expect(repo.tersimpan.first.catatan!.length, lessThanOrEqualTo(100));
    });

    test('simpanSemua gagal saat repository melempar exception', () async {
      repo.throwOnSimpanBanyak = true;

      final cubit = KonfirmasiPindaiCubit(
        simpanTransaksiPindai: simpanUseCase,
        hasilPindai: hasilAwal,
      );

      final sukses = await cubit.simpanSemua();

      expect(sukses, isFalse);
      expect(cubit.state.status, KonfirmasiPindaiStatus.gagal);
      expect(cubit.state.pesanGalat, contains('Database lock error'));
    });
  });
}
