import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/network/gemini_client.dart';
import 'package:insap/features/pindai/data/models/hasil_pindai_model.dart';
import 'package:insap/features/pindai/domain/entities/hasil_pindai_entity.dart';

void main() {
  group('HasilPindaiModel', () {
    test('adalah subclass dari HasilPindaiEntity', () {
      const model = HasilPindaiModel(
        adalahStruk: true,
        namaToko: 'Indomaret Sempaja',
        tanggal: '2026-09-01',
        total: 47500,
        kategoriUsulan: 'makan',
        keyakinan: 0.92,
      );

      expect(model, isA<HasilPindaiEntity>());
    });

    test('fromJson berhasil memetakan JSON valid sesuai GEMINI-CONTRACT.md', () {
      final json = {
        'adalah_struk': true,
        'nama_toko': 'Indomaret Sempaja',
        'tanggal': '2026-09-01',
        'total': 47500,
        'kategori_usulan': 'makan',
        'keyakinan': 0.92,
      };

      final result = HasilPindaiModel.fromJson(json);

      expect(result.adalahStruk, isTrue);
      expect(result.namaToko, 'Indomaret Sempaja');
      expect(result.tanggal, '2026-09-01');
      expect(result.total, 47500);
      expect(result.kategoriUsulan, 'makan');
      expect(result.keyakinan, 0.92);
    });

    test('fromJson berhasil memetakan JSON bukan struk', () {
      final json = {
        'adalah_struk': false,
        'nama_toko': null,
        'tanggal': null,
        'total': null,
        'kategori_usulan': null,
        'keyakinan': 0.0,
      };

      final result = HasilPindaiModel.fromJson(json);

      expect(result.adalahStruk, isFalse);
      expect(result.namaToko, isNull);
      expect(result.tanggal, isNull);
      expect(result.total, isNull);
      expect(result.kategoriUsulan, isNull);
      expect(result.keyakinan, 0.0);
    });

    test('fromJson melempar GeminiException bila adalah_struk hilang dari JSON (No 15)', () {
      final Map<String, dynamic> json = {};

      expect(
        () => HasilPindaiModel.fromJson(json),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.pesan,
            'pesan',
            'Gagal membaca struk, coba lagi',
          ),
        ),
      );
    });

    test('fromJson melempar GeminiException bila adalah_struk bukan boolean (No 15)', () {
      final json = {
        'adalah_struk': 'true', // string bukan boolean
        'nama_toko': 'Kopi Kenangan',
        'tanggal': '2026-10-14',
        'total': 28500,
        'kategori_usulan': 'makan',
        'keyakinan': 0.88,
      };

      expect(
        () => HasilPindaiModel.fromJson(json),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.pesan,
            'pesan',
            'Gagal membaca struk, coba lagi',
          ),
        ),
      );
    });

    test('fromJson menangani total sebagai tipe num/double', () {
      final json = {
        'adalah_struk': true,
        'total': 150000.0,
        'keyakinan': 1.0,
      };

      final result = HasilPindaiModel.fromJson(json);

      expect(result.adalahStruk, isTrue);
      expect(result.total, 150000);
      expect(result.keyakinan, 1.0);
    });

    test('toJson menghasilkan Map yang sesuai dengan skema JSON kontrak', () {
      const model = HasilPindaiModel(
        adalahStruk: true,
        namaToko: 'Alfamart',
        tanggal: '2026-10-14',
        total: 35000,
        kategoriUsulan: 'jajan daring',
        keyakinan: 0.95,
      );

      final map = model.toJson();

      expect(map['adalah_struk'], true);
      expect(map['nama_toko'], 'Alfamart');
      expect(map['tanggal'], '2026-10-14');
      expect(map['total'], 35000);
      expect(map['kategori_usulan'], 'jajan daring');
      expect(map['keyakinan'], 0.95);
    });
  });
}
