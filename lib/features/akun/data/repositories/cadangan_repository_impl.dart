import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/cadangan_info.dart';
import '../../domain/repositories/cadangan_repository.dart';

class CadanganRepositoryImpl implements CadanganRepository {
  final FirebaseFirestore _firestore;
  final DatabaseHelper _databaseHelper;

  CadanganRepositoryImpl({
    FirebaseFirestore? firestore,
    DatabaseHelper? databaseHelper,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _databaseHelper = databaseHelper ?? DatabaseHelper();

  @override
  Stream<CadanganInfo?> pantauCadanganTerakhir(String uid) {
    return _firestore.collection('pengguna').doc(uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = snapshot.data()!;
      final ts = data['cadangan_terakhir'] as Timestamp?;
      return CadanganInfo(
        waktuCadanganTerakhir: ts?.toDate(),
        jumlahTransaksi: (data['jumlah_transaksi'] as num?)?.toInt() ?? 0,
        jumlahKategori: (data['jumlah_kategori'] as num?)?.toInt() ?? 0,
        jumlahRefleksi: (data['jumlah_refleksi'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<CadanganInfo?> ambilCadanganTerakhir(String uid) async {
    final doc = await _firestore.collection('pengguna').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    final ts = data['cadangan_terakhir'] as Timestamp?;
    return CadanganInfo(
      waktuCadanganTerakhir: ts?.toDate(),
      jumlahTransaksi: (data['jumlah_transaksi'] as num?)?.toInt() ?? 0,
      jumlahKategori: (data['jumlah_kategori'] as num?)?.toInt() ?? 0,
      jumlahRefleksi: (data['jumlah_refleksi'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> cadangkanData(String uid) async {
    final db = await _databaseHelper.database;
    final daftarKategori = await db.query('kategori');
    final daftarTransaksi = await db.query('transaksi');
    final daftarRefleksi = await db.query('refleksi_mingguan');

    final docPengguna = _firestore.collection('pengguna').doc(uid);

    WriteBatch batch = _firestore.batch();
    int count = 0;

    Future<void> commitJikaPenuh() async {
      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    // Dokumen induk pengguna
    batch.set(docPengguna, {
      'cadangan_terakhir': FieldValue.serverTimestamp(),
      'jumlah_transaksi': daftarTransaksi.length,
      'jumlah_kategori': daftarKategori.length,
      'jumlah_refleksi': daftarRefleksi.length,
    }, SetOptions(merge: true));
    count++;
    await commitJikaPenuh();

    // Subkoleksi kategori
    for (final kat in daftarKategori) {
      final ref = docPengguna.collection('kategori').doc(kat['id'].toString());
      batch.set(ref, Map<String, dynamic>.from(kat), SetOptions(merge: true));
      count++;
      await commitJikaPenuh();
    }

    // Subkoleksi transaksi
    for (final trx in daftarTransaksi) {
      final ref = docPengguna.collection('transaksi').doc(trx['id'].toString());
      batch.set(ref, Map<String, dynamic>.from(trx), SetOptions(merge: true));
      count++;
      await commitJikaPenuh();
    }

    // Subkoleksi refleksi
    for (final refData in daftarRefleksi) {
      final ref = docPengguna
          .collection('refleksi')
          .doc(refData['id'].toString());
      batch.set(
        ref,
        Map<String, dynamic>.from(refData),
        SetOptions(merge: true),
      );
      count++;
      await commitJikaPenuh();
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  @override
  Future<CadanganInfo> pulihkanData(String uid) async {
    final docPengguna = _firestore.collection('pengguna').doc(uid);
    final snapshotPengguna = await docPengguna.get();

    if (!snapshotPengguna.exists || snapshotPengguna.data() == null) {
      throw Exception('Belum ada data cadangan di akun ini.');
    }

    final dataInduk = snapshotPengguna.data()!;
    final ts = dataInduk['cadangan_terakhir'] as Timestamp?;
    final infoCadangan = CadanganInfo(
      waktuCadanganTerakhir: ts?.toDate(),
      jumlahTransaksi: (dataInduk['jumlah_transaksi'] as num?)?.toInt() ?? 0,
      jumlahKategori: (dataInduk['jumlah_kategori'] as num?)?.toInt() ?? 0,
      jumlahRefleksi: (dataInduk['jumlah_refleksi'] as num?)?.toInt() ?? 0,
    );

    // Ambil data subkoleksi dari Firestore
    final snapshotKategori = await docPengguna.collection('kategori').get();
    final snapshotTransaksi = await docPengguna.collection('transaksi').get();
    final snapshotRefleksi = await docPengguna.collection('refleksi').get();

    final db = await _databaseHelper.database;

    // Transaksi pemulihan lokal (atomik dan referensial)
    await db.transaction((txn) async {
      // 1. Hapus transaksi terlebih dahulu (menjaga foreign key kategori)
      await txn.delete('transaksi');

      // 2. Pulihkan kategori
      if (snapshotKategori.docs.isNotEmpty) {
        await txn.delete('kategori');
        for (final doc in snapshotKategori.docs) {
          await txn.insert(
            'kategori',
            Map<String, dynamic>.from(doc.data()),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // 3. Pulihkan transaksi
      for (final doc in snapshotTransaksi.docs) {
        await txn.insert(
          'transaksi',
          Map<String, dynamic>.from(doc.data()),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 4. Pulihkan refleksi
      await txn.delete('refleksi_mingguan');
      for (final doc in snapshotRefleksi.docs) {
        await txn.insert(
          'refleksi_mingguan',
          Map<String, dynamic>.from(doc.data()),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return infoCadangan;
  }
}
