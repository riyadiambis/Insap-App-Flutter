import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/avatar_profil.dart';

void main() {
  group('AvatarProfil', () {
    testWidgets('menampilkan ikon person bawaan bila fotoUrl null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarProfil(
              fotoUrl: null,
              ukuran: 52,
              ukuranIkon: 28,
              warnaLatar: AppColors.stabilo,
              warnaIkon: AppColors.ink,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('menampilkan ikon person bawaan bila fotoUrl string kosong', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarProfil(
              fotoUrl: '   ',
              ukuran: 52,
              ukuranIkon: 28,
              warnaLatar: AppColors.stabilo,
              warnaIkon: AppColors.ink,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets(
      'errorBuilder pada Image.network jatuh ke ikon person saat gagal muat atau offline',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AvatarProfil(
                fotoUrl: 'https://example.com/foto_offline.jpg',
                ukuran: 52,
                ukuranIkon: 28,
                warnaLatar: AppColors.stabilo,
                warnaIkon: AppColors.ink,
              ),
            ),
          ),
        );

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        final imageWidget = tester.widget<Image>(imageFinder);
        expect(imageWidget.errorBuilder, isNotNull);

        final element = tester.element(imageFinder);
        final fallbackWidget = imageWidget.errorBuilder!(
          element,
          Exception('Offline / Gagal koneksi'),
          null,
        );

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: fallbackWidget)),
        );

        final iconFinder = find.byIcon(Icons.person);
        expect(iconFinder, findsOneWidget);
        final iconWidget = tester.widget<Icon>(iconFinder);
        expect(iconWidget.size, 28);
        expect(iconWidget.color, AppColors.ink);
      },
    );
  });
}
