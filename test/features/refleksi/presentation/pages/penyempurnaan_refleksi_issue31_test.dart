import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/database/database_helper.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/refleksi/data/datasources/refleksi_local_datasource.dart';
import 'package:insap/features/refleksi/domain/entities/refleksi_mingguan_entity.dart';
import 'package:insap/features/refleksi/domain/repositories/refleksi_repository.dart';
import 'package:insap/features/refleksi/domain/usecases/ambil_refleksi_pekan.dart';
import 'package:insap/features/refleksi/domain/usecases/ambil_semua_refleksi.dart';
import 'package:insap/features/refleksi/presentation/pages/halaman_riwayat_refleksi.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeKategoriRepo implements KategoriRepository {
  @override
  Future<List<KategoriEntity>> ambilSemua() async => const [
    KategoriEntity(
      id: 1,
      nama: 'makan',
      ikon: 'restaurant',
      warna: '#E8734A',
      kelompokKakeibo: 'esensial',
      bawaan: 1,
      urutan: 1,
    ),
  ];
}

class _FakeTransaksiRepo implements TransaksiRepository {
  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async =>
      const [];

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftar) async =>
      List.generate(daftar.length, (i) => i + 1);
}

class _FakeRefleksiRepo implements RefleksiRepository {
  final Map<String, RefleksiMingguanEntity> rows = {};
  int? targetPekanDepan;

  @override
  Future<RefleksiMingguanEntity?> ambilPerMinggu(
    int tahun,
    int mingguKe,
  ) async {
    return rows['$tahun-$mingguKe'];
  }

  @override
  Future<List<RefleksiMingguanEntity>> ambilSemuaRefleksi() async {
    final list = rows.values.toList();
    list.sort((a, b) {
      final t = b.tahun.compareTo(a.tahun);
      if (t != 0) return t;
      return b.mingguKe.compareTo(a.mingguKe);
    });
    return list;
  }

  @override
  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi) async {
    final key = '${refleksi.tahun}-${refleksi.mingguKe}';
    final id = rows[key]?.id ?? (rows.length + 1);
    rows[key] = refleksi.copyWith(id: id);
    return id;
  }

  @override
  Future<int?> bacaTargetPekanDepan({int? tahun, int? mingguKe}) async =>
      targetPekanDepan;

  @override
  Future<void> simpanTargetPekanDepan(
    int? target, {
    int? tahunTujuan,
    int? mingguTujuan,
  }) async {
    targetPekanDepan = target;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ISSUE-31: Batas Tahun Refleksi', () {
    test(
      'Batas tahun pekan 1 mengambil pekan terakhir tahun sebelumnya dengan benar',
      () async {
        final fakeRepo = _FakeRefleksiRepo();
        fakeRepo.rows['2025-52'] = const RefleksiMingguanEntity(
          id: 99,
          tahun: 2025,
          mingguKe: 52,
          catatanRefleksi: 'Resolusi hemat tahun baru',
          realisasi: 250000,
          dibuatPada: '2025-12-28T12:00:00',
        );

        final useCase = AmbilRefleksiPekan(
          refleksiRepository: fakeRepo,
          transaksiRepository: _FakeTransaksiRepo(),
          kategoriRepository: _FakeKategoriRepo(),
          sekarang: () => DateTime(2026, 1, 2),
        );

        final hasil = await useCase();
        expect(hasil.tahun, 2026);
        expect(hasil.mingguKe, 1);
        expect(hasil.refleksiPekanLalu, isNotNull);
        expect(hasil.refleksiPekanLalu!.tahun, 2025);
        expect(hasil.refleksiPekanLalu!.mingguKe, 52);
        expect(
          hasil.refleksiPekanLalu!.catatanRefleksi,
          'Resolusi hemat tahun baru',
        );
      },
    );
  });

  group('ISSUE-31: Kunci Lama Target', () {
    test(
      'Nilai lama kunci target_pekan_depan angka polos terbaca aman sebagai null tanpa crash',
      () async {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;

        final db = await openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
            CREATE TABLE pengaturan (
              kunci TEXT PRIMARY KEY,
              nilai TEXT NOT NULL
            );
          ''');
          },
        );

        await db.insert('pengaturan', {
          'kunci': 'target_pekan_depan',
          'nilai': '500000',
        });

        final dbHelper = _TestDatabaseHelper(db);
        final dataSource = RefleksiLocalDataSource(dbHelper: dbHelper);

        final hasil = await dataSource.bacaTargetPekanDepan(
          tahun: 2026,
          mingguKe: 43,
        );
        expect(hasil, isNull);

        final hasilPolos = await dataSource.bacaTargetPekanDepan();
        expect(hasilPolos, isNull);

        await db.close();
      },
    );
  });

  group('ISSUE-31: Riwayat Refleksi', () {
    testWidgets('Menampilkan daftar riwayat refleksi urutan terbaru di atas', (
      tester,
    ) async {
      final fakeRepo = _FakeRefleksiRepo();
      fakeRepo.rows['2026-40'] = const RefleksiMingguanEntity(
        id: 1,
        tahun: 2026,
        mingguKe: 40,
        catatanRefleksi: 'Refleksi lama pekan 40',
        targetPengeluaran: 300000,
        realisasi: 280000,
        dibuatPada: '2026-10-04T10:00:00',
      );
      fakeRepo.rows['2026-41'] = const RefleksiMingguanEntity(
        id: 2,
        tahun: 2026,
        mingguKe: 41,
        catatanRefleksi: 'Refleksi baru pekan 41',
        targetPengeluaran: 350000,
        realisasi: 320000,
        dibuatPada: '2026-10-11T10:00:00',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HalamanRiwayatRefleksi(
            ambilSemuaRefleksi: AmbilSemuaRefleksi(fakeRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('"Refleksi baru pekan 41"'), findsOneWidget);
      expect(find.text('"Refleksi lama pekan 40"'), findsOneWidget);
      expect(find.text('Target: Rp350.000'), findsOneWidget);
      expect(find.text('Realisasi: Rp320.000'), findsOneWidget);
    });

    testWidgets(
      'Menampilkan pesan kosong jika belum ada riwayat tersimpan',
      (tester) async {
        final fakeRepo = _FakeRefleksiRepo();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: HalamanRiwayatRefleksi(
              ambilSemuaRefleksi: AmbilSemuaRefleksi(fakeRepo),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('teks_riwayat_kosong')), findsOneWidget);
        expect(find.text('Belum ada refleksi tersimpan.'), findsOneWidget);
      },
    );
  });
}

class _TestDatabaseHelper implements DatabaseHelper {
  final Database _db;

  _TestDatabaseHelper(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
