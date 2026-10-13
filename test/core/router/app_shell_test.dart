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

  testWidgets('keempat tab navigasi memiliki ukuran pill aktif yang sama', (
    tester,
  ) async {
    await tester.pumpWidget(buatAplikasiUji());
    await tester.pumpAndSettle();

    // 1. Tab Beranda (aktif saat inisialisasi)
    final pillBeranda = cariPillAktif();
    expect(pillBeranda, findsOneWidget);
    final sizeBeranda = tester.getSize(pillBeranda);

    // 2. Ketuk tab Catat
    await tester.tap(find.text('Catat'));
    await tester.pumpAndSettle();
    final pillCatat = cariPillAktif();
    expect(pillCatat, findsOneWidget);
    final sizeCatat = tester.getSize(pillCatat);

    // 3. Ketuk tab Refleksi
    await tester.tap(find.text('Refleksi'));
    await tester.pumpAndSettle();
    final pillRefleksi = cariPillAktif();
    expect(pillRefleksi, findsOneWidget);
    final sizeRefleksi = tester.getSize(pillRefleksi);

    // 4. Ketuk tab Riwayat
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    final pillRiwayat = cariPillAktif();
    expect(pillRiwayat, findsOneWidget);
    final sizeRiwayat = tester.getSize(pillRiwayat);

    debugPrint('Ukuran pill Beranda : $sizeBeranda');
    debugPrint('Ukuran pill Catat   : $sizeCatat');
    debugPrint('Ukuran pill Refleksi: $sizeRefleksi');
    debugPrint('Ukuran pill Riwayat : $sizeRiwayat');

    // Pastikan ukuran pill sesuai konstan tema
    expect(
      sizeBeranda,
      equals(
        const Size(AppSizes.lebarPillNavigasi, AppSizes.tinggiPillNavigasi),
      ),
    );

    // Pastikan keempat ukuran pill sama persis
    expect(sizeCatat, equals(sizeBeranda));
    expect(sizeRefleksi, equals(sizeBeranda));
    expect(sizeRiwayat, equals(sizeBeranda));
  });
}
