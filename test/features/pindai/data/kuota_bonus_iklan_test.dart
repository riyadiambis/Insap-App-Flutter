import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/constants/kuota_constants.dart';
import 'package:insap/core/database/database_helper.dart';
import 'package:insap/core/database/seed_pengaturan.dart';
import 'package:insap/features/pindai/data/datasources/kuota_local_datasource.dart';
import 'package:insap/features/transaksi/data/datasources/transaksi_local_datasource.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Kuota Bonus Iklan Rewarded (ISSUE-40)', () {
    late Directory folderSementara;
    late Database db;
    late KuotaLocalDataSourceImpl kuotaDataSource;
    late TransaksiLocalDataSource transaksiDataSource;

    final seninPekanIni = DateTime(2026, 10, 19, 10, 0);

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      folderSementara = await Directory.systemTemp.createTemp(
        'insap_kuota_bonus_iklan_test_',
      );
      await databaseFactory.setDatabasesPath(folderSementara.path);
      db = await DatabaseHelper().database;
      kuotaDataSource = KuotaLocalDataSourceImpl(DatabaseHelper());
      transaksiDataSource = TransaksiLocalDataSource(
        dbHelper: DatabaseHelper(),
      );
    });

    tearDownAll(() async {
      await db.close();
      await folderSementara.delete(recursive: true);
    });

    setUp(() async {
      await db.delete('pengaturan');
      for (final p in buatSeedPengaturan(waktuSekarang: seninPekanIni)) {
        await db.insert('pengaturan', p.toMap());
      }
    });

    test('bonus menambah sisa kuota +1 dan mengurangi sisa bonus -1', () async {
      // Habiskan 5 kuota awal terlebih dahulu
      for (int i = 0; i < kuotaPindaiPekanan; i++) {
        await kuotaDataSource.potongKuota(waktuSekarang: seninPekanIni);
      }
      expect(
        await kuotaDataSource.ambilSisaKuota(waktuSekarang: seninPekanIni),
        0,
      );
      expect(
        await kuotaDataSource.ambilSisaBonusIklan(
          waktuSekarang: seninPekanIni,
        ),
        bonusIklanMaksimalPekanan,
      );

      final berhasil = await kuotaDataSource.tambahBonusIklan(
        waktuSekarang: seninPekanIni,
      );

      expect(berhasil, isTrue);
      expect(
        await kuotaDataSource.ambilSisaKuota(waktuSekarang: seninPekanIni),
        1,
      );
      expect(
        await kuotaDataSource.ambilSisaBonusIklan(
          waktuSekarang: seninPekanIni,
        ),
        bonusIklanMaksimalPekanan - 1,
      );
    });

    test(
      'maksimal 10 bonus per pekan, klaim ke-11 mengembalikan false',
      () async {
        for (int i = 0; i < kuotaPindaiPekanan; i++) {
          await kuotaDataSource.potongKuota(waktuSekarang: seninPekanIni);
        }

        for (int i = 0; i < bonusIklanMaksimalPekanan; i++) {
          final ok = await kuotaDataSource.tambahBonusIklan(
            waktuSekarang: seninPekanIni,
          );
          expect(ok, isTrue, reason: 'Klaim ke-${i + 1} harus berhasil');
        }

        expect(
          await kuotaDataSource.ambilSisaBonusIklan(
            waktuSekarang: seninPekanIni,
          ),
          0,
        );
        expect(
          await kuotaDataSource.ambilSisaKuota(waktuSekarang: seninPekanIni),
          bonusIklanMaksimalPekanan,
        );

        final klaimKe11 = await kuotaDataSource.tambahBonusIklan(
          waktuSekarang: seninPekanIni,
        );
        expect(klaimKe11, isFalse);
        expect(
          await kuotaDataSource.ambilSisaKuota(waktuSekarang: seninPekanIni),
          bonusIklanMaksimalPekanan,
        );
      },
    );

    test(
      'bonus tidak terpangkas oleh ambilSisaKuota maupun TransaksiLocalDataSource (plafon 15)',
      () async {
        // Klaim 10 bonus saat sisa masih penuh (5 + 10 = 15)
        for (int i = 0; i < bonusIklanMaksimalPekanan; i++) {
          final ok = await kuotaDataSource.tambahBonusIklan(
            waktuSekarang: seninPekanIni,
          );
          expect(ok, isTrue);
        }

        final sisaKuota = await kuotaDataSource.ambilSisaKuota(
          waktuSekarang: seninPekanIni,
        );
        final sisaDariTransaksi = await transaksiDataSource.ambilKuotaPindai();

        expect(sisaKuota, kuotaPindaiPekanan + bonusIklanMaksimalPekanan);
        expect(
          sisaDariTransaksi,
          kuotaPindaiPekanan + bonusIklanMaksimalPekanan,
        );
      },
    );

    test(
      'reset pekan baru mengembalikan bonus terpakai ke 0 dan sisa ke kuotaPindaiPekanan',
      () async {
        // Pakai 3 bonus di pekan ini
        for (int i = 0; i < 3; i++) {
          await kuotaDataSource.tambahBonusIklan(waktuSekarang: seninPekanIni);
        }
        expect(
          await kuotaDataSource.ambilSisaBonusIklan(
            waktuSekarang: seninPekanIni,
          ),
          7,
        );

        // Pindah ke Senin pekan depan
        final seninPekanDepan = seninPekanIni.add(const Duration(days: 7));
        final sisaPekanBaru = await kuotaDataSource.ambilSisaKuota(
          waktuSekarang: seninPekanDepan,
        );
        final sisaBonusPekanBaru = await kuotaDataSource.ambilSisaBonusIklan(
          waktuSekarang: seninPekanDepan,
        );

        expect(sisaPekanBaru, kuotaPindaiPekanan);
        expect(sisaBonusPekanBaru, bonusIklanMaksimalPekanan);
      },
    );

    test(
      'basis data lama tanpa baris kuota_bonus_iklan_terpakai tetap bekerja',
      () async {
        // Pastikan kunci bonus tidak ada di tabel pengaturan
        await db.delete(
          'pengaturan',
          where: 'kunci = ?',
          whereArgs: ['kuota_bonus_iklan_terpakai'],
        );
        await db.update(
          'pengaturan',
          {'nilai': '0'},
          where: 'kunci = ?',
          whereArgs: ['kuota_pindai_sisa'],
        );

        expect(
          await kuotaDataSource.ambilSisaBonusIklan(
            waktuSekarang: seninPekanIni,
          ),
          bonusIklanMaksimalPekanan,
        );

        final berhasil = await kuotaDataSource.tambahBonusIklan(
          waktuSekarang: seninPekanIni,
        );
        expect(berhasil, isTrue);
        expect(
          await kuotaDataSource.ambilSisaKuota(waktuSekarang: seninPekanIni),
          1,
        );
        expect(
          await kuotaDataSource.ambilSisaBonusIklan(
            waktuSekarang: seninPekanIni,
          ),
          bonusIklanMaksimalPekanan - 1,
        );
      },
    );
  });
}
