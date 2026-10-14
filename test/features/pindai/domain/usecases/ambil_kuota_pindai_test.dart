import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/database/database_helper.dart';
import 'package:insap/core/database/seed_pengaturan.dart';
import 'package:insap/features/pindai/data/datasources/kuota_local_datasource.dart';
import 'package:insap/features/pindai/domain/entities/hasil_pindai_entity.dart';
import 'package:insap/features/pindai/domain/repositories/pindai_repository.dart';
import 'package:insap/features/pindai/domain/usecases/ambil_kuota_pindai.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakePindaiRepository implements PindaiRepository {
  int kuotaKembalian = 10;
  bool ambilSisaKuotaDipanggil = false;

  @override
  Future<int> ambilSisaKuota() async {
    ambilSisaKuotaDipanggil = true;
    return kuotaKembalian;
  }

  @override
  Future<HasilPindaiEntity> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> potongKuota() async {}
}

void main() {
  group('AmbilKuotaPindai Use Case', () {
    test('memanggil ambilSisaKuota pada PindaiRepository', () async {
      final fakeRepo = _FakePindaiRepository();
      fakeRepo.kuotaKembalian = 7;
      final useCase = AmbilKuotaPindai(fakeRepo);

      final result = await useCase();

      expect(fakeRepo.ambilSisaKuotaDipanggil, isTrue);
      expect(result, 7);
    });
  });

  group('KuotaLocalDataSource & Auto-Reset Mingguan di Basis Data', () {
    late Directory folderSementara;
    late Database db;
    late KuotaLocalDataSourceImpl dataSource;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      folderSementara =
          await Directory.systemTemp.createTemp('insap_kuota_test_');
      await databaseFactory.setDatabasesPath(folderSementara.path);
      db = await DatabaseHelper().database;
      dataSource = KuotaLocalDataSourceImpl(DatabaseHelper());
    });

    tearDownAll(() async {
      await db.close();
      await folderSementara.delete(recursive: true);
    });

    setUp(() async {
      // Kembalikan seed pengaturan awal
      await db.delete('pengaturan');
      for (final p in buatSeedPengaturan()) {
        await db.insert('pengaturan', p.toMap());
      }
    });

    test('kuota awal pada saat aplikasi baru dibuka adalah 10', () async {
      final sisa = await dataSource.ambilSisaKuota();
      expect(sisa, 10);
    });

    test('potongKuota berhasil mengurangi kuota bertahap', () async {
      await dataSource.potongKuota();
      expect(await dataSource.ambilSisaKuota(), 9);

      await dataSource.potongKuota();
      expect(await dataSource.ambilSisaKuota(), 8);
    });

    test('tidak melakukan reset kuota jika masih di dalam pekan yang sama', () async {
      // Kurangi kuota hingga 7 pada hari Senin
      final senin = DateTime(2026, 10, 12, 10, 0); // Senin
      await dataSource.ambilSisaKuota(waktuSekarang: senin);
      await dataSource.potongKuota();
      await dataSource.potongKuota();
      await dataSource.potongKuota();
      expect(await dataSource.ambilSisaKuota(waktuSekarang: senin), 7);

      // Cek pada hari Kamis di pekan yang sama
      final kamis = DateTime(2026, 10, 15, 14, 0);
      final sisaKamis = await dataSource.ambilSisaKuota(waktuSekarang: kamis);

      // Kuota harus tetap 7, tidak boleh direset
      expect(sisaKamis, 7);
    });

    test('mereset kuota otomatis ke 10 saat berganti ke pekan berikutnya', () async {
      // Set kuota terpakai menjadi 5 pada pekan lama
      final pekanLama = DateTime(2026, 10, 12, 10, 0);
      await dataSource.ambilSisaKuota(waktuSekarang: pekanLama);
      for (int i = 0; i < 5; i++) {
        await dataSource.potongKuota();
      }
      expect(await dataSource.ambilSisaKuota(waktuSekarang: pekanLama), 5);

      // Berpindah ke Senin pekan depan (2026-10-19)
      final seninPekanDepan = DateTime(2026, 10, 19, 8, 30);
      final sisaPekanBaru =
          await dataSource.ambilSisaKuota(waktuSekarang: seninPekanDepan);

      // Kuota harus otomatis ter-reset kembali ke 10
      expect(sisaPekanBaru, 10);

      // Verifikasi bahwa periode di database juga sudah terbarui
      final result = await db.query(
        'pengaturan',
        where: 'kunci = ?',
        whereArgs: ['kuota_periode_mulai'],
      );
      expect(result.first['nilai'], '2026-10-19');
    });
  });
}
