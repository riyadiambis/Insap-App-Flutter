import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';

abstract class KuotaLocalDataSource {
  Future<int> ambilSisaKuota({DateTime? waktuSekarang});
  Future<void> potongKuota();
  Future<void> resetKuotaKeAwal({DateTime? waktuSekarang});
}

class KuotaLocalDataSourceImpl implements KuotaLocalDataSource {
  final DatabaseHelper _dbHelper;
  static const int kuotaMaksimal = 10;

  KuotaLocalDataSourceImpl(this._dbHelper);

  @override
  Future<int> ambilSisaKuota({DateTime? waktuSekarang}) async {
    final db = await _dbHelper.database;
    final sekarang = waktuSekarang ?? DateTime.now();
    final seninPekanIni =
        sekarang.subtract(Duration(days: sekarang.weekday - 1));
    final seninIso = '${seninPekanIni.year.toString().padLeft(4, '0')}-'
        '${seninPekanIni.month.toString().padLeft(2, '0')}-'
        '${seninPekanIni.day.toString().padLeft(2, '0')}';

    // 1. Ambil periode mulai saat ini di database
    final resultPeriode = await db.query(
      'pengaturan',
      columns: ['nilai'],
      where: 'kunci = ?',
      whereArgs: ['kuota_periode_mulai'],
      limit: 1,
    );

    final String? periodeDatabase = resultPeriode.isNotEmpty
        ? resultPeriode.first['nilai'] as String?
        : null;

    // 2. Jika berganti pekan (periode tidak sama dengan Senin pekan berjalan), reset kuota otomatis
    if (periodeDatabase != seninIso) {
      await resetKuotaKeAwal(waktuSekarang: sekarang);
      return kuotaMaksimal;
    }

    // 3. Baca nilai sisa kuota yang tersimpan
    final resultSisa = await db.query(
      'pengaturan',
      columns: ['nilai'],
      where: 'kunci = ?',
      whereArgs: ['kuota_pindai_sisa'],
      limit: 1,
    );

    if (resultSisa.isNotEmpty) {
      final val = resultSisa.first['nilai'] as String?;
      return int.tryParse(val ?? '') ?? kuotaMaksimal;
    }

    return kuotaMaksimal;
  }

  @override
  Future<void> potongKuota() async {
    final sisa = await ambilSisaKuota();
    if (sisa <= 0) return;

    final db = await _dbHelper.database;
    final sisaBaru = sisa - 1;

    await db.update(
      'pengaturan',
      {'nilai': sisaBaru.toString()},
      where: 'kunci = ?',
      whereArgs: ['kuota_pindai_sisa'],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> resetKuotaKeAwal({DateTime? waktuSekarang}) async {
    final db = await _dbHelper.database;
    final sekarang = waktuSekarang ?? DateTime.now();
    final seninPekanIni =
        sekarang.subtract(Duration(days: sekarang.weekday - 1));
    final seninIso = '${seninPekanIni.year.toString().padLeft(4, '0')}-'
        '${seninPekanIni.month.toString().padLeft(2, '0')}-'
        '${seninPekanIni.day.toString().padLeft(2, '0')}';

    await db.transaction((txn) async {
      await txn.update(
        'pengaturan',
        {'nilai': kuotaMaksimal.toString()},
        where: 'kunci = ?',
        whereArgs: ['kuota_pindai_sisa'],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        'pengaturan',
        {'nilai': seninIso},
        where: 'kunci = ?',
        whereArgs: ['kuota_periode_mulai'],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
