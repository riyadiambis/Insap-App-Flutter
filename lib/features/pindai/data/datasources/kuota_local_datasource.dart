import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/kuota_constants.dart';
import '../../../../core/database/database_helper.dart';

abstract class KuotaLocalDataSource {
  Future<int> ambilSisaKuota({DateTime? waktuSekarang});
  Future<int> ambilSisaBonusIklan({DateTime? waktuSekarang});
  Future<bool> tambahBonusIklan({DateTime? waktuSekarang});
  Future<void> potongKuota({DateTime? waktuSekarang});
  Future<void> resetKuotaKeAwal({DateTime? waktuSekarang});
}

class KuotaLocalDataSourceImpl implements KuotaLocalDataSource {
  final DatabaseHelper _dbHelper;
  static const int kuotaMaksimal = kuotaPindaiPekanan;
  static const String _kunciSisa = 'kuota_pindai_sisa';
  static const String _kunciPeriode = 'kuota_periode_mulai';
  static const String _kunciBonusTerpakai = 'kuota_bonus_iklan_terpakai';

  KuotaLocalDataSourceImpl(this._dbHelper);

  static String _hitungSeninIso(DateTime sekarang) {
    final seninPekanIni = sekarang.subtract(Duration(days: sekarang.weekday - 1));
    return '${seninPekanIni.year.toString().padLeft(4, '0')}-'
        '${seninPekanIni.month.toString().padLeft(2, '0')}-'
        '${seninPekanIni.day.toString().padLeft(2, '0')}';
  }

  Future<String?> _bacaNilai(DatabaseExecutor db, String kunci) async {
    final result = await db.query(
      'pengaturan',
      columns: ['nilai'],
      where: 'kunci = ?',
      whereArgs: [kunci],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['nilai'] as String?;
  }

  Future<void> _tulisNilai(
    DatabaseExecutor db,
    String kunci,
    String nilai,
  ) async {
    await db.insert(
      'pengaturan',
      {'kunci': kunci, 'nilai': nilai},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _resetDalamTransaksi(
    DatabaseExecutor txn,
    String seninIso,
  ) async {
    await _tulisNilai(txn, _kunciSisa, kuotaMaksimal.toString());
    await _tulisNilai(txn, _kunciPeriode, seninIso);
    await _tulisNilai(txn, _kunciBonusTerpakai, '0');
  }

  @override
  Future<int> ambilSisaKuota({DateTime? waktuSekarang}) async {
    final db = await _dbHelper.database;
    final sekarang = waktuSekarang ?? DateTime.now();
    final seninIso = _hitungSeninIso(sekarang);

    // 1. Ambil periode mulai saat ini di database
    final periodeDatabase = await _bacaNilai(db, _kunciPeriode);

    // 2. Jika berganti pekan (periode tidak sama dengan Senin pekan berjalan), reset kuota otomatis
    if (periodeDatabase != seninIso) {
      await resetKuotaKeAwal(waktuSekarang: sekarang);
      return kuotaMaksimal;
    }

    // 3. Baca bonus iklan terpakai pekan ini agar batas pangkas ikut bertambah
    final valBonus = await _bacaNilai(db, _kunciBonusTerpakai);
    final bonusTerpakai = (int.tryParse(valBonus ?? '') ?? 0).clamp(
      0,
      bonusIklanMaksimalPekanan,
    );
    final batasMaksimal = kuotaMaksimal + bonusTerpakai;

    // 4. Baca nilai sisa kuota yang tersimpan
    final valSisa = await _bacaNilai(db, _kunciSisa);
    if (valSisa != null) {
      final sisa = int.tryParse(valSisa) ?? kuotaMaksimal;
      if (sisa > batasMaksimal) {
        return batasMaksimal;
      }
      return sisa;
    }

    return kuotaMaksimal;
  }

  @override
  Future<int> ambilSisaBonusIklan({DateTime? waktuSekarang}) async {
    final db = await _dbHelper.database;
    final sekarang = waktuSekarang ?? DateTime.now();
    final seninIso = _hitungSeninIso(sekarang);

    final periodeDatabase = await _bacaNilai(db, _kunciPeriode);
    if (periodeDatabase != seninIso) {
      await resetKuotaKeAwal(waktuSekarang: sekarang);
      return bonusIklanMaksimalPekanan;
    }

    final valBonus = await _bacaNilai(db, _kunciBonusTerpakai);
    final bonusTerpakai = (int.tryParse(valBonus ?? '') ?? 0).clamp(
      0,
      bonusIklanMaksimalPekanan,
    );
    return (bonusIklanMaksimalPekanan - bonusTerpakai).clamp(
      0,
      bonusIklanMaksimalPekanan,
    );
  }

  @override
  Future<bool> tambahBonusIklan({DateTime? waktuSekarang}) async {
    final db = await _dbHelper.database;
    final sekarang = waktuSekarang ?? DateTime.now();
    final seninIso = _hitungSeninIso(sekarang);

    return db.transaction<bool>((txn) async {
      final periodeDatabase = await _bacaNilai(txn, _kunciPeriode);
      int bonusTerpakai;
      int sisaKuota;

      if (periodeDatabase != seninIso) {
        await _resetDalamTransaksi(txn, seninIso);
        bonusTerpakai = 0;
        sisaKuota = kuotaMaksimal;
      } else {
        final valBonus = await _bacaNilai(txn, _kunciBonusTerpakai);
        bonusTerpakai = (int.tryParse(valBonus ?? '') ?? 0).clamp(
          0,
          bonusIklanMaksimalPekanan,
        );
        if (bonusTerpakai >= bonusIklanMaksimalPekanan) {
          return false;
        }

        final valSisa = await _bacaNilai(txn, _kunciSisa);
        final sisaRaw = int.tryParse(valSisa ?? '') ?? kuotaMaksimal;
        final batasMaksimal = kuotaMaksimal + bonusTerpakai;
        sisaKuota = sisaRaw.clamp(0, batasMaksimal);
      }

      if (bonusTerpakai >= bonusIklanMaksimalPekanan) {
        return false;
      }

      await _tulisNilai(txn, _kunciSisa, (sisaKuota + 1).toString());
      await _tulisNilai(
        txn,
        _kunciBonusTerpakai,
        (bonusTerpakai + 1).toString(),
      );
      return true;
    });
  }

  @override
  Future<void> potongKuota({DateTime? waktuSekarang}) async {
    final sisa = await ambilSisaKuota(waktuSekarang: waktuSekarang);
    if (sisa <= 0) return;

    final db = await _dbHelper.database;
    final sisaBaru = sisa - 1;
    await _tulisNilai(db, _kunciSisa, sisaBaru.toString());
  }

  @override
  Future<void> resetKuotaKeAwal({DateTime? waktuSekarang}) async {
    final db = await _dbHelper.database;
    final sekarang = waktuSekarang ?? DateTime.now();
    final seninIso = _hitungSeninIso(sekarang);

    await db.transaction((txn) async {
      await _resetDalamTransaksi(txn, seninIso);
    });
  }
}
