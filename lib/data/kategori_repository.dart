import 'database_helper.dart';
import 'models/kategori.dart';

class KategoriRepository {
  final DatabaseHelper _dbHelper;

  KategoriRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<Kategori>> ambilSemua() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kategori',
      orderBy: 'urutan ASC',
    );
    return List.generate(maps.length, (i) {
      return Kategori.fromMap(maps[i]);
    });
  }
}
