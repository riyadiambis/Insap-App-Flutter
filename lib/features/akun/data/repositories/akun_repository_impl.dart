import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/pengguna_entity.dart';
import '../../domain/repositories/akun_repository.dart';
import 'cadangan_repository_impl.dart';

class AkunRepositoryImpl implements AkunRepository {
  final FirebaseAuth _firebaseAuth;
  final DatabaseHelper _databaseHelper;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore? _firestoreSuntikan;

  AkunRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    DatabaseHelper? databaseHelper,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _databaseHelper = databaseHelper ?? DatabaseHelper(),
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestoreSuntikan = firestore;

  /// Firebase menolak hapus akun bila sesi masuk lebih lama dari ini.
  static const batasMasukTerbaru = Duration(minutes: 5);

  static const pesanPerluMasukUlang =
      'Demi keamanan, keluar lalu masuk lagi, kemudian ulangi Hapus Akun.';

  /// Benar bila [terakhirMasuk] masih cukup baru untuk menghapus akun.
  static bool masukMasihBaru(DateTime? terakhirMasuk, DateTime sekarang) {
    if (terakhirMasuk == null) return false;
    return sekarang.difference(terakhirMasuk) < batasMasukTerbaru;
  }

  PenggunaEntity _kePenggunaEntity(User user) {
    return PenggunaEntity(
      uid: user.uid,
      email: user.email,
      namaTampilan: user.displayName,
      fotoUrl: user.photoURL,
    );
  }

  @override
  Stream<PenggunaEntity?> pantauPengguna() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return _kePenggunaEntity(user);
    });
  }

  @override
  Future<PenggunaEntity?> ambilPenggunaSaatIni() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _kePenggunaEntity(user);
  }

  @override
  Future<PenggunaEntity> daftarDenganEmail({
    required String email,
    required String kataSandi,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: kataSandi,
      );
      final user = credential.user!;
      await _simpanUidKeLokal(user.uid);
      return _kePenggunaEntity(user);
    } on FirebaseAuthException catch (e) {
      throw _terjemahkanPesanGalat(e);
    }
  }

  @override
  Future<PenggunaEntity> masukDenganEmail({
    required String email,
    required String kataSandi,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: kataSandi,
      );
      final user = credential.user!;
      await _simpanUidKeLokal(user.uid);
      return _kePenggunaEntity(user);
    } on FirebaseAuthException catch (e) {
      throw _terjemahkanPesanGalat(e);
    }
  }

  @override
  Future<void> keluar() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Abaikan jika tidak login via Google
    }
    await _firebaseAuth.signOut();
    await _hapusUidDariLokal();
  }

  @override
  Future<void> kirimResetKataSandi(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _terjemahkanPesanGalat(e);
    }
  }

  @override
  Future<PenggunaEntity?> masukDenganGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user != null) {
        await _simpanUidKeLokal(user.uid);
        return _kePenggunaEntity(user);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _terjemahkanPesanGalat(e);
    } catch (e) {
      throw 'Gagal masuk dengan Google: ${e.toString()}';
    }
  }

  @override
  Future<void> hapusAkun() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw 'Tidak ada akun yang sedang masuk.';
    }
    // Dicek sebelum menghapus apa pun, supaya data awan tidak terhapus
    // sementara akunnya gagal dihapus.
    if (!masukMasihBaru(user.metadata.lastSignInTime, DateTime.now())) {
      throw pesanPerluMasukUlang;
    }
    try {
      await CadanganRepositoryImpl.hapusDataAwan(
        _firestoreSuntikan ?? FirebaseFirestore.instance,
        user.uid,
      );
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') throw pesanPerluMasukUlang;
      throw _terjemahkanPesanGalat(e);
    } on FirebaseException catch (e) {
      throw 'Gagal menghapus data cadangan: ${e.message ?? e.code}';
    }
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // Abaikan jika tidak login via Google
    }
    await _hapusUidDariLokal();
  }

  Future<void> _simpanUidKeLokal(String uid) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert('pengaturan', {
        'kunci': 'uid_pengguna',
        'nilai': uid,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      // Penyimpanan lokal bersifat pelengkap, jangan gagalkan autentikasi
    }
  }

  Future<void> _hapusUidDariLokal() async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'pengaturan',
        where: 'kunci = ?',
        whereArgs: ['uid_pengguna'],
      );
    } catch (_) {
      // Abaikan jika tabel atau entri tidak ada
    }
  }

  String _terjemahkanPesanGalat(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun dengan surel ini belum terdaftar.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Surel atau kata sandi tidak cocok.';
      case 'email-already-in-use':
        return 'Surel ini sudah digunakan oleh akun lain.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Minimal 6 karakter.';
      case 'invalid-email':
        return 'Format surel tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan masuk. Coba lagi beberapa saat lagi.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      default:
        return e.message ?? 'Terjadi kesalahan saat memproses akun.';
    }
  }
}
