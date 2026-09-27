class Transaksi {
  final int? id;
  final int jumlah;
  final int kategoriId;
  final String tanggal;
  final String? catatan;
  final String? tipeKebutuhan;
  final String sumber;
  final String? namaToko;
  final String dibuatPada;

  Transaksi({
    this.id,
    required this.jumlah,
    required this.kategoriId,
    required this.tanggal,
    this.catatan,
    this.tipeKebutuhan,
    this.sumber = 'manual',
    this.namaToko,
    required this.dibuatPada,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jumlah': jumlah,
      'kategori_id': kategoriId,
      'tanggal': tanggal,
      'catatan': catatan,
      'tipe_kebutuhan': tipeKebutuhan,
      'sumber': sumber,
      'nama_toko': namaToko,
      'dibuat_pada': dibuatPada,
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'] as int?,
      jumlah: map['jumlah'] as int,
      kategoriId: map['kategori_id'] as int,
      tanggal: map['tanggal'] as String,
      catatan: map['catatan'] as String?,
      tipeKebutuhan: map['tipe_kebutuhan'] as String?,
      sumber: map['sumber'] as String,
      namaToko: map['nama_toko'] as String?,
      dibuatPada: map['dibuat_pada'] as String,
    );
  }
}
