import 'package:equatable/equatable.dart';

import '../../domain/entities/barang_pindai.dart';

enum KonfirmasiPindaiStatus { siap, menyimpan, sukses, gagal }

/// Representasi satu kelompok kategori barang beserta subtotalnya
class KelompokBarangPindai {
  final int kategoriId;
  final List<BarangPindai> items;
  final int subtotal;
  final bool adaGalat;

  const KelompokBarangPindai({
    required this.kategoriId,
    required this.items,
    required this.subtotal,
    required this.adaGalat,
  });
}

class KonfirmasiPindaiState extends Equatable {
  final List<BarangPindai> daftarBarang;
  final String namaToko;
  final String tanggal;
  final int totalStruk;
  final double keyakinan;
  final bool tampilkanSemua;
  final Map<int, String> tipeKebutuhan;
  final KonfirmasiPindaiStatus status;
  final String? pesanGalat;
  final int jumlahTransaksiTersimpan;
  final bool totalDihitungDariBarang;

  const KonfirmasiPindaiState({
    required this.daftarBarang,
    required this.namaToko,
    required this.tanggal,
    required this.totalStruk,
    required this.keyakinan,
    this.tampilkanSemua = false,
    this.tipeKebutuhan = const {},
    this.status = KonfirmasiPindaiStatus.siap,
    this.pesanGalat,
    this.jumlahTransaksiTersimpan = 0,
    this.totalDihitungDariBarang = false,
  });

  /// Total nominal seluruh barang yang sedang tercentang (dihitung via Dart fold)
  int get totalDipilih => daftarBarang
      .where((b) => b.dicentang)
      .fold<int>(0, (sum, b) => sum + b.harga);

  /// Jumlah barang yang sedang dicentang
  int get jumlahBarangDicentang =>
      daftarBarang.where((b) => b.dicentang).length;

  /// Daftar barang dikelompokkan per kategoriId, diurutkan berdasarkan subtotal terbesar
  List<KelompokBarangPindai> get kelompokList {
    final Map<int, List<BarangPindai>> map = {};
    for (final b in daftarBarang) {
      map.putIfAbsent(b.kategoriId, () => []).add(b);
    }

    final List<KelompokBarangPindai> kelompok = [];
    for (final entry in map.entries) {
      final subtotal = entry.value
          .where((b) => b.dicentang)
          .fold<int>(0, (sum, b) => sum + b.harga);
      final adaChecked = entry.value.any((b) => b.dicentang);
      final adaGalat = adaChecked && subtotal <= 0;
      kelompok.add(
        KelompokBarangPindai(
          kategoriId: entry.key,
          items: entry.value,
          subtotal: subtotal,
          adaGalat: adaGalat,
        ),
      );
    }

    // Urutkan kelompok berdasarkan subtotal terbesar
    kelompok.sort((a, b) => b.subtotal.compareTo(a.subtotal));
    return kelompok;
  }

  /// Menandakan apakah ada kelompok tercentang yang memiliki subtotal <= 0
  bool get adaKelompokGalat => kelompokList.any((k) => k.adaGalat);

  /// Jumlah transaksi aktif yang akan disimpan (satu per kelompok dengan subtotal > 0)
  int get jumlahTransaksiAktif => kelompokList
      .where((k) => k.items.any((b) => b.dicentang) && k.subtotal > 0)
      .length;

  /// Validasi tombol simpan aktif
  bool get bolehSimpan =>
      jumlahBarangDicentang > 0 &&
      !adaKelompokGalat &&
      status != KonfirmasiPindaiStatus.menyimpan;

  KonfirmasiPindaiState copyWith({
    List<BarangPindai>? daftarBarang,
    String? namaToko,
    String? tanggal,
    int? totalStruk,
    double? keyakinan,
    bool? tampilkanSemua,
    Map<int, String>? tipeKebutuhan,
    KonfirmasiPindaiStatus? status,
    String? pesanGalat,
    int? jumlahTransaksiTersimpan,
    bool? totalDihitungDariBarang,
  }) {
    return KonfirmasiPindaiState(
      daftarBarang: daftarBarang ?? this.daftarBarang,
      namaToko: namaToko ?? this.namaToko,
      tanggal: tanggal ?? this.tanggal,
      totalStruk: totalStruk ?? this.totalStruk,
      keyakinan: keyakinan ?? this.keyakinan,
      tampilkanSemua: tampilkanSemua ?? this.tampilkanSemua,
      tipeKebutuhan: tipeKebutuhan ?? this.tipeKebutuhan,
      status: status ?? this.status,
      pesanGalat: pesanGalat,
      jumlahTransaksiTersimpan:
          jumlahTransaksiTersimpan ?? this.jumlahTransaksiTersimpan,
      totalDihitungDariBarang:
          totalDihitungDariBarang ?? this.totalDihitungDariBarang,
    );
  }

  @override
  List<Object?> get props => [
        daftarBarang,
        namaToko,
        tanggal,
        totalStruk,
        keyakinan,
        tampilkanSemua,
        tipeKebutuhan,
        status,
        pesanGalat,
        jumlahTransaksiTersimpan,
        totalDihitungDariBarang,
      ];
}
