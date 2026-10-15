import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';

class PengaturanLocalDataSource {
  final DatabaseHelper _dbHelper;

  PengaturanLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<String?> baca(String kunci) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'pengaturan',
      columns: ['nilai'],
      where: 'kunci = ?',
      whereArgs: [kunci],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['nilai'] as String?;
    }
    return null;
  }

  Future<void> simpan(String kunci, String nilai) async {
    final db = await _dbHelper.database;
    await db.insert(
      'pengaturan',
      {'kunci': kunci, 'nilai': nilai},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
