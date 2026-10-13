import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/database/database_helper.dart';
import 'package:insap/core/database/seed_kategori.dart';
import 'package:insap/features/akun/data/repositories/cadangan_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Menguji alur cadangkanData, siapkanCadangan, dan pulihkanData yang asli:
/// Firestore diganti FakeFirebaseFirestore, SQLite memakai DatabaseHelper asli
/// (skema, seed kategori, foreign key, AUTOINCREMENT) lewat sqflite_common_ffi.
void main() {
  const uid = 'uid-uji';
  late Directory folderSementara;
  late Database db;
  late FakeFirebaseFirestore firestore;
  late CadanganRepositoryImpl repo;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    folderSementara = await Directory.systemTemp.createTemp('insap_cadangan_');
    await databaseFactory.setDatabasesPath(folderSementara.path);
    db = await DatabaseHelper().database;
  });

  tearDownAll(() async {
    await db.close();
    await folderSementara.delete(recursive: true);
  });

  /// Mengembalikan SQLite ke kondisi instalasi baru, termasuk penghitung ID.
  Future<void> pasangUlangAplikasi() async {
    await db.delete('transaksi');
    await db.delete('refleksi_mingguan');
    await db.delete('kategori');
    await db.delete('sqlite_sequence');
    for (final kategori in seedKategori) {
      await db.insert('kategori', kategori.toMap());
    }
  }

  Future<int> tambahTransaksi({int jumlah = 15000, String catatan = 'jajan'}) {
    return db.insert('transaksi', {
      'jumlah': jumlah,
      'kategori_id': 1,
      'tanggal': '2026-10-14',
      'catatan': catatan,
      'dibuat_pada': '2026-10-14T08:00:00.000',
    });
  }

  Future<int> tambahRefleksi(int mingguKe) {
    return db.insert('refleksi_mingguan', {
      'tahun': 2026,
      'minggu_ke': mingguKe,
      'realisasi': 300000,
      'dibuat_pada': '2026-10-14T08:00:00.000',
    });
  }

  Future<Set<String>> idAwan(String koleksi) async {
    final snapshot = await firestore
        .collection('pengguna')
        .doc(uid)
        .collection(koleksi)
        .get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  Future<Set<int>> idLokal(String tabel) async {
    final baris = await db.query(tabel, columns: ['id']);
    return baris.map((b) => b['id'] as int).toSet();
  }

  setUp(() async {
    await pasangUlangAplikasi();
    firestore = FakeFirebaseFirestore();
    repo = CadanganRepositoryImpl(
      firestore: firestore,
      databaseHelper: DatabaseHelper(),
    );
  });

  group('cadangkanData dan pulihkanData (alur asli)', () {
    test(
      'transaksi yang dihapus lokal tidak muncul lagi setelah pulihkan',
      () async {
        await tambahTransaksi(catatan: 'satu');
        final idDihapus = await tambahTransaksi(catatan: 'dua');
        await tambahTransaksi(catatan: 'tiga');
        await tambahRefleksi(41);
        await repo.cadangkanData(uid);
        expect(await idAwan('transaksi'), {'1', '2', '3'});

        await db.delete('transaksi', where: 'id = ?', whereArgs: [idDihapus]);
        await repo.cadangkanData(uid);
        expect(await idAwan('transaksi'), {'1', '3'});

        // Data lokal hilang, lalu dipulihkan dari awan
        await db.delete('transaksi');
        final info = await repo.pulihkanData(uid);

        expect(await idLokal('transaksi'), {1, 3});
        expect(await idLokal('refleksi_mingguan'), {1});
        expect(info.jumlahTransaksi, 2);
        expect(info.jumlahRefleksi, 1);
        expect(info.jumlahKategori, seedKategori.length);
      },
    );

    test('pulihkanData mengembalikan isi transaksi persis seperti saat dicadangkan', () async {
      await tambahTransaksi(jumlah: 45000, catatan: 'makan siang');
      final sebelum = await db.query('transaksi');
      await repo.cadangkanData(uid);

      await pasangUlangAplikasi();
      await repo.pulihkanData(uid);

      expect(await db.query('transaksi'), sebelum);
    });
  });

  group('Pengaman perangkat kosong', () {
    test(
      'cadangkanData ditolak dan awan tetap utuh setelah pasang ulang',
      () async {
        await tambahTransaksi();
        await tambahTransaksi();
        await tambahRefleksi(40);
        await repo.cadangkanData(uid);

        await pasangUlangAplikasi();

        final rencana = await repo.siapkanCadangan(uid);
        expect(rencana.perangkatKosong, isTrue);
        expect(rencana.ditolak, isTrue);
        expect(rencana.transaksi.jumlahAwan, 2);
        expect(rencana.refleksi.jumlahAwan, 1);

        await expectLater(
          repo.cadangkanData(uid),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'pesan',
              contains('Pulihkan data dulu'),
            ),
          ),
        );
        expect(await idAwan('transaksi'), {'1', '2'});
        expect(await idAwan('refleksi'), {'1'});
      },
    );

    test(
      'perangkat kosong boleh dicadangkan bila awan juga masih kosong',
      () async {
        final rencana = await repo.siapkanCadangan(uid);
        expect(rencana.ditolak, isFalse);
        expect(rencana.perluKonfirmasi, isFalse);

        await repo.cadangkanData(uid);
        expect(await idAwan('kategori'), hasLength(seedKategori.length));
      },
    );
  });

  group('Rencana cadangan (dialog konfirmasi)', () {
    test('pasang ulang + 1 transaksi baru: ID mulai dari 1, rencana menghitung yang dihapus dan ditimpa', () async {
      await tambahTransaksi(catatan: 'lama 1');
      await tambahTransaksi(catatan: 'lama 2');
      await tambahTransaksi(catatan: 'lama 3');
      await tambahRefleksi(41);
      await repo.cadangkanData(uid);

      await pasangUlangAplikasi();
      final idBaru = await tambahTransaksi(jumlah: 9000, catatan: 'baru');
      expect(idBaru, 1, reason: 'AUTOINCREMENT mulai lagi dari 1');

      final rencana = await repo.siapkanCadangan(uid);
      expect(rencana.ditolak, isFalse);
      expect(rencana.perluKonfirmasi, isTrue);
      expect(rencana.transaksi.akanDihapus, 2);
      expect(rencana.transaksi.akanDitimpa, 1);
      expect(rencana.refleksi.akanDihapus, 1);
      expect(rencana.kategori.akanDihapus, 0);
      expect(rencana.kategori.akanDitimpa, 0);
      expect(rencana.totalDihapus, 3);
      expect(rencana.totalDitimpa, 1);
    });

    test('hanya penambahan data baru tidak butuh konfirmasi', () async {
      await tambahTransaksi();
      await tambahRefleksi(41);
      await repo.cadangkanData(uid);

      final tanpaPerubahan = await repo.siapkanCadangan(uid);
      expect(tanpaPerubahan.perluKonfirmasi, isFalse);

      await tambahTransaksi();
      await tambahRefleksi(42);
      final rencana = await repo.siapkanCadangan(uid);
      expect(rencana.perluKonfirmasi, isFalse);
      expect(rencana.transaksi.jumlahLokal, 2);
      expect(rencana.transaksi.jumlahAwan, 1);
    });

    test('transaksi yang diubah lokal terhitung akan ditimpa', () async {
      final id = await tambahTransaksi(jumlah: 10000);
      await repo.cadangkanData(uid);

      await db.update(
        'transaksi',
        {'jumlah': 12000},
        where: 'id = ?',
        whereArgs: [id],
      );

      final rencana = await repo.siapkanCadangan(uid);
      expect(rencana.perluKonfirmasi, isTrue);
      expect(rencana.transaksi.akanDitimpa, 1);
      expect(rencana.totalDihapus, 0);
    });
  });
}
