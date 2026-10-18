import '../../../../core/network/gemini_client.dart';
import '../../domain/entities/hasil_pindai_entity.dart';

/// Model data untuk memetakan balasan JSON dari Gemini API ke entitas domain (GEMINI-CONTRACT.md).
class HasilPindaiModel extends HasilPindaiEntity {
  const HasilPindaiModel({
    required super.adalahStruk,
    super.namaToko,
    super.tanggal,
    super.total,
    super.kategoriUsulan,
    required super.keyakinan,
  });

  /// Factory untuk memetakan Map JSON dari Gemini API secara aman
  factory HasilPindaiModel.fromJson(Map<String, dynamic> json) {
    // 1. Parsing adalah_struk (wajib boolean, No 15)
    final rawStruk = json['adalah_struk'];
    if (rawStruk is! bool) {
      throw const GeminiException('Gagal membaca struk, coba lagi');
    }
    final bool adalahStruk = rawStruk;

    // 2. Parsing nama_toko
    String? namaToko;
    final rawToko = json['nama_toko'];
    if (rawToko is String && rawToko.trim().isNotEmpty) {
      namaToko = rawToko.trim();
    }

    // 3. Parsing tanggal (format YYYY-MM-DD)
    String? tanggal;
    final rawTanggal = json['tanggal'];
    if (rawTanggal is String && rawTanggal.trim().isNotEmpty) {
      tanggal = rawTanggal.trim();
    }

    // 4. Parsing total nominal (bilangan bulat rupiah tanpa titik/Rp)
    int? total;
    final rawTotal = json['total'];
    if (rawTotal is int) {
      total = rawTotal;
    } else if (rawTotal is num) {
      total = rawTotal.toInt();
    } else if (rawTotal is String) {
      final angkaSaja = rawTotal.replaceAll(RegExp(r'[^\d]'), '');
      total = int.tryParse(angkaSaja);
    }

    // 5. Parsing kategori_usulan
    String? kategoriUsulan;
    final rawKategori = json['kategori_usulan'];
    if (rawKategori is String && rawKategori.trim().isNotEmpty) {
      kategoriUsulan = rawKategori.trim().toLowerCase();
    }

    // 6. Parsing keyakinan (angka 0.0 sampai 1.0)
    double keyakinan = 0.0;
    final rawKeyakinan = json['keyakinan'];
    if (rawKeyakinan is num) {
      keyakinan = rawKeyakinan.toDouble();
    } else if (rawKeyakinan is String) {
      keyakinan = double.tryParse(rawKeyakinan.trim()) ?? 0.0;
    }

    return HasilPindaiModel(
      adalahStruk: adalahStruk,
      namaToko: namaToko,
      tanggal: tanggal,
      total: total,
      kategoriUsulan: kategoriUsulan,
      keyakinan: keyakinan.clamp(0.0, 1.0),
    );
  }

  /// Mengonversi model ke Map JSON
  Map<String, dynamic> toJson() {
    return {
      'adalah_struk': adalahStruk,
      'nama_toko': namaToko,
      'tanggal': tanggal,
      'total': total,
      'kategori_usulan': kategoriUsulan,
      'keyakinan': keyakinan,
    };
  }
}
