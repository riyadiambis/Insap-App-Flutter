import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/router/app_shell.dart';
import 'package:insap/core/theme.dart';

void main() {
  Widget buatAplikasiUji() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const SizedBox(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/catat',
                  builder: (context, state) => const SizedBox(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/refleksi',
                  builder: (context, state) => const SizedBox(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/riwayat',
                  builder: (context, state) => const SizedBox(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router);
  }

  Finder cariPillAktif() {
    return find.byWidgetPredicate((widget) {
      if (widget is AnimatedContainer) {
        final decoration = widget.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == AppColors.stabilo;
        }
      }
      return false;
    });
  }

  testWidgets(
    'keempat tab navigasi memiliki ukuran pill aktif yang sama tanpa overflow',
    (tester) async {
      await tester.pumpWidget(buatAplikasiUji());
      await tester.pumpAndSettle();

      // Pastikan keempat label teks tampil utuh
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Catat'), findsOneWidget);
      expect(find.text('Refleksi'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);

      // 1. Tab Beranda (aktif saat awal)
      expect(tester.takeException(), isNull);
      final pillBeranda = cariPillAktif();
      expect(pillBeranda, findsOneWidget);
      final sizeBeranda = tester.getSize(pillBeranda);

      // 2. Ketuk tab Catat
      await tester.tap(find.text('Catat'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final pillCatat = cariPillAktif();
      expect(pillCatat, findsOneWidget);
      final sizeCatat = tester.getSize(pillCatat);

      // 3. Ketuk tab Refleksi
      await tester.tap(find.text('Refleksi'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final pillRefleksi = cariPillAktif();
      expect(pillRefleksi, findsOneWidget);
      final sizeRefleksi = tester.getSize(pillRefleksi);

      // 4. Ketuk tab Riwayat
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final pillRiwayat = cariPillAktif();
      expect(pillRiwayat, findsOneWidget);
      final sizeRiwayat = tester.getSize(pillRiwayat);

      debugPrint('Ukuran pill Beranda : $sizeBeranda');
      debugPrint('Ukuran pill Catat   : $sizeCatat');
      debugPrint('Ukuran pill Refleksi: $sizeRefleksi');
      debugPrint('Ukuran pill Riwayat : $sizeRiwayat');

      // Pastikan tinggi pill sesuai konstan tema
      expect(sizeBeranda.height, equals(AppSizes.tinggiPillNavigasi));
      expect(sizeCatat.height, equals(AppSizes.tinggiPillNavigasi));
      expect(sizeRefleksi.height, equals(AppSizes.tinggiPillNavigasi));
      expect(sizeRiwayat.height, equals(AppSizes.tinggiPillNavigasi));

      // Pastikan lebar pill aktif di keempat tab sama persis
      expect(sizeCatat.width, equals(sizeBeranda.width));
      expect(sizeRefleksi.width, equals(sizeBeranda.width));
      expect(sizeRiwayat.width, equals(sizeBeranda.width));

      // Seluruh ukuran (lebar x tinggi) identik
      expect(sizeCatat, equals(sizeBeranda));
      expect(sizeRefleksi, equals(sizeBeranda));
      expect(sizeRiwayat, equals(sizeBeranda));
    },
  );

  testWidgets(
    'pada layar ponsel (lebar 360), pill aktif seragam selebar 74 dan bebas overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buatAplikasiUji());
      await tester.pumpAndSettle();

      // Pastikan keempat label teks tampil utuh
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Catat'), findsOneWidget);
      expect(find.text('Refleksi'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);

      // 1. Tab Beranda
      expect(tester.takeException(), isNull);
      final sizeBeranda = tester.getSize(cariPillAktif());

      // 2. Tab Catat
      await tester.tap(find.text('Catat'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final sizeCatat = tester.getSize(cariPillAktif());

      // 3. Tab Refleksi
      await tester.tap(find.text('Refleksi'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final sizeRefleksi = tester.getSize(cariPillAktif());

      // 4. Tab Riwayat
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final sizeRiwayat = tester.getSize(cariPillAktif());

      debugPrint('Ponsel 360px - Beranda : $sizeBeranda');
      debugPrint('Ponsel 360px - Catat   : $sizeCatat');
      debugPrint('Ponsel 360px - Refleksi: $sizeRefleksi');
      debugPrint('Ponsel 360px - Riwayat : $sizeRiwayat');

      expect(
        sizeBeranda,
        equals(const Size(74.0, AppSizes.tinggiPillNavigasi)),
      );
      expect(sizeCatat, equals(sizeBeranda));
      expect(sizeRefleksi, equals(sizeBeranda));
      expect(sizeRiwayat, equals(sizeBeranda));
    },
  );
}
