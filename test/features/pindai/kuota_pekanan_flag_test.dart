import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/constants/kuota_constants.dart';
import 'package:insap/core/database/database_helper.dart';
import 'package:insap/core/database/seed_pengaturan.dart';
import 'package:insap/features/pindai/data/datasources/kuota_local_datasource.dart';
import 'package:insap/features/transaksi/data/datasources/transaksi_local_datasource.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('ISSUE-26 Tahap 3: Jatah Kuota Pindai Pekanan', () {
    late Directory folderSementara;
    late Database db;
    late KuotaLocalDataSourceImpl kuotaDataSource;
    late TransaksiLocalDataSource transaksiDataSource;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      folderSementara =
          await Directory.systemTemp.createTemp('insap_kuota_flag_test_');
      await databaseFactory.setDatabasesPath(folderSementara.path);
      db = await DatabaseHelper().database;
      kuotaDataSource = KuotaLocalDataSourceImpl(DatabaseHelper());
      transaksiDataSource = TransaksiLocalDataSource(dbHelper: DatabaseHelper());
    });

    tearDownAll(() async {
      await db.close();
      await folderSementara.delete(recursive: true);
    });

    test('1. Nilai bawaan kuotaPindaiPekanan adalah 10 jika flag build tidak disetel', () {
      expect(kuotaPindaiPekanan, 10);
      expect(KuotaLocalDataSourceImpl.kuotaMaksimal, 10);
    });

    test('2. Sisa kuota di database yang lebih besar dari jatah otomatis dipangkas ke jatah', () async {
      // Simulasikan database memiliki nilai sisa kuota 999 (misal sisa demo atau korup)
      final seninPekanIni = DateTime(2026, 10, 19, 10, 0);
      await db.delete('pengaturan');
      for (final p in buatSeedPengaturan(waktuSekarang: seninPekanIni)) {
        await db.insert('pengaturan', p.toMap());
      }

      await db.update(
        'pengaturan',
        {'nilai': '999'},
        where: 'kunci = ?',
        whereArgs: ['kuota_pindai_sisa'],
      );

      // KuotaLocalDataSource harus memangkas ke kuotaPindaiPekanan (10)
      final sisaPindai = await kuotaDataSource.ambilSisaKuota(waktuSekarang: seninPekanIni);
      expect(sisaPindai, kuotaPindaiPekanan);
      expect(sisaPindai, 10);

      // TransaksiLocalDataSource juga memangkas ke kuotaPindaiPekanan (10)
      final sisaTransaksi = await transaksiDataSource.ambilKuotaPindai();
      expect(sisaTransaksi, kuotaPindaiPekanan);
      expect(sisaTransaksi, 10);
    });

    test('3. Isi ulang otomatis pada hari Senin memakai jatah kuota aktif', () async {
      // Mulai dengan sisa 2 pada pekan lalu (2026-10-12)
      final pekanLalu = DateTime(2026, 10, 12, 10, 0);
      await db.delete('pengaturan');
      for (final p in buatSeedPengaturan(waktuSekarang: pekanLalu)) {
        await db.insert('pengaturan', p.toMap());
      }
      await db.update(
        'pengaturan',
        {'nilai': '2'},
        where: 'kunci = ?',
        whereArgs: ['kuota_pindai_sisa'],
      );

      // Beralih ke Senin pekan berikutnya (2026-10-19)
      final seninBerikutnya = DateTime(2026, 10, 19, 9, 0);
      final sisaSetelahReset = await kuotaDataSource.ambilSisaKuota(waktuSekarang: seninBerikutnya);

      // Kuota harus diisi ulang tepat sebanyak kuotaPindaiPekanan (10)
      expect(sisaSetelahReset, kuotaPindaiPekanan);
      expect(sisaSetelahReset, 10);

      // Verifikasi nilai tersimpan di database juga sama dengan jatah kuota
      final barisSisa = await db.query(
        'pengaturan',
        where: 'kunci = ?',
        whereArgs: ['kuota_pindai_sisa'],
      );
      expect(barisSisa.first['nilai'], kuotaPindaiPekanan.toString());
    });
  });
}
