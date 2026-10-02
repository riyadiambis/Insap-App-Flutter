import '../../../../core/database/database_helper.dart';
import '../models/kategori_model.dart';

class KategoriLocalDataSource {
  final DatabaseHelper _dbHelper;

  KategoriLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<KategoriModel>> ambilSemua() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kategori',
      orderBy: 'urutan ASC',
    );
    return List.generate(maps.length, (i) {
      return KategoriModel.fromMap(maps[i]);
    });
  }
}
