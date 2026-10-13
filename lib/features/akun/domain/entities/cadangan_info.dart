class CadanganInfo {
  final DateTime? waktuCadanganTerakhir;
  final int jumlahTransaksi;
  final int jumlahKategori;
  final int jumlahRefleksi;

  const CadanganInfo({
    this.waktuCadanganTerakhir,
    this.jumlahTransaksi = 0,
    this.jumlahKategori = 0,
    this.jumlahRefleksi = 0,
  });
}
