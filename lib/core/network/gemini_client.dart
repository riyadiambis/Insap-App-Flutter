import 'package:dio/dio.dart';

/// Pengecualian khusus ketika terjadi kegagalan jaringan atau komunikasi dengan Gemini API
class GeminiException implements Exception {
  final String pesan;
  final int? statusCode;

  const GeminiException(this.pesan, [this.statusCode]);

  @override
  String toString() => 'GeminiException: $pesan (status: $statusCode)';
}

/// Klien jaringan untuk berkomunikasi dengan REST API Google Gemini.
/// Dikonfigurasi dengan Dio, batas waktu 15 detik, dan pembacaan kunci dari environment.
class GeminiClient {
  static const int batasWaktuDetik = 15;
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Nama model Flash stabil default, dapat diubah via --dart-define=GEMINI_MODEL=...
  static const String namaModelDefault = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  /// Kunci API Gemini dari environment (--dart-define=GEMINI_API_KEY=...)
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final Dio dio;
  final String model;

  GeminiClient({
    Dio? dio,
    String? model,
  })  : model = model ?? namaModelDefault,
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: batasWaktuDetik),
                receiveTimeout: const Duration(seconds: batasWaktuDetik),
                sendTimeout: const Duration(seconds: batasWaktuDetik),
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            );

  /// Mengirim permintaan generateContent ke endpoint REST API Gemini
  Future<Response<Map<String, dynamic>>> generateContent({
    required Map<String, dynamic> requestBody,
    String? customApiKey,
  }) async {
    final key = customApiKey ?? apiKey;
    final path = '/models/$model:generateContent';

    try {
      final response = await dio.post<Map<String, dynamic>>(
        path,
        data: requestBody,
        queryParameters: {
          if (key.isNotEmpty) 'key': key,
        },
      );
      return response;
    } on DioException catch (e) {
      throw _tanganiDioError(e);
    } catch (e) {
      throw GeminiException('Terjadi galat tak terduga: $e');
    }
  }

  GeminiException _tanganiDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const GeminiException(
        'Waktu tunggu pemindaian habis (melebihi 15 detik)',
        408,
      );
    } else if (e.type == DioExceptionType.connectionError) {
      return const GeminiException(
        'Tidak ada koneksi internet',
        503,
      );
    } else if (e.response != null) {
      final code = e.response?.statusCode;
      final msg = e.response?.data?['error']?['message'] ??
          e.message ??
          'Galat dari server Gemini';
      return GeminiException(msg.toString(), code);
    } else {
      return GeminiException(
        e.message ?? 'Galat jaringan saat menghubungi Gemini',
      );
    }
  }
}
