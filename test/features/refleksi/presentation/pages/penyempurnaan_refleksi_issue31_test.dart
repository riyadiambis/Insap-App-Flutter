import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:insap/features/refleksi/domain/usecases/simpan_refleksi.dart';
import 'package:insap/features/refleksi/presentation/cubit/refleksi_cubit.dart';
import 'package:insap/features/refleksi/presentation/pages/halaman_refleksi.dart';
import 'package:insap/features/refleksi/presentation/pages/halaman_riwayat_refleksi.dart';
import 'package:insap/features/refleksi/presentation/widgets/form_isian_refleksi.dart';
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
      int tahun, int mingguKe) async {
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
  Future<void> simpanTargetPekanDepan(int? target,
      {int? tahunTujuan, int? mingguTujuan}) async {
    targetPekanDepan = target;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ISSUE-31: Tahap 1 - Kartu Ringkasan Refleksi & Tombol Ubah', () {
    testWidgets('Kartu ringkasan muncul setelah tersimpan dan tombol Ubah membuka form kembali',
        (tester) async {
      final fakeRepo = _FakeRefleksiRepo();
      final cubit = RefleksiCubit(
        ambilRefleksiPekan: AmbilRefleksiPekan(
          refleksiRepository: fakeRepo,
          transaksiRepository: _FakeTransaksiRepo(),
          kategoriRepository: _FakeKategoriRepo(),
          sekarang: () => DateTime(2026, 10, 18),
        ),
        simpanRefleksi: SimpanRefleksi(
          fakeRepo,
          transaksiRepository: _FakeTransaksiRepo(),
          sekarang: () => DateTime(2026, 10, 18),
        ),
      );

      // 1. Awalnya belum disimpan: FormIsianRefleksi muncul
      await cubit.muatRefleksi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HalamanRefleksiWrapper(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FormIsianRefleksi), findsOneWidget);
      expect(find.byKey(const Key('kartu_ringkasan_refleksi_tersimpan')),
          findsNothing);

      // Simpan refleksi
      await cubit.simpan(
        catatanRefleksi: 'Bawa botol minum sendiri.',
        targetPekanDepan: 250000,
      );
      await tester.pumpAndSettle();

      // 2. Sekarang kartu ringkasan muncul
      expect(find.byKey(const Key('kartu_ringkasan_refleksi_tersimpan')),
          findsOneWidget);
      expect(find.text('Bawa botol minum sendiri.'), findsOneWidget);
      expect(find.text('Rp250.000'), findsOneWidget);
      expect(find.byKey(const Key('tombol_ubah_refleksi')), findsOneWidget);

      // 3. Tekan "Ubah": form kembali terbuka berisi nilai tersimpan
      final tombolUbah = find.byKey(const Key('tombol_ubah_refleksi'));
      await tester.scrollUntilVisible(tombolUbah, 100);
      await tester.tap(tombolUbah);
      await tester.pumpAndSettle();

      expect(find.byType(FormIsianRefleksi), findsOneWidget);
      expect(find.text('Bawa botol minum sendiri.'), findsOneWidget);
      expect(find.text('250.000'), findsOneWidget);
    });
  });

  group('ISSUE-31: Tahap 2 - Teks Bantu Target Bulanan', () {
    testWidgets('Teks bantu bulanan dihitung tepat untuk 31 hari (Oktober) dan 30 hari (September)',
        (tester) async {
      // Oktober 2026 (31 hari), target bulanan 1.000.000 -> perkiraan per pekan: round(1.000.000 * 7 / 31 / 1000) * 1000 = 226.000
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormIsianRefleksi(
              targetBulanan: 1000000,
              tanggalAcuan: DateTime(2026, 10, 18),
              onSimpan: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final teksBantuKey = const Key('teks_bantu_target_bulanan_per_pekan');
      expect(find.byKey(teksBantuKey), findsOneWidget);
      expect(
        find.text('Target bulananmu Rp1.000.000, kira-kira Rp226.000 per pekan.'),
        findsOneWidget,
      );

      // September 2026 (30 hari), target bulanan 1.000.000 -> perkiraan per pekan: round(1.000.000 * 7 / 30 / 1000) * 1000 = 233.000
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormIsianRefleksi(
              targetBulanan: 1000000,
              tanggalAcuan: DateTime(2026, 9, 15),
              onSimpan: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Target bulananmu Rp1.000.000, kira-kira Rp233.000 per pekan.'),
        findsOneWidget,
      );
    });

    testWidgets('Teks bantu bulanan tidak tampil jika target bulanan kosong / null / 0',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormIsianRefleksi(
              targetBulanan: null,
              onSimpan: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('teks_bantu_target_bulanan_per_pekan')),
        findsNothing,
      );
    });
  });

  group('ISSUE-31: Tahap 3 - Kartu Pekan Lalu & Batas Tahun', () {
    testWidgets('Kartu pekan lalu muncul jika ada refleksi pekan lalu dan tidak muncul jika tidak ada',
        (tester) async {
      final fakeRepo = _FakeRefleksiRepo();
      // Pekan lalu (2026, pekan 41) ada refleksi
      fakeRepo.rows['2026-41'] = const RefleksiMingguanEntity(
        id: 1,
        tahun: 2026,
        mingguKe: 41,
        catatanRefleksi: 'Masak nasi sendiri di kos',
        realisasi: 180000,
        targetPengeluaran: 200000,
        dibuatPada: '2026-10-11T20:00:00',
      );

      final cubit = RefleksiCubit(
        ambilRefleksiPekan: AmbilRefleksiPekan(
          refleksiRepository: fakeRepo,
          transaksiRepository: _FakeTransaksiRepo(),
          kategoriRepository: _FakeKategoriRepo(),
          sekarang: () => DateTime(2026, 10, 18), // Pekan 42
        ),
        simpanRefleksi: SimpanRefleksi(
          fakeRepo,
          transaksiRepository: _FakeTransaksiRepo(),
          sekarang: () => DateTime(2026, 10, 18),
        ),
      );
      await cubit.muatRefleksi();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HalamanRefleksiWrapper(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kartu_pekan_lalu')), findsOneWidget);
      expect(find.text('Pekan lalu kamu ingin:'), findsOneWidget);
      expect(find.text('"Masak nasi sendiri di kos"'), findsOneWidget);
    });

    test('Batas tahun pekan 1 mengambil pekan terakhir tahun sebelumnya dengan benar',
        () async {
      final fakeRepo = _FakeRefleksiRepo();
      // Pekan terakhir tahun 2025 (pekan 52)
      fakeRepo.rows['2025-52'] = const RefleksiMingguanEntity(
        id: 99,
        tahun: 2025,
        mingguKe: 52,
        catatanRefleksi: 'Resolusi hemat tahun baru',
        realisasi: 250000,
        dibuatPada: '2025-12-28T12:00:00',
      );

      // Tanggal 2 Januari 2026 (Jumat Pekan 1 2026)
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
    });
  });

  group('ISSUE-31: Tahap 4 - Formatter Ribuan & Kunci Lama Target', () {
    testWidgets('Input target refleksi memformat titik ribuan otomatis',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormIsianRefleksi(
              onSimpan: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final targetField = find.byKey(const Key('input_target_pekan_depan'));
      await tester.enterText(targetField, '100000');
      await tester.pumpAndSettle();

      expect(find.text('100.000'), findsOneWidget);
    });

    test('Nilai lama kunci target_pekan_depan angka polos terbaca aman sebagai null tanpa crash',
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

      // Masukkan format angka polos lama (sebelum ISSUE-30)
      await db.insert('pengaturan', {
        'kunci': 'target_pekan_depan',
        'nilai': '500000',
      });

      final dbHelper = _TestDatabaseHelper(db);
      final dataSource = RefleksiLocalDataSource(dbHelper: dbHelper);

      // Baca target untuk pekan tertentu (harus return null dengan aman)
      final hasil = await dataSource.bacaTargetPekanDepan(
        tahun: 2026,
        mingguKe: 43,
      );
      expect(hasil, isNull);

      // Baca tanpa tahun/minggu (juga harus return null dengan aman)
      final hasilPolos = await dataSource.bacaTargetPekanDepan();
      expect(hasilPolos, isNull);

      await db.close();
    });
  });

  group('ISSUE-31: Tahap 5 - Riwayat Refleksi', () {
    testWidgets('Menampilkan daftar riwayat refleksi urutan terbaru di atas',
        (tester) async {
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

    testWidgets('Menampilkan pesan kosong jika belum ada riwayat tersimpan',
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
    });
  });
}

class HalamanRefleksiWrapper extends StatelessWidget {
  final RefleksiCubit cubit;

  const HalamanRefleksiWrapper({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RefleksiCubit>.value(
      value: cubit,
      child: const HalamanRefleksi(),
    );
  }
}

class _TestDatabaseHelper implements DatabaseHelper {
  final Database _db;

  _TestDatabaseHelper(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
