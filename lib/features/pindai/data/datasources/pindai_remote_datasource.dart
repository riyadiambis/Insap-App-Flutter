import 'dart:convert';
import 'dart:io';

import '../../../../core/network/gemini_client.dart';
import '../models/hasil_pindai_model.dart';

abstract class PindaiRemoteDataSource {
  Future<HasilPindaiModel> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
  });
}

class PindaiRemoteDataSourceImpl implements PindaiRemoteDataSource {
  final GeminiClient geminiClient;

  PindaiRemoteDataSourceImpl({required this.geminiClient});

  static const String _promptSistem = '''
Kamu adalah pengekstrak data struk belanja Indonesia. Kamu menerima satu
citra dan membalas HANYA dengan objek JSON yang valid, tanpa penjelasan,
tanpa tanda kutip pembungkus, dan tanpa pagar kode markdown.

Aturan:
1. Kalau citra bukan struk belanja, isi "adalah_struk" dengan false dan
   biarkan seluruh kolom lain bernilai null.
2. "total" adalah jumlah akhir yang benar-benar dibayar, sudah termasuk
   pajak dan diskon. Tulis sebagai bilangan bulat Rupiah tanpa titik,
   koma, atau awalan "Rp".
3. "tanggal" memakai format YYYY-MM-DD. Kalau tahun tidak tercetak,
   pakai tahun berjalan. Kalau tanggal tidak terbaca sama sekali, isi null.
4. "kategori_usulan" hanya boleh dipilih dari daftar yang diberikan
   pengguna. Kalau tidak ada yang cocok, pilih "lainnya".
5. "keyakinan" adalah bilangan 0 sampai 1 yang menyatakan seberapa yakin
   kamu pada hasil bacaanmu secara keseluruhan.
6. Jangan menebak. Kolom yang tidak terbaca diisi null, bukan dikarang.
''';

  @override
  Future<HasilPindaiModel> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const GeminiException('Berkas gambar struk tidak ditemukan');
    }

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    String mimeType = 'image/jpeg';
    final lowerPath = imagePath.toLowerCase();
    if (lowerPath.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (lowerPath.endsWith('.webp')) {
      mimeType = 'image/webp';
    }

    final kategoriTersedia = daftarKategori.isNotEmpty
        ? daftarKategori.join(', ')
        : 'makan, transport, jajan daring, top up, kos, lainnya';

    final promptPengguna = '''
Ekstrak struk pada citra ini.
Kategori yang tersedia: $kategoriTersedia
''';

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': _promptSistem.trim()}
        ]
      },
      'contents': [
        {
          'parts': [
            {'text': promptPengguna.trim()},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      }
    };

    final response = await geminiClient.generateContent(
      requestBody: requestBody,
    );

    final data = response.data;
    if (data == null) {
      throw const GeminiException('Gagal membaca struk, coba lagi');
    }

    try {
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const GeminiException('Gagal membaca struk, coba lagi');
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw const GeminiException('Gagal membaca struk, coba lagi');
      }

      final text = parts.first['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw const GeminiException('Gagal membaca struk, coba lagi');
      }

      var cleanedText = text.trim();
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      } else if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();

      final jsonMap = jsonDecode(cleanedText) as Map<String, dynamic>;
      return HasilPindaiModel.fromJson(jsonMap);
    } catch (e) {
      if (e is GeminiException) rethrow;
      throw const GeminiException('Gagal membaca struk, coba lagi');
    }
  }
}
