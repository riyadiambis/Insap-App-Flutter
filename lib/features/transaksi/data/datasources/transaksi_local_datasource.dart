import '../../../../data/database_helper.dart';
import '../models/transaksi_model.dart';

class TransaksiLocalDataSource {
  final DatabaseHelper _dbHelper;

  TransaksiLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> simpan(TransaksiModel transaksi) async {
    final db = await _dbHelper.database;
    final map = transaksi.toMap();
    if (transaksi.dibuatPada.isEmpty) {
      map['dibuat_pada'] = DateTime.now().toIso8601String();
    }
    return await db.insert('transaksi', map);
  }

  Future<List<TransaksiModel>> ambilTerakhir(int batas) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      orderBy: 'dibuat_pada DESC',
      limit: batas,
    );
    return List.generate(maps.length, (i) {
      return TransaksiModel.fromMap(maps[i]);
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

  /// Ambil daftar transaksi dengan saringan rentang tanggal dan kategori,
  /// keduanya opsional. Memakai idx_transaksi_tanggal dan
  /// idx_transaksi_kategori lewat klausa WHERE, bukan menyaring di memori.
  Future<List<TransaksiModel>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    final db = await _dbHelper.database;
    final List<String> kondisi = [];
    final List<Object?> args = [];

    if (tanggalMulai != null && tanggalAkhir != null) {
      kondisi.add('tanggal BETWEEN ? AND ?');
      args.add(tanggalMulai);
      args.add(tanggalAkhir);
    }
    if (kategoriId != null) {
      kondisi.add('kategori_id = ?');
      args.add(kategoriId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      where: kondisi.isEmpty ? null : kondisi.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'tanggal DESC, dibuat_pada DESC',
    );
    return List.generate(maps.length, (i) {
      return TransaksiModel.fromMap(maps[i]);
    });
  }

  Future<TransaksiModel?> ambilSatu(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TransaksiModel.fromMap(maps.first);
  }

  Future<int> hapus(int id) async {
    final db = await _dbHelper.database;
    return db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }
}
