import '../../domain/entities/kategori_entity.dart';

class KategoriModel extends KategoriEntity {
  const KategoriModel({
    super.id,
    required super.nama,
    required super.ikon,
    required super.warna,
    required super.kelompokKakeibo,
    super.bawaan = 0,
    super.urutan = 0,
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

  factory KategoriModel.fromMap(Map<String, dynamic> map) {
    return KategoriModel(
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
