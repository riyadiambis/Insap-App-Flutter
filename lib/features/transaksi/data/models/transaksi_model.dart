import '../../domain/entities/transaksi_entity.dart';

class TransaksiModel extends TransaksiEntity {
  const TransaksiModel({
    super.id,
    required super.jumlah,
    required super.kategoriId,
    required super.tanggal,
    super.catatan,
    super.tipeKebutuhan,
    super.sumber = 'manual',
    super.namaToko,
    required super.dibuatPada,
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

  factory TransaksiModel.fromMap(Map<String, dynamic> map) {
    return TransaksiModel(
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
