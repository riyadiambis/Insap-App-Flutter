import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/refleksi_mingguan_model.dart';

class RefleksiLocalDataSource {
  static const String kunciTargetPekanDepan = 'target_pekan_depan';

  final DatabaseHelper _dbHelper;

  RefleksiLocalDataSource({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<RefleksiMingguanModel?> ambilPerMinggu(int tahun, int mingguKe) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'refleksi_mingguan',
      where: 'tahun = ? AND minggu_ke = ?',
      whereArgs: [tahun, mingguKe],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return RefleksiMingguanModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<RefleksiMingguanModel>> ambilSemuaRefleksi() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'refleksi_mingguan',
      orderBy: 'tahun DESC, minggu_ke DESC',
    );
    return maps.map((m) => RefleksiMingguanModel.fromMap(m)).toList();
  }

  // simpan baris baru atau perbarui baris pekan berjalan supaya tidak ada entri ganda
  Future<int> simpanAtauPerbarui(RefleksiMingguanModel refleksi) async {
    final db = await _dbHelper.database;
    final existing = await ambilPerMinggu(refleksi.tahun, refleksi.mingguKe);

    final dibuatPada = refleksi.dibuatPada.isEmpty
        ? DateTime.now().toIso8601String()
        : refleksi.dibuatPada;

    if (existing != null) {
      await db.update(
        'refleksi_mingguan',
        {
          'target_pengeluaran':
              refleksi.targetPengeluaran ?? existing.targetPengeluaran,
          'realisasi': refleksi.realisasi,
          'catatan_refleksi': refleksi.catatanRefleksi,
          'dibuat_pada': dibuatPada,
        },
        where: 'tahun = ? AND minggu_ke = ?',
        whereArgs: [refleksi.tahun, refleksi.mingguKe],
      );
      return existing.id ?? 1;
    }

    final map = refleksi.toMap();
    if (map['id'] == null) {
      map.remove('id');
    }
    map['dibuat_pada'] = dibuatPada;

    return await db.insert(
      'refleksi_mingguan',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> bacaTargetPekanDepan({int? tahun, int? mingguKe}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'pengaturan',
      columns: ['nilai'],
      where: 'kunci = ?',
      whereArgs: [kunciTargetPekanDepan],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final raw = maps.first['nilai'] as String?;
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();

    // Format target bersama pekan tujuannya: "tahun-minggu:nominal" (contoh "2026-43:500000")
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length == 2) {
        final tahunMinggu = parts[0];
        final target = int.tryParse(parts[1]);
        if (target == null || target <= 0) return null;
        if (tahun != null && mingguKe != null) {
          if (tahunMinggu == '$tahun-$mingguKe') {
            return target;
          }
          // Target disimpan bukan untuk pekan yang diminta (misal terlewat 1 pekan)
          return null;
        }
        return target;
      }
    }

    // Nilai lama yang berformat angka saja (sebelum ISSUE-30) terbaca aman sebagai null (tidak ada target)
    return null;
  }

  Future<void> simpanTargetPekanDepan(
    int? target, {
    int? tahunTujuan,
    int? mingguTujuan,
  }) async {
    final db = await _dbHelper.database;
    if (target == null || target <= 0 || tahunTujuan == null || mingguTujuan == null) {
      await db.delete(
        'pengaturan',
        where: 'kunci = ?',
        whereArgs: [kunciTargetPekanDepan],
      );
      return;
    }

    final nilai = '$tahunTujuan-$mingguTujuan:$target';
    await db.insert('pengaturan', {
      'kunci': kunciTargetPekanDepan,
      'nilai': nilai,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
