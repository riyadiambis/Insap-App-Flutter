import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/gemini_client.dart';
import '../models/hasil_pindai_model.dart';

abstract class PindaiRemoteDataSource {
  Future<HasilPindaiModel> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
    Map<String, int>? petaKategoriId,
    CancelToken? cancelToken,
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
4. "kategori_usulan" = kategori dengan nilai terbesar. Hanya boleh dipilih
   dari daftar yang diberikan pengguna. Kalau tidak ada yang cocok, pilih "lainnya".
5. Aturan kolom "barang":
   (i) Catat tiap barang yang tercetak, nama seperti tercetak, harga = total baris itu
       (jumlah x harga satuan) setelah potongan baris itu;
   (ii) Baris pajak, biaya layanan, pembulatan, dan total tidak dicatat sebagai barang;
   (iii) Kategori tiap barang wajib dari daftar, pilih yang paling sesuai dengan contoh
       isinya, "lainnya" hanya bila tidak ada yang mendekati;
   (iv) Kalau rincian tidak terbaca, "barang" diisi [] tapi total tetap diisi;
   (v) "kategori_usulan" = kategori dengan nilai terbesar.
6. "keyakinan" adalah bilangan 0 sampai 1 yang menyatakan seberapa yakin
   kamu pada hasil bacaanmu secara keseluruhan.
7. Jangan menebak. Kolom yang tidak terbaca diisi null, bukan dikarang.
''';

  static const Map<String, String> _contohKategori = {
    'makan': 'warteg, katering, sarapan',
    'transport': 'bensin, ojek daring, angkot',
    'kos': 'sewa, listrik, wifi, patungan',
    'kuliah': 'fotokopi, praktikum, buku',
    'jajan daring': 'belanja daring, kopi kekinian',
    'nongkrong': 'kafe, bioskop, main bareng',
    'top up': 'permainan, langganan hiburan',
    'darurat': 'obat, servis motor, kondangan',
    'lainnya': 'penampung, wajib ada',
  };

  @override
  Future<HasilPindaiModel> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
    Map<String, int>? petaKategoriId,
    CancelToken? cancelToken,
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

    // Bangun daftar kategori beserta contoh isi sesuai KATEGORI.md
    final listKategoriClean = daftarKategori
        .map((k) => k.toLowerCase().trim())
        .where((k) => k.isNotEmpty)
        .toSet()
        .toList();

    if (!listKategoriClean.contains('lainnya')) {
      listKategoriClean.add('lainnya');
    }

    final barisKategori = listKategoriClean.map((k) {
      final contoh = _contohKategori[k];
      if (contoh != null) {
        return '- $k ($contoh)';
      }
      return '- $k';
    }).join('\n');

    final promptPengguna = '''
Ekstrak struk pada citra ini.
Kategori yang tersedia:
$barisKategori
'''.trim();

    // ResponseSchema terstruktur sesuai GEMINI-CONTRACT.md bagian 3
    final responseSchema = {
      'type': 'OBJECT',
      'properties': {
        'adalah_struk': {'type': 'BOOLEAN'},
        'nama_toko': {'type': 'STRING', 'nullable': true},
        'tanggal': {'type': 'STRING', 'nullable': true},
        'total': {'type': 'INTEGER', 'nullable': true},
        'kategori_usulan': {
          'type': 'STRING',
          'enum': listKategoriClean,
          'nullable': true,
        },
        'keyakinan': {'type': 'NUMBER'},
        'barang': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'nama': {'type': 'STRING'},
              'harga': {'type': 'INTEGER'},
              'kategori': {
                'type': 'STRING',
                'enum': listKategoriClean,
              },
            },
            'required': ['nama', 'harga', 'kategori'],
          },
        },
      },
      'required': ['adalah_struk', 'keyakinan', 'barang'],
    };

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': _promptSistem.trim()}
        ]
      },
      'contents': [
        {
          'parts': [
            {'text': promptPengguna},
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
        'responseSchema': responseSchema,
        'temperature': 0,
      }
    };

    final response = await geminiClient.generateContent(
      requestBody: requestBody,
      cancelToken: cancelToken,
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
      return HasilPindaiModel.fromJson(
        jsonMap,
        daftarKategori: listKategoriClean,
        petaKategoriId: petaKategoriId,
      );
    } catch (e) {
      if (e is GeminiException) rethrow;
      throw const GeminiException('Gagal membaca struk, coba lagi');
    }
  }
}
