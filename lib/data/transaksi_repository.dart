import 'database_helper.dart';
import 'models/transaksi.dart';

class TransaksiRepository {
  final DatabaseHelper _dbHelper;

  TransaksiRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> simpan(Transaksi transaksi) async {
    final db = await _dbHelper.database;
    final map = transaksi.toMap();
    if (transaksi.dibuatPada.isEmpty) {
      map['dibuat_pada'] = DateTime.now().toIso8601String();
    }
    return await db.insert('transaksi', map);
  }

  Future<List<Transaksi>> ambilTerakhir(int batas) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      orderBy: 'dibuat_pada DESC',
      limit: batas,
    );
    return List.generate(maps.length, (i) {
      return Transaksi.fromMap(maps[i]);
    });
  }

  Future<int> totalRentang(String tanggalMulai, String tanggalAkhir) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(jumlah) as total
      FROM transaksi
      WHERE tanggal BETWEEN ? AND ?
      ''',
      [tanggalMulai, tanggalAkhir],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toInt();
    }
    return 0;
  }

  Future<int> totalMingguIni(String tanggalMulai, String tanggalAkhir) {
    return totalRentang(tanggalMulai, tanggalAkhir);
  }

  Future<int> ambilKuotaPindai() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'pengaturan',
      columns: ['nilai'],
      where: 'kunci = ?',
      whereArgs: ['kuota_pindai_sisa'],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final val = result.first['nilai'] as String?;
      return int.tryParse(val ?? '') ?? 0;
    }
    return 10;
  }
}
