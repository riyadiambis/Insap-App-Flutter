import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/pengaturan/data/datasources/pengaturan_local_datasource.dart';
import 'package:insap/features/pengaturan/data/repositories/pengaturan_repository_impl.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';

class _FakePengaturanLocalDataSource implements PengaturanLocalDataSource {
  final Map<String, String> _memori = {};

  @override
  Future<String?> baca(String kunci) async {
    return _memori[kunci];
  }

  @override
  Future<void> simpan(String kunci, String nilai) async {
    _memori[kunci] = nilai;
  }
}

void main() {
  late _FakePengaturanLocalDataSource fakeDataSource;
  late PengaturanRepository repository;

  setUp(() {
    fakeDataSource = _FakePengaturanLocalDataSource();
    repository = PengaturanRepositoryImpl(dataSource: fakeDataSource);
  });

  group('PengaturanRepository (Refactor ISSUE-25)', () {
    test('bacaStatusOnboarding default false dan true setelah disimpan', () async {
      // Nilai awal belum ada -> false
      expect(await repository.bacaStatusOnboarding(), isFalse);

      // Simpan false ('0') -> false
      await repository.simpanStatusOnboarding(false);
      expect(await repository.bacaStatusOnboarding(), isFalse);

      // Simpan true ('1') -> true
      await repository.simpanStatusOnboarding(true);
      expect(await repository.bacaStatusOnboarding(), isTrue);
    });

    test('baca/tulis target_bulanan menyimpan nominal Rupiah penuh', () async {
      // Belum ada -> null
      expect(await repository.bacaTargetBulanan(), isNull);

      // Simpan 3.500.000
      await repository.simpanTargetBulanan(3500000);
      expect(await repository.bacaTargetBulanan(), 3500000);

      // Ubah jadi 5.000.000
      await repository.simpanTargetBulanan(5000000);
      expect(await repository.bacaTargetBulanan(), 5000000);
    });

    test('bacaPengaturan dan simpanPengaturan untuk kunci umum', () async {
      await repository.simpanPengaturan('kunci_uji', 'nilai_uji');
      expect(await repository.bacaPengaturan('kunci_uji'), 'nilai_uji');
    });
  });
}
