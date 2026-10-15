import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/widgets/avatar_profil.dart';
import 'package:insap/core/widgets/header_aplikasi.dart';
import 'package:insap/features/akun/domain/entities/pengguna_entity.dart';

void main() {
  group('HeaderAplikasi profil ikon / avatar', () {
    testWidgets('menampilkan ikon default saat belum login (pengguna null)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: HeaderAplikasi(namaLayar: 'BERANDA', pengguna: null),
          ),
        ),
      );

      final avatar = tester.widget<AvatarProfil>(find.byType(AvatarProfil));
      expect(avatar.fotoUrl, isNull);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('menampilkan AvatarProfil saat login dengan fotoUrl', (
      tester,
    ) async {
      const pengguna = PenggunaEntity(
        uid: 'uid-google',
        email: 'user@gmail.com',
        namaTampilan: 'User Google',
        fotoUrl: 'https://lh3.googleusercontent.com/foto.jpg',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: HeaderAplikasi(namaLayar: 'BERANDA', pengguna: pengguna),
          ),
        ),
      );

      expect(find.byType(AvatarProfil), findsOneWidget);
      final avatar = tester.widget<AvatarProfil>(find.byType(AvatarProfil));
      expect(avatar.fotoUrl, 'https://lh3.googleusercontent.com/foto.jpg');
    });

    testWidgets(
      'menampilkan AvatarProfil saat login tanpa fotoUrl (fallback ikon person)',
      (tester) async {
        const pengguna = PenggunaEntity(
          uid: 'uid-email',
          email: 'user@email.com',
          namaTampilan: 'User Email',
          fotoUrl: null,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              appBar: HeaderAplikasi(namaLayar: 'BERANDA', pengguna: pengguna),
            ),
          ),
        );

        expect(find.byType(AvatarProfil), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
      },
    );

    testWidgets('ketuk ikon profil menavigasi ke route /akun', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(appBar: HeaderAplikasi(namaLayar: 'BERANDA')),
          ),
          GoRoute(
            path: '/akun',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Layar Akun Target'))),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.byKey(const Key('tombol_profil_header')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tombol_profil_header')));
      await tester.pumpAndSettle();

      expect(find.text('Layar Akun Target'), findsOneWidget);
    });
  });
}
