import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'seed_kategori.dart';
import 'seed_pengaturan.dart';
import 'models/kategori.dart';
import 'models/pengaturan.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'insap.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE kategori (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          nama            TEXT    NOT NULL UNIQUE,
          ikon            TEXT    NOT NULL,
          warna           TEXT    NOT NULL,
          kelompok_kakeibo TEXT   NOT NULL,
          bawaan          INTEGER NOT NULL DEFAULT 0,
          urutan          INTEGER NOT NULL DEFAULT 0,

          CHECK (kelompok_kakeibo IN ('esensial','opsional','hiburan','ekstra')),
          CHECK (bawaan IN (0,1))
      )
    ''');

    await db.execute('''
      CREATE TABLE transaksi (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          jumlah          INTEGER NOT NULL,
          kategori_id     INTEGER NOT NULL,
          tanggal         TEXT    NOT NULL,
          catatan         TEXT,
          tipe_kebutuhan  TEXT,
          sumber          TEXT    NOT NULL DEFAULT 'manual',
          nama_toko       TEXT,
          dibuat_pada     TEXT    NOT NULL,

          FOREIGN KEY (kategori_id) REFERENCES kategori(id) ON DELETE RESTRICT,
          CHECK (jumlah > 0),
          CHECK (tipe_kebutuhan IS NULL OR tipe_kebutuhan IN ('butuh','pengen')),
          CHECK (sumber IN ('manual','pindai'))
      )
    ''');

    await db.execute('CREATE INDEX idx_transaksi_tanggal  ON transaksi(tanggal)');
    await db.execute('CREATE INDEX idx_transaksi_kategori ON transaksi(kategori_id)');

    await db.execute('''
      CREATE TABLE refleksi_mingguan (
          id                  INTEGER PRIMARY KEY AUTOINCREMENT,
          tahun               INTEGER NOT NULL,
          minggu_ke           INTEGER NOT NULL,
          target_pengeluaran  INTEGER,
          realisasi           INTEGER NOT NULL,
          catatan_refleksi    TEXT,
          dibuat_pada         TEXT    NOT NULL,

          UNIQUE (tahun, minggu_ke),
          CHECK (minggu_ke BETWEEN 1 AND 53)
      )
    ''');

    await db.execute('''
      CREATE TABLE pengaturan (
          kunci   TEXT PRIMARY KEY,
          nilai   TEXT NOT NULL
      )
    ''');

    for (Kategori kategori in seedKategori) {
      await db.insert('kategori', kategori.toMap());
    }

    for (Pengaturan pengaturan in buatSeedPengaturan()) {
      await db.insert('pengaturan', pengaturan.toMap());
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Siap untuk migrasi selanjutnya
  }
}
