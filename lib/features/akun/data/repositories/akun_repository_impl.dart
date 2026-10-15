import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/pengguna_entity.dart';
import '../../domain/repositories/akun_repository.dart';

class AkunRepositoryImpl implements AkunRepository {
  final FirebaseAuth _firebaseAuth;
  final DatabaseHelper _databaseHelper;
  final GoogleSignIn _googleSignIn;

  AkunRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    DatabaseHelper? databaseHelper,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _databaseHelper = databaseHelper ?? DatabaseHelper(),
       _googleSignIn = googleSignIn ?? GoogleSignIn();

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
