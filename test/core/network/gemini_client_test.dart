import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/network/gemini_client.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options)? handler;

  _FakeHttpAdapter([this.handler]);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString(
      jsonEncode({'candidates': []}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('GeminiClient', () {
    test('melempar GeminiException(400) ramah jika kunci API kosong (No 33)', () async {
      final client = GeminiClient(
        dio: Dio(),
        model: 'gemini-3.5-flash-lite',
      );

      expect(
        () => client.generateContent(
          requestBody: {'contents': []},
          customApiKey: '', // Kunci sengaja dikosongkan
        ),
        throwsA(
          isA<GeminiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.pesan,
                'pesan',
                'Pindai struk belum aktif di versi ini',
              ),
        ),
      );
    });

    test('melempar GeminiException(408) jika TimeoutException terjadi (No 6)', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpAdapter((options) async {
        throw TimeoutException('Batas waktu total 15 detik terlewati');
      });

      final client = GeminiClient(
        dio: dio,
        model: 'gemini-3.5-flash-lite',
      );

      expect(
        () => client.generateContent(
          requestBody: {'contents': []},
          customApiKey: 'kunci_dummy_untuk_uji',
        ),
        throwsA(
          isA<GeminiException>()
              .having((e) => e.statusCode, 'statusCode', 408)
              .having(
                (e) => e.pesan,
                'pesan',
                contains('15 detik'),
              ),
        ),
      );
    });

    test('melempar GeminiException(408) jika Dio connectionTimeout terjadi (No 6)', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });

      final client = GeminiClient(
        dio: dio,
        model: 'gemini-3.5-flash-lite',
      );

      expect(
        () => client.generateContent(
          requestBody: {'contents': []},
          customApiKey: 'kunci_dummy_untuk_uji',
        ),
        throwsA(
          isA<GeminiException>()
              .having((e) => e.statusCode, 'statusCode', 408)
              .having(
                (e) => e.pesan,
                'pesan',
                contains('15 detik'),
              ),
        ),
      );
    });

    test('melempar GeminiException(499) saat CancelToken dibatalkan (No 5 & No 38)', () async {
      final dio = Dio();
      final cancelToken = CancelToken();

      dio.httpClientAdapter = _FakeHttpAdapter((options) async {
        cancelToken.cancel('Dibatalkan oleh pengguna');
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        );
      });

      final client = GeminiClient(
        dio: dio,
        model: 'gemini-3.5-flash-lite',
      );

      expect(
        () => client.generateContent(
          requestBody: {'contents': []},
          customApiKey: 'kunci_dummy_untuk_uji',
          cancelToken: cancelToken,
        ),
        throwsA(
          isA<GeminiException>()
              .having((e) => e.statusCode, 'statusCode', 499)
              .having((e) => e.pesan, 'pesan', contains('dibatalkan')),
        ),
      );
    });

    test('melempar GeminiException(503) jika tidak ada koneksi internet (Dio connectionError)', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      final client = GeminiClient(
        dio: dio,
        model: 'gemini-3.5-flash-lite',
      );

      expect(
        () => client.generateContent(
          requestBody: {'contents': []},
          customApiKey: 'kunci_dummy_untuk_uji',
        ),
        throwsA(
          isA<GeminiException>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having((e) => e.pesan, 'pesan', contains('koneksi internet')),
        ),
      );
    });

    test('mengembalikan Response sukses bila permintaan berhasil', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '{"adalah_struk": true}'}
                  ]
                }
              }
            ]
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = GeminiClient(
        dio: dio,
        model: 'gemini-3.5-flash-lite',
      );

      final response = await client.generateContent(
        requestBody: {'contents': []},
        customApiKey: 'kunci_dummy_untuk_uji',
      );

      expect(response.statusCode, 200);
      expect(response.data, isNotNull);
      expect(response.data!['candidates'], isNotEmpty);
    });
  });
}
