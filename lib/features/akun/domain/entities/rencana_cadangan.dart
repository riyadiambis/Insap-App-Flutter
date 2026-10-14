/// Selisih satu koleksi antara data lokal dan cadangan di awan.
class SelisihKoleksi {
  final int jumlahLokal;
  final int jumlahAwan;

  /// Dokumen awan yang ID-nya tidak ada di lokal.
  final int akanDihapus;

  /// Dokumen awan yang ID-nya ada di lokal tetapi isinya berbeda.
  final int akanDitimpa;

  const SelisihKoleksi({
    this.jumlahLokal = 0,
    this.jumlahAwan = 0,
    this.akanDihapus = 0,
    this.akanDitimpa = 0,
  });
}

/// Ringkasan dampak pencadangan terhadap isi awan, dihitung sebelum menulis.
class RencanaCadangan {
  final SelisihKoleksi transaksi;
  final SelisihKoleksi kategori;
  final SelisihKoleksi refleksi;

  const RencanaCadangan({
    this.transaksi = const SelisihKoleksi(),
    this.kategori = const SelisihKoleksi(),
    this.refleksi = const SelisihKoleksi(),
  });

  /// Kategori tidak dihitung karena selalu berisi kategori bawaan hasil seed.
  bool get perangkatKosong =>
      transaksi.jumlahLokal == 0 && refleksi.jumlahLokal == 0;

  bool get awanBerisi => transaksi.jumlahAwan > 0 || refleksi.jumlahAwan > 0;

  /// Mencadangkan dari perangkat kosong akan menghapus seluruh cadangan awan.
  bool get ditolak => perangkatKosong && awanBerisi;

  int get totalDihapus =>
      transaksi.akanDihapus + kategori.akanDihapus + refleksi.akanDihapus;

  int get totalDitimpa =>
      transaksi.akanDitimpa + kategori.akanDitimpa + refleksi.akanDitimpa;

  bool get perluKonfirmasi => totalDihapus > 0 || totalDitimpa > 0;
}

const String pesanPerangkatTidakKosong =
    'Data di perangkat ini masih ada. Pemulihan hanya untuk perangkat kosong, supaya data barumu tidak tertimpa.';

/// Galat khusus saat pemulihan ditolak karena tabel transaksi lokal masih berisi data.
class PerangkatTidakKosongException implements Exception {
  final String pesan;

  const PerangkatTidakKosongException([this.pesan = pesanPerangkatTidakKosong]);

  @override
  String toString() => pesan;
}
