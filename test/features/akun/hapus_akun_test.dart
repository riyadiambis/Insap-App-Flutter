import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/akun/data/repositories/akun_repository_impl.dart';
import 'package:insap/features/akun/data/repositories/cadangan_repository_impl.dart';

/// Menguji bagian hapus akun (ISSUE-36) yang tidak butuh Firebase Auth asli.
void main() {
  group('CadanganRepositoryImpl.hapusDataAwan', () {
    late FakeFirebaseFirestore firestore;

    Future<void> isiAwan(String uid, {int jumlahTransaksi = 2}) async {
      final doc = firestore.collection('pengguna').doc(uid);
      await doc.set({'jumlah_transaksi': jumlahTransaksi});
      await doc.collection('kategori').doc('1').set({'nama': 'Makan'});
      await doc.collection('refleksi').doc('1').set({'catatan': 'hemat'});
      for (var i = 0; i < jumlahTransaksi; i++) {
        await doc.collection('transaksi').doc('$i').set({'jumlah': 1000 + i});
      }
    }

    Future<int> hitungDokumen(String uid) async {
      final doc = firestore.collection('pengguna').doc(uid);
      var total = (await doc.get()).exists ? 1 : 0;
      for (final nama in const ['kategori', 'transaksi', 'refleksi']) {
        total += (await doc.collection(nama).get()).docs.length;
      }
      return total;
    }

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('menghapus dokumen induk dan seluruh subkoleksi', () async {
      await isiAwan('uid-a');
      expect(await hitungDokumen('uid-a'), 5);

      await CadanganRepositoryImpl.hapusDataAwan(firestore, 'uid-a');

      expect(await hitungDokumen('uid-a'), 0);
    });

    test('tidak menyentuh data pengguna lain', () async {
      await isiAwan('uid-a');
      await isiAwan('uid-b');

      await CadanganRepositoryImpl.hapusDataAwan(firestore, 'uid-a');

      expect(await hitungDokumen('uid-b'), 5);
    });

    test('tetap tuntas bila dokumen melebihi satu batch', () async {
      await isiAwan('uid-a', jumlahTransaksi: 500);

      await CadanganRepositoryImpl.hapusDataAwan(firestore, 'uid-a');

      expect(await hitungDokumen('uid-a'), 0);
    });

    test('aman dipanggil saat awan kosong', () async {
      await CadanganRepositoryImpl.hapusDataAwan(firestore, 'uid-kosong');

      expect(await hitungDokumen('uid-kosong'), 0);
    });
  });

  group('AkunRepositoryImpl.masukMasihBaru', () {
    final sekarang = DateTime(2026, 11, 15, 12);

    test('benar bila masuk kurang dari 5 menit lalu', () {
      expect(
        AkunRepositoryImpl.masukMasihBaru(
          sekarang.subtract(const Duration(minutes: 4, seconds: 59)),
          sekarang,
        ),
        isTrue,
      );
    });

    test('salah bila masuk tepat 5 menit lalu atau lebih', () {
      expect(
        AkunRepositoryImpl.masukMasihBaru(
          sekarang.subtract(const Duration(minutes: 5)),
          sekarang,
        ),
        isFalse,
      );
    });

    test('salah bila waktu masuk tidak diketahui', () {
      expect(AkunRepositoryImpl.masukMasihBaru(null, sekarang), isFalse);
    });
  });
}
