import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/network/gemini_client.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';
import 'package:insap/features/pengaturan/domain/usecases/ambil_target_bulanan.dart';
import 'package:insap/features/refleksi/data/datasources/refleksi_ai_remote_datasource.dart';
import 'package:insap/features/refleksi/data/models/hasil_refleksi_ai_model.dart';
import 'package:insap/features/refleksi/data/repositories/refleksi_ai_repository_impl.dart';
import 'package:insap/features/refleksi/domain/entities/refleksi_ai_entity.dart';
import 'package:insap/features/refleksi/domain/usecases/minta_refleksi_ai.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';

class _FakeKategoriRepository implements KategoriRepository {
  @override
  Future<List<KategoriEntity>> ambilSemua() async => const [
    KategoriEntity(
      id: 1,
      nama: 'makan',
      ikon: 'restaurant',
      warna: '#E8734A',
      kelompokKakeibo: 'esensial',
      bawaan: 1,
      urutan: 1,
    ),
    KategoriEntity(
      id: 6,
      nama: 'nongkrong',
      ikon: 'local_cafe',
      warna: '#FFB020',
      kelompokKakeibo: 'hiburan',
      bawaan: 1,
      urutan: 6,
    ),
  ];
}

class _FakeTransaksiRepository implements TransaksiRepository {
  List<TransaksiEntity> daftarPekanIni = const [];
  List<TransaksiEntity> daftarPekanLalu = const [];

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    if (tanggalMulai == '2026-11-16') return daftarPekanIni;
    return daftarPekanLalu;
  }

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async =>
      List.generate(daftarTransaksi.length, (i) => i + 1);
}

class _FakePengaturanRepository implements PengaturanRepository {
  final Map<String, String> data = {};
  int? targetBulanan;

  @override
  Future<String?> bacaPengaturan(String kunci) async => data[kunci];

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {
    data[kunci] = nilai;
  }

  @override
  Future<bool> bacaStatusOnboarding() async => true;

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {}

  @override
  Future<int?> bacaTargetBulanan() async => targetBulanan;

  @override
  Future<void> simpanTargetBulanan(int target) async {
    targetBulanan = target;
  }
}

class _FakeGeminiClient extends GeminiClient {
  int jumlahPanggilan = 0;
  final List<Map<String, dynamic>> bodyTerkirim = [];
  Future<Response<Map<String, dynamic>>> Function(
    Map<String, dynamic> requestBody,
    int panggilanKe,
  )?
  onGenerate;

  _FakeGeminiClient({this.onGenerate})
    : super(dio: Dio(), model: 'gemini-3.5-flash-lite');

  @override
  Future<Response<Map<String, dynamic>>> generateContent({
    required Map<String, dynamic> requestBody,
    String? customApiKey,
    CancelToken? cancelToken,
  }) async {
    jumlahPanggilan++;
    bodyTerkirim.add(requestBody);
    if (onGenerate != null) {
      return onGenerate!(requestBody, jumlahPanggilan);
    }
    return Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/generateContent'),
      statusCode: 200,
      data: {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'saran': [
                      {
                        'kategori': 'makan',
                        'teks':
                            'Makan turun Rp 25.000 dibanding pekan lalu. Pertahankan bawa bekal!',
                      },
                      {
                        'kategori': 'nongkrong',
                        'teks':
                            'Nongkrong 2 kali pekan ini, total Rp 80.000. Tetap aman terkendali.',
                      },
                      {
                        'kategori': 'umum',
                        'teks':
                            'Sisihkan Rp 50.000 ke tabungan di awal pekan depan.',
                      },
                    ],
                  }),
                },
              ],
            },
          },
        ],
      },
    );
  }
}

class _FakeHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _FakeHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  final tanggalAcuan = DateTime(2026, 11, 20); // Senin ISO: 2026-11-16

  group('HasilRefleksiAiModel parsing', () {
    test('parsing JSON valid dengan pemotongan teks > 160 karakter dan kategori tak dikenal -> umum', () {
      final teksPanjang = 'A' * 200;
      final raw = jsonEncode({
        'saran': [
          {'kategori': 'Makan', 'teks': '  $teksPanjang  '},
          {'kategori': 'kategori_asing', 'teks': 'Kurangi jajan impulsif.'},
          {'kategori': 'nongkrong', 'teks': 'Batas Rp 60.000 pekan depan.'},
        ],
      });

      final model = HasilRefleksiAiModel.fromRawText(
        '```json\n$raw\n```',
        daftarKategori: const ['makan', 'nongkrong'],
      );

      expect(model.saran.length, 3);
      expect(model.saran[0].kategori, 'makan');
      expect(model.saran[0].teks.length, 160);
      expect(model.saran[1].kategori, 'umum');
      expect(model.saran[2].kategori, 'nongkrong');
    });

    test('melempar GeminiException jika JSON rusak', () {
      expect(
        () => HasilRefleksiAiModel.fromRawText('{bukan json valid'),
        throwsA(isA<GeminiException>()),
      );
    });

    test('melempar GeminiException jika saran kurang dari 3 item', () {
      final raw = jsonEncode({
        'saran': [
          {'kategori': 'makan', 'teks': 'Saran 1'},
          {'kategori': 'nongkrong', 'teks': 'Saran 2'},
        ],
      });
      expect(
        () => HasilRefleksiAiModel.fromRawText(raw),
        throwsA(isA<GeminiException>()),
      );
    });

    test('melempar GeminiException jika teks saran kosong', () {
      final raw = jsonEncode({
        'saran': [
          {'kategori': 'makan', 'teks': '   '},
          {'kategori': 'nongkrong', 'teks': 'Saran 2'},
          {'kategori': 'umum', 'teks': 'Saran 3'},
        ],
      });
      expect(
        () => HasilRefleksiAiModel.fromRawText(raw),
        throwsA(isA<GeminiException>()),
      );
    });
  });

  group('Cache per pekan dan privasi payload', () {
    test('panggilan kedua pada pekan yang sama memakai cache tanpa memanggil AI', () async {
      final pengaturanRepo = _FakePengaturanRepository()
        ..targetBulanan = 2000000; // target pekanan 500.000
      final transaksiRepo = _FakeTransaksiRepository()
        ..daftarPekanIni = const [
          TransaksiEntity(
            id: 1,
            jumlah: 180000,
            kategoriId: 1,
            tanggal: '2026-11-18',
            catatan: 'RAHASIA_CATATAN_PRIBADI',
            namaToko: 'WARUNG_RAHASIA',
            dibuatPada: '2026-11-18T12:00:00',
          ),
        ];
      final fakeClient = _FakeGeminiClient();
      final remoteDs = RefleksiAiRemoteDataSourceImpl(geminiClient: fakeClient);
      final repo = RefleksiAiRepositoryImpl(
        remoteDataSource: remoteDs,
        pengaturanRepository: pengaturanRepo,
      );
      final useCase = MintaRefleksiAi(
        refleksiAiRepository: repo,
        transaksiRepository: transaksiRepo,
        kategoriRepository: _FakeKategoriRepository(),
        ambilTargetBulanan: AmbilTargetBulanan(pengaturanRepo),
        sekarang: () => tanggalAcuan,
      );

      final pertama = await useCase();
      expect(fakeClient.jumlahPanggilan, 1);
      expect(pertama.saran.length, 3);
      expect(pengaturanRepo.data.containsKey('refleksi_ai_2026-11-16'), isTrue);

      // Verifikasi payload tidak mengandung catatan, nama toko, atau nama barang
      final payloadStr = jsonEncode(fakeClient.bodyTerkirim.first);
      expect(payloadStr, isNot(contains('RAHASIA_CATATAN_PRIBADI')));
      expect(payloadStr, isNot(contains('WARUNG_RAHASIA')));
      expect(payloadStr, isNot(contains('nama_toko')));
      expect(payloadStr, contains('180000'));
      expect(payloadStr, contains('makan'));

      // Panggilan kedua pada pekan yang sama
      final kedua = await useCase();
      expect(fakeClient.jumlahPanggilan, 1); // tidak memanggil AI lagi
      expect(kedua.saran.length, 3);
      expect(kedua.saran.first.teks, pertama.saran.first.teks);
    });

    test('bila pemanggilan AI gagal, hasil tidak disimpan ke cache pengaturan', () async {
      final pengaturanRepo = _FakePengaturanRepository();
      final transaksiRepo = _FakeTransaksiRepository()
        ..daftarPekanIni = const [
          TransaksiEntity(
            id: 1,
            jumlah: 100000,
            kategoriId: 1,
            tanggal: '2026-11-18',
            dibuatPada: '2026-11-18T12:00:00',
          ),
        ];
      final fakeClient = _FakeGeminiClient(
        onGenerate: (_, _) async {
          throw const GeminiException('Tidak ada koneksi internet', 503);
        },
      );
      final repo = RefleksiAiRepositoryImpl(
        remoteDataSource: RefleksiAiRemoteDataSourceImpl(
          geminiClient: fakeClient,
        ),
        pengaturanRepository: pengaturanRepo,
      );
      final useCase = MintaRefleksiAi(
        refleksiAiRepository: repo,
        transaksiRepository: transaksiRepo,
        kategoriRepository: _FakeKategoriRepository(),
        ambilTargetBulanan: AmbilTargetBulanan(pengaturanRepo),
        sekarang: () => tanggalAcuan,
      );

      await expectLater(useCase(), throwsA(isA<GeminiException>()));
      expect(
        pengaturanRepo.data.containsKey('refleksi_ai_2026-11-16'),
        isFalse,
      );
    });

    test('fallback aman bila model menolak thinkingConfig dengan status 400', () async {
      final dio = Dio();
      int hitCount = 0;
      dio.httpClientAdapter = _FakeHttpAdapter((options) async {
        hitCount++;
        final data = options.data as Map<String, dynamic>;
        final genConfig = data['generationConfig'] as Map<String, dynamic>;
        if (hitCount == 1 && genConfig.containsKey('thinkingConfig')) {
          return ResponseBody.fromString(
            jsonEncode({
              'error': {'message': 'thinkingConfig is not supported'},
            }),
            400,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'saran': [
                          {'kategori': 'makan', 'teks': 'Saran 1'},
                          {'kategori': 'nongkrong', 'teks': 'Saran 2'},
                          {'kategori': 'umum', 'teks': 'Saran 3'},
                        ],
                      }),
                    },
                  ],
                },
              },
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = GeminiClient(dio: dio, model: 'gemini-test');
      // Gunakan customApiKey tidak bisa diinjeksi langsung lewat remoteDs, jadi kita test via wrapper client
      final remoteDs = RefleksiAiRemoteDataSourceImpl(
        geminiClient: _TestKeyGeminiClient(dio: dio),
      );

      final saran = await remoteDs.mintaSaran(
        const RingkasanRefleksiAiInput(
          rentangPekan: '16 - 22 Nov',
          tanggalSeninIso: '2026-11-16',
          totalPekanIni: 100000,
          targetPekanan: 200000,
          totalPekanLalu: 120000,
          daftarKategori: [
            AgregatKategoriAi(
              nama: 'makan',
              totalPekanIni: 100000,
              totalPekanLalu: 120000,
              jumlahTransaksi: 2,
            ),
          ],
        ),
      );
      expect(client.model, 'gemini-test');
      expect(hitCount, 2);
      expect(saran.length, 3);
    });
  });

  group('Evaluasi hemat vs boncos', () {
    test('dengan target bulanan: di bawah target pekanan (bulanan/4) -> hemat, di atas -> boncos', () {
      // Target bulanan 2.000.000 -> target pekanan 500.000
      final hemat = EvaluasiHematBoncos.hitung(
        totalPekanIni: 412500,
        targetBulanan: 2000000,
        totalPekanLalu: 300000,
      );
      expect(hemat.hemat, isTrue);
      expect(hemat.pakaiTarget, isTrue);
      expect(hemat.pembanding, 500000);
      expect(hemat.selisih, -87500);

      final boncos = EvaluasiHematBoncos.hitung(
        totalPekanIni: 564000,
        targetBulanan: 2000000,
        totalPekanLalu: 700000,
      );
      expect(boncos.hemat, isFalse);
      expect(boncos.pakaiTarget, isTrue);
      expect(boncos.pembanding, 500000);
      expect(boncos.selisih, 64000);
    });

    test('tanpa target bulanan: memakai total pekan lalu sebagai pembanding', () {
      final hemat = EvaluasiHematBoncos.hitung(
        totalPekanIni: 150000,
        targetBulanan: null,
        totalPekanLalu: 200000,
      );
      expect(hemat.hemat, isTrue);
      expect(hemat.pakaiTarget, isFalse);
      expect(hemat.pembanding, 200000);
      expect(hemat.selisih, -50000);

      final boncos = EvaluasiHematBoncos.hitung(
        totalPekanIni: 240000,
        targetBulanan: null,
        totalPekanLalu: 200000,
      );
      expect(boncos.hemat, isFalse);
      expect(boncos.pakaiTarget, isFalse);
      expect(boncos.pembanding, 200000);
      expect(boncos.selisih, 40000);
    });
  });
}

class _TestKeyGeminiClient extends GeminiClient {
  _TestKeyGeminiClient({required super.dio});

  @override
  Future<Response<Map<String, dynamic>>> generateContent({
    required Map<String, dynamic> requestBody,
    String? customApiKey,
    CancelToken? cancelToken,
  }) {
    return super.generateContent(
      requestBody: requestBody,
      customApiKey: customApiKey ?? 'kunci_uji_dummy',
      cancelToken: cancelToken,
    );
  }
}
