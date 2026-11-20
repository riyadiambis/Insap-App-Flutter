import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/gemini_client.dart';
import '../../domain/entities/refleksi_ai_entity.dart';
import '../models/hasil_refleksi_ai_model.dart';

abstract class RefleksiAiRemoteDataSource {
  Future<List<SaranRefleksiAi>> mintaSaran(
    RingkasanRefleksiAiInput input, {
    CancelToken? cancelToken,
  });
}

class RefleksiAiRemoteDataSourceImpl implements RefleksiAiRemoteDataSource {
  static const int batasWaktuDetik = 30;

  static const String promptSistem = '''
Kamu adalah Struki, teman pencatat keuangan mahasiswa Indonesia yang ramah dan santai.
Kamu menerima ringkasan agregat pengeluaran sepekan dan membalas HANYA dengan objek JSON valid sesuai skema, tanpa penjelasan dan tanpa pagar kode markdown.

Aturan:
1. Isi "saran" dengan TEPAT 3 item.
2. Kolom "kategori" wajib dipilih persis dari daftar kategori yang diberikan, atau "umum" untuk saran penghematan umum.
3. Kolom "teks" maksimal 160 karakter, 1-2 kalimat bahasa Indonesia santai, konkret, sebutkan angka Rupiah bila relevan, dan tidak menghakimi.
4. Jangan mengarang nama barang, nama toko, atau detail yang tidak ada di data.
''';

  final GeminiClient geminiClient;

  RefleksiAiRemoteDataSourceImpl({required this.geminiClient});

  Map<String, dynamic> _bangunRequestBody(
    RingkasanRefleksiAiInput input, {
    required bool sertakanThinkingConfig,
  }) {
    final daftarNama = input.daftarKategori.map((k) => k.nama).toList();
    final promptPengguna = '''
Buat tepat 3 saran refleksi mingguan berdasarkan ringkasan agregat berikut:
${jsonEncode(input.toPayloadMap())}
Daftar kategori tersedia: ${daftarNama.isEmpty ? 'umum' : daftarNama.join(', ')}, umum.
'''.trim();

    final responseSchema = {
      'type': 'OBJECT',
      'properties': {
        'saran': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'kategori': {'type': 'STRING'},
              'teks': {'type': 'STRING'},
            },
            'required': ['kategori', 'teks'],
          },
        },
      },
      'required': ['saran'],
    };

    final generationConfig = <String, dynamic>{
      'responseMimeType': 'application/json',
      'responseSchema': responseSchema,
      'temperature': 0.3,
    };

    if (sertakanThinkingConfig) {
      generationConfig['thinkingConfig'] = {'thinkingBudget': 0};
    }

    return {
      'system_instruction': {
        'parts': [
          {'text': promptSistem.trim()},
        ],
      },
      'contents': [
        {
          'parts': [
            {'text': promptPengguna},
          ],
        },
      ],
      'generationConfig': generationConfig,
    };
  }

  Future<Response<Map<String, dynamic>>> _kirimDenganBatasWaktu(
    Map<String, dynamic> body,
    CancelToken token,
  ) async {
    try {
      return await geminiClient
          .generateContent(requestBody: body, cancelToken: token)
          .timeout(const Duration(seconds: batasWaktuDetik));
    } on TimeoutException {
      if (!token.isCancelled) {
        token.cancel('Batas waktu refleksi AI 30 detik terlewati');
      }
      throw const GeminiException(
        'Waktu tunggu refleksi AI habis (melebihi $batasWaktuDetik detik)',
        408,
      );
    }
  }

  @override
  Future<List<SaranRefleksiAi>> mintaSaran(
    RingkasanRefleksiAiInput input, {
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    Response<Map<String, dynamic>> response;

    try {
      response = await _kirimDenganBatasWaktu(
        _bangunRequestBody(input, sertakanThinkingConfig: true),
        token,
      );
    } on GeminiException catch (e) {
      // Bila kunci kosong (status 400 dari GeminiClient sebelum memanggil jaringan), langsung lempar.
      if (e.statusCode == 400 &&
          e.pesan != 'Pindai struk belum aktif di versi ini') {
        final retryToken = cancelToken ?? CancelToken();
        response = await _kirimDenganBatasWaktu(
          _bangunRequestBody(input, sertakanThinkingConfig: false),
          retryToken,
        );
      } else {
        rethrow;
      }
    }

    final data = response.data;
    if (data == null) {
      throw const GeminiException('Respons refleksi AI kosong');
    }

    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const GeminiException('Respons refleksi AI tidak tersedia');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw const GeminiException('Respons refleksi AI tidak memiliki teks');
    }

    final text = parts.first['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw const GeminiException('Respons refleksi AI kosong');
    }

    final model = HasilRefleksiAiModel.fromRawText(
      text,
      daftarKategori: input.daftarKategori.map((k) => k.nama).toList(),
    );
    return model.saran;
  }
}
