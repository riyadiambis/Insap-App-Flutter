class Kategori {
  final int? id;
  final String nama;
  final String ikon;
  final String warna;
  final String kelompokKakeibo;
  final int bawaan;
  final int urutan;

  Kategori({
    this.id,
    required this.nama,
    required this.ikon,
    required this.warna,
    required this.kelompokKakeibo,
    this.bawaan = 0,
    this.urutan = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'ikon': ikon,
      'warna': warna,
      'kelompok_kakeibo': kelompokKakeibo,
      'bawaan': bawaan,
      'urutan': urutan,
    };
  }

  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      ikon: map['ikon'] as String,
      warna: map['warna'] as String,
      kelompokKakeibo: map['kelompok_kakeibo'] as String,
      bawaan: map['bawaan'] as int,
      urutan: map['urutan'] as int,
    );
  }
}
