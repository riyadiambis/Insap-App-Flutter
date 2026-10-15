import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/router/app_shell.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/header_aplikasi.dart';

Future<void> _muatFont(String keluarga, List<String> berkas) async {
  final loader = FontLoader(keluarga);
  for (final b in berkas) {
    loader.addFont(rootBundle.load('assets/fonts/$b'));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _muatFont('Nunito', [
      'Nunito-Regular.ttf',
      'Nunito-SemiBold.ttf',
      'Nunito-Bold.ttf',
      'Nunito-ExtraBold.ttf',
    ]);
    await _muatFont('Baloo2', [
      'Baloo2-SemiBold.ttf',
      'Baloo2-Bold.ttf',
      'Baloo2-ExtraBold.ttf',
    ]);
  });

  Widget buatAplikasiUji({Widget? kontenBeranda}) {
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
                  builder: (context, state) => kontenBeranda ?? const SizedBox(),
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
        GoRoute(
          path: '/akun',
          builder: (context, state) => const Scaffold(
            body: Text('Halaman Akun Pengguna'),
          ),
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

  void ujiPillNavigasiPadaLebarLayar(double lebarLayar) {
    testWidgets(
      'pada lebar layar $lebarLayar: keempat pill aktif sama besar dan label tidak terpotong (font Nunito)',
      (tester) async {
        tester.view.physicalSize = Size(lebarLayar, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buatAplikasiUji());
        await tester.pumpAndSettle();

        final expectedWidth = (lebarLayar / 4) - (AppSpacing.mini * 2);
        final expectedHeight = AppSizes.tinggiPillNavigasi;
        final expectedSize = Size(expectedWidth, expectedHeight);

        final tabs = ['Beranda', 'Catat', 'Refleksi', 'Riwayat'];
        final List<Size> ukuranPills = [];

        for (final tab in tabs) {
          // Ketuk tab jika belum aktif
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();

          final pillAktif = cariPillAktif();
          expect(pillAktif, findsOneWidget);

          final sizePill = tester.getSize(pillAktif);
          ukuranPills.add(sizePill);

          // 1. Ukuran pill sesuai perhitungan responsif slot Expanded
          expect(
            sizePill,
            equals(expectedSize),
            reason:
                'Ukuran pill tab $tab harus $expectedSize, ditemukan $sizePill',
          );

          // 2. Verifikasi FittedBox membungkus label
          final fittedBoxFinder = find.descendant(
            of: pillAktif,
            matching: find.byType(FittedBox),
          );
          expect(
            fittedBoxFinder,
            findsOneWidget,
            reason: 'Label $tab harus dibungkus FittedBox',
          );

          // 3. Verifikasi teks label tidak memakai TextOverflow.ellipsis
          final textFinder = find.descendant(
            of: pillAktif,
            matching: find.byType(Text),
          );
          expect(textFinder, findsOneWidget);
          final textWidget = tester.widget<Text>(textFinder);
          expect(textWidget.data, equals(tab));
          expect(
            textWidget.overflow,
            isNot(TextOverflow.ellipsis),
            reason: 'Teks $tab tidak boleh menggunakan TextOverflow.ellipsis',
          );

          // 4. Verifikasi teks tidak melebihi batas (didExceedMaxLines == false)
          // Tersedia lebar penuh pill dikurangi border 2.0 di kiri dan kanan
          final lebarTersedia = sizePill.width - (AppSizes.border * 2);
          final textPainter = TextPainter(
            text: TextSpan(text: textWidget.data, style: textWidget.style),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout(maxWidth: lebarTersedia);

          expect(
            textPainter.didExceedMaxLines,
            isFalse,
            reason:
                'Label "$tab" terpotong pada lebar tersedia $lebarTersedia px '
                '(panjang teks asli: ${textPainter.size.width} px)',
          );

          // 5. Tidak ada exception
          expect(tester.takeException(), isNull);
        }

        // 6. Seluruh 4 tab memiliki ukuran pill yang persis sama
        expect(ukuranPills.length, equals(4));
        for (int i = 1; i < ukuranPills.length; i++) {
          expect(
            ukuranPills[i],
            equals(ukuranPills[0]),
            reason:
                'Ukuran pill ${tabs[i]} (${ukuranPills[i]}) harus sama dengan ${tabs[0]} (${ukuranPills[0]})',
          );
        }
      },
    );
  }

  group('AppShell - Keseragaman Pill Navigasi & Label Utuh', () {
    ujiPillNavigasiPadaLebarLayar(360.0);
    ujiPillNavigasiPadaLebarLayar(411.0);
  });

  group('AppShell - HeaderAplikasi Seragam di Seluruh Tab (ISSUE-24)', () {
    testWidgets(
      'tiap tab menampilkan tepat satu HeaderAplikasi dengan subjudul benar dan berganti saat pindah tab',
      (tester) async {
        await tester.pumpWidget(buatAplikasiUji());
        await tester.pumpAndSettle();

        // 1. Tab 0: Beranda
        expect(find.byType(HeaderAplikasi), findsOneWidget);
        expect(find.text('BERANDA'), findsOneWidget);

        // 2. Tab 1: Catat
        await tester.tap(find.text('Catat'));
        await tester.pumpAndSettle();
        expect(find.byType(HeaderAplikasi), findsOneWidget);
        expect(find.text('CATAT'), findsOneWidget);
        expect(find.text('BERANDA'), findsNothing);

        // 3. Tab 2: Refleksi
        await tester.tap(find.text('Refleksi'));
        await tester.pumpAndSettle();
        expect(find.byType(HeaderAplikasi), findsOneWidget);
        expect(find.text('REFLEKSI'), findsOneWidget);
        expect(find.text('CATAT'), findsNothing);

        // 4. Tab 3: Riwayat
        await tester.tap(find.text('Riwayat'));
        await tester.pumpAndSettle();
        expect(find.byType(HeaderAplikasi), findsOneWidget);
        expect(find.text('RIWAYAT'), findsOneWidget);
        expect(find.text('REFLEKSI'), findsNothing);
      },
    );

    testWidgets(
      'mengetuk tombol profil di header aplikasi mengarahkan navigasi ke rute /akun',
      (tester) async {
        await tester.pumpWidget(buatAplikasiUji());
        await tester.pumpAndSettle();

        final tombolProfil = find.byKey(const Key('tombol_profil_header'));
        expect(tombolProfil, findsOneWidget);

        await tester.tap(tombolProfil);
        await tester.pumpAndSettle();

        expect(find.text('Halaman Akun Pengguna'), findsOneWidget);
      },
    );
  });
}
