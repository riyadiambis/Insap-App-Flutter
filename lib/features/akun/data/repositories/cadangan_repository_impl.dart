import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/cadangan_info.dart';
import '../../domain/entities/rencana_cadangan.dart';
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

  static const pesanPerangkatKosong =
      'Perangkat ini belum berisi transaksi maupun refleksi, sedangkan awan '
      'masih menyimpan cadangan. Pulihkan data dulu agar cadangan tidak terhapus.';

  static const pesanPerangkatTidakKosong =
      'Data di perangkat ini masih ada. Pemulihan hanya untuk perangkat kosong, supaya data barumu tidak tertimpa.';

  /// Menghitung ID dokumen di awan yang sudah tidak ada di lokal (mencegah data hantu).
  static Set<String> cariDokumenUsang({
    required Iterable<String> idAwan,
    required Iterable<String> idLokal,
  }) {
    final setLokal = idLokal.toSet();
    return idAwan.where((id) => !setLokal.contains(id)).toSet();
  }

  /// Membandingkan isi dokumen awan dengan baris lokal ber-ID sama.
  static bool isiSama(Map<String, dynamic> awan, Map<String, Object?> lokal) {
    if (awan.length != lokal.length) return false;
    for (final kolom in lokal.entries) {
      if (!awan.containsKey(kolom.key) || awan[kolom.key] != kolom.value) {
        return false;
      }
    }
    return true;
  }

  static SelisihKoleksi hitungSelisih({
    required List<Map<String, Object?>> lokal,
    required Map<String, Map<String, dynamic>> awan,
  }) {
    final lokalPerId = {
      for (final baris in lokal) baris['id'].toString(): baris,
    };
    final usang = cariDokumenUsang(idAwan: awan.keys, idLokal: lokalPerId.keys);
    var ditimpa = 0;
    awan.forEach((id, isi) {
      final baris = lokalPerId[id];
      if (baris != null && !isiSama(isi, baris)) ditimpa++;
    });
    return SelisihKoleksi(
      jumlahLokal: lokal.length,
      jumlahAwan: awan.length,
      akanDihapus: usang.length,
      akanDitimpa: ditimpa,
    );
  }

  Future<_DataCadangan> _muatData(String uid) async {
    final db = await _databaseHelper.database;
    final docPengguna = _firestore.collection('pengguna').doc(uid);
    return _DataCadangan(
      kategori: await db.query('kategori'),
      transaksi: await db.query('transaksi'),
      refleksi: await db.query('refleksi_mingguan'),
      kategoriAwan: await docPengguna.collection('kategori').get(),
      transaksiAwan: await docPengguna.collection('transaksi').get(),
      refleksiAwan: await docPengguna.collection('refleksi').get(),
    );
  }

  RencanaCadangan _susunRencana(_DataCadangan data) {
    Map<String, Map<String, dynamic>> isiAwan(
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) => {for (final doc in snapshot.docs) doc.id: doc.data()};

    return RencanaCadangan(
      transaksi: hitungSelisih(
        lokal: data.transaksi,
        awan: isiAwan(data.transaksiAwan),
      ),
      kategori: hitungSelisih(
        lokal: data.kategori,
        awan: isiAwan(data.kategoriAwan),
      ),
      refleksi: hitungSelisih(
        lokal: data.refleksi,
        awan: isiAwan(data.refleksiAwan),
      ),
    );
  }

  @override
  Future<RencanaCadangan> siapkanCadangan(String uid) async {
    return _susunRencana(await _muatData(uid));
  }

  @override
  Future<void> cadangkanData(String uid) async {
    final data = await _muatData(uid);
    // Pengaman di lapisan data: perangkat kosong tidak boleh mengosongkan awan
    if (_susunRencana(data).ditolak) {
      throw Exception(pesanPerangkatKosong);
    }

    final daftarKategori = data.kategori;
    final daftarTransaksi = data.transaksi;
    final daftarRefleksi = data.refleksi;
    final snapshotKategoriAwan = data.kategoriAwan;
    final snapshotTransaksiAwan = data.transaksiAwan;
    final snapshotRefleksiAwan = data.refleksiAwan;

    final docPengguna = _firestore.collection('pengguna').doc(uid);

    final localKategoriIds = daftarKategori
        .map((k) => k['id'].toString())
        .toSet();
    final localTransaksiIds = daftarTransaksi
        .map((t) => t['id'].toString())
        .toSet();
    final localRefleksiIds = daftarRefleksi
        .map((r) => r['id'].toString())
        .toSet();

    WriteBatch batch = _firestore.batch();
    int count = 0;

    Future<void> commitJikaPenuh() async {
      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    // 1. Hapus dokumen di awan yang sudah tidak ada lagi di lokal (cegah data hantu)
    final idKategoriUsang = cariDokumenUsang(
      idAwan: snapshotKategoriAwan.docs.map((d) => d.id),
      idLokal: localKategoriIds,
    );
    for (final doc in snapshotKategoriAwan.docs) {
      if (idKategoriUsang.contains(doc.id)) {
        batch.delete(doc.reference);
        count++;
        await commitJikaPenuh();
      }
    }

    final idTransaksiUsang = cariDokumenUsang(
      idAwan: snapshotTransaksiAwan.docs.map((d) => d.id),
      idLokal: localTransaksiIds,
    );
    for (final doc in snapshotTransaksiAwan.docs) {
      if (idTransaksiUsang.contains(doc.id)) {
        batch.delete(doc.reference);
        count++;
        await commitJikaPenuh();
      }
    }

    final idRefleksiUsang = cariDokumenUsang(
      idAwan: snapshotRefleksiAwan.docs.map((d) => d.id),
      idLokal: localRefleksiIds,
    );
    for (final doc in snapshotRefleksiAwan.docs) {
      if (idRefleksiUsang.contains(doc.id)) {
        batch.delete(doc.reference);
        count++;
        await commitJikaPenuh();
      }
    }

    // 2. Subkoleksi kategori
    for (final kat in daftarKategori) {
      final ref = docPengguna.collection('kategori').doc(kat['id'].toString());
      batch.set(ref, Map<String, dynamic>.from(kat), SetOptions(merge: true));
      count++;
      await commitJikaPenuh();
    }

    // 3. Subkoleksi transaksi
    for (final trx in daftarTransaksi) {
      final ref = docPengguna.collection('transaksi').doc(trx['id'].toString());
      batch.set(ref, Map<String, dynamic>.from(trx), SetOptions(merge: true));
      count++;
      await commitJikaPenuh();
    }

    // 4. Subkoleksi refleksi
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

    // 5. Dokumen induk pengguna
    batch.set(docPengguna, {
      'cadangan_terakhir': FieldValue.serverTimestamp(),
      'jumlah_transaksi': daftarTransaksi.length,
      'jumlah_kategori': daftarKategori.length,
      'jumlah_refleksi': daftarRefleksi.length,
    }, SetOptions(merge: true));
    count++;
    await commitJikaPenuh();

    if (count > 0) {
      await batch.commit();
    }
  }

  @override
  Future<CadanganInfo> pulihkanData(String uid) async {
    final db = await _databaseHelper.database;
    final transaksiLokal = await db.query('transaksi');
    final refleksiLokal = await db.query('refleksi_mingguan');
    if (transaksiLokal.isNotEmpty || refleksiLokal.isNotEmpty) {
      throw const PerangkatTidakKosongException();
    }

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

class _DataCadangan {
  final List<Map<String, Object?>> kategori;
  final List<Map<String, Object?>> transaksi;
  final List<Map<String, Object?>> refleksi;
  final QuerySnapshot<Map<String, dynamic>> kategoriAwan;
  final QuerySnapshot<Map<String, dynamic>> transaksiAwan;
  final QuerySnapshot<Map<String, dynamic>> refleksiAwan;

  const _DataCadangan({
    required this.kategori,
    required this.transaksi,
    required this.refleksi,
    required this.kategoriAwan,
    required this.transaksiAwan,
    required this.refleksiAwan,
  });
}
