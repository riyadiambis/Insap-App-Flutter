import 'dart:convert';

import '../../../../core/network/gemini_client.dart';
import '../../domain/entities/refleksi_ai_entity.dart';

/// Model parser dan serialisasi untuk respons JSON refleksi AI dari Gemini.
class HasilRefleksiAiModel {
  static const int jumlahSaranWajib = 3;
  static const int maksPanjangTeks = 160;

  final List<SaranRefleksiAi> saran;

  const HasilRefleksiAiModel({required this.saran});

  factory HasilRefleksiAiModel.fromRawText(
    String rawText, {
    List<String> daftarKategori = const [],
  }) {
    var cleaned = rawText.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    if (cleaned.isEmpty) {
      throw const GeminiException('Respons refleksi AI kosong');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } catch (_) {
      throw const GeminiException('Format JSON refleksi AI tidak valid');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const GeminiException('Struktur JSON refleksi AI tidak valid');
    }

    return HasilRefleksiAiModel.fromJson(
      decoded,
      daftarKategori: daftarKategori,
    );
  }

  factory HasilRefleksiAiModel.fromJson(
    Map<String, dynamic> json, {
    List<String> daftarKategori = const [],
  }) {
    final rawSaran = json['saran'];
    if (rawSaran is! List || rawSaran.length != jumlahSaranWajib) {
      throw const GeminiException('Jumlah saran refleksi AI harus tepat 3');
    }

    final kategoriNormal = daftarKategori
        .map((k) => k.trim().toLowerCase())
        .where((k) => k.isNotEmpty)
        .toSet();

    final List<SaranRefleksiAi> hasil = [];
    for (final item in rawSaran) {
      if (item is! Map) {
        throw const GeminiException('Item saran refleksi AI tidak valid');
      }

      final rawTeks = item['teks'];
      if (rawTeks is! String || rawTeks.trim().isEmpty) {
        throw const GeminiException('Teks saran refleksi AI kosong');
      }

      String teks = rawTeks.trim();
      if (teks.length > maksPanjangTeks) {
        teks = teks.substring(0, maksPanjangTeks).trimRight();
      }

      final rawKategori = item['kategori'];
      String kategori = rawKategori is String
          ? rawKategori.trim().toLowerCase()
          : '';
      if (kategori.isEmpty ||
          (kategoriNormal.isNotEmpty && !kategoriNormal.contains(kategori))) {
        kategori = 'umum';
      }

      hasil.add(SaranRefleksiAi(kategori: kategori, teks: teks));
    }

    return HasilRefleksiAiModel(saran: hasil);
  }

  Map<String, dynamic> toJson() {
    return {
      'saran': saran
          .map((s) => {'kategori': s.kategori, 'teks': s.teks})
          .toList(),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}
