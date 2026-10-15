import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/pengaturan/domain/entities/perbandingan_target_entity.dart';
import 'package:insap/features/pengaturan/domain/usecases/hitung_perbandingan_target.dart';

void main() {
  group('PerbandinganTargetEntity & HitungPerbandinganTarget (ISSUE-25)', () {
    const hitungUsecase = HitungPerbandinganTarget();

    test('(a.1) di bawah target: persen < 1.0, sisa > 0, lewat = 0, isLewat false', () {
      final hasil = hitungUsecase(
        totalBulanIni: 1500000,
        targetBulanan: 2000000,
      );
      final hasilEntitas = PerbandinganTargetEntity.hitung(
        totalBulanIni: 1500000,
        targetBulanan: 2000000,
      );

      expect(hasil, equals(hasilEntitas));
      expect(hasil.adaTarget, isTrue);
      expect(hasil.totalBulanIni, 1500000);
      expect(hasil.targetBulanan, 2000000);
      expect(hasil.persen, 0.75);
      expect(hasil.sisa, 500000);
      expect(hasil.lewat, 0);
      expect(hasil.isLewat, isFalse);
      expect(hasil.isTepat, isFalse);
    });

    test('(a.2) tepat target: persen == 1.0, sisa = 0, lewat = 0, isTepat true', () {
      final hasil = hitungUsecase(
        totalBulanIni: 2000000,
        targetBulanan: 2000000,
      );

      expect(hasil.adaTarget, isTrue);
      expect(hasil.persen, 1.0);
      expect(hasil.sisa, 0);
      expect(hasil.lewat, 0);
      expect(hasil.isLewat, isFalse);
      expect(hasil.isTepat, isTrue);
    });

    test('(a.3) lewat target: persen > 1.0, sisa = 0, lewat > 0, isLewat true', () {
      final hasil = hitungUsecase(
        totalBulanIni: 2500000,
        targetBulanan: 2000000,
      );

      expect(hasil.adaTarget, isTrue);
      expect(hasil.persen, 1.25);
      expect(hasil.sisa, 0);
      expect(hasil.lewat, 500000);
      expect(hasil.isLewat, isTrue);
      expect(hasil.isTepat, isFalse);
    });

    test('(a.4) target null: adaTarget false, persen = 0, sisa = 0, lewat = 0', () {
      final hasil = hitungUsecase(
        totalBulanIni: 1200000,
        targetBulanan: null,
      );

      expect(hasil.adaTarget, isFalse);
      expect(hasil.targetBulanan, isNull);
      expect(hasil.persen, 0.0);
      expect(hasil.sisa, 0);
      expect(hasil.lewat, 0);
      expect(hasil.isLewat, isFalse);
      expect(hasil.isTepat, isFalse);
    });

    test('(a.5) target 0 atau negatif dianggap belum ada target', () {
      final hasilNol = hitungUsecase(
        totalBulanIni: 500000,
        targetBulanan: 0,
      );
      expect(hasilNol.adaTarget, isFalse);

      final hasilNegatif = hitungUsecase(
        totalBulanIni: 500000,
        targetBulanan: -100000,
      );
      expect(hasilNegatif.adaTarget, isFalse);
    });
  });
}
