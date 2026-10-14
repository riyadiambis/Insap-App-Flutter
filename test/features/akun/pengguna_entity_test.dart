import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/akun/domain/entities/pengguna_entity.dart';

void main() {
  group('PenggunaEntity', () {
    test('pemetaan entity dengan namaTampilan dan fotoUrl lengkap', () {
      const pengguna1 = PenggunaEntity(
        uid: 'uid-google-1',
        email: 'user@gmail.com',
        namaTampilan: 'Rahmat Riyadi',
        fotoUrl: 'https://lh3.googleusercontent.com/a/foto.jpg',
      );
      const pengguna2 = PenggunaEntity(
        uid: 'uid-google-1',
        email: 'user@gmail.com',
        namaTampilan: 'Rahmat Riyadi',
        fotoUrl: 'https://lh3.googleusercontent.com/a/foto.jpg',
      );

      expect(pengguna1.uid, 'uid-google-1');
      expect(pengguna1.email, 'user@gmail.com');
      expect(pengguna1.namaTampilan, 'Rahmat Riyadi');
      expect(pengguna1.fotoUrl, 'https://lh3.googleusercontent.com/a/foto.jpg');
      expect(pengguna1, equals(pengguna2));
      expect(pengguna1.props, [
        'uid-google-1',
        'user@gmail.com',
        'Rahmat Riyadi',
        'https://lh3.googleusercontent.com/a/foto.jpg',
      ]);
    });

    test('pemetaan entity dengan namaTampilan dan fotoUrl bernilai null', () {
      const pengguna = PenggunaEntity(
        uid: 'uid-email-1',
        email: 'user@insap.id',
      );

      expect(pengguna.uid, 'uid-email-1');
      expect(pengguna.email, 'user@insap.id');
      expect(pengguna.namaTampilan, isNull);
      expect(pengguna.fotoUrl, isNull);
      expect(pengguna.props, ['uid-email-1', 'user@insap.id', null, null]);
    });

    test('entity berbeda jika namaTampilan atau fotoUrl berbeda', () {
      const penggunaA = PenggunaEntity(
        uid: 'uid-1',
        email: 'a@insap.id',
        namaTampilan: 'Budi',
      );
      const penggunaB = PenggunaEntity(
        uid: 'uid-1',
        email: 'a@insap.id',
        namaTampilan: 'Santoso',
      );
      const penggunaC = PenggunaEntity(
        uid: 'uid-1',
        email: 'a@insap.id',
        namaTampilan: 'Budi',
        fotoUrl: 'https://example.com/foto.jpg',
      );

      expect(penggunaA, isNot(equals(penggunaB)));
      expect(penggunaA, isNot(equals(penggunaC)));
    });
  });
}
