import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/kartu_tentang_aplikasi.dart';
import 'package:insap/features/akun/presentation/pages/halaman_tentang.dart';

/// Tombol Tentang Aplikasi membuka halaman sendiri berisi kartu (ISSUE-38).
void main() {
  Widget buatAplikasiUji() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: TombolTentangAplikasi())),
        ),
        GoRoute(
          path: '/tentang',
          builder: (context, state) => const HalamanTentang(),
        ),
      ],
    );
    return MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router);
  }

  testWidgets('tombol Tentang Aplikasi membuka halaman Tentang', (
    tester,
  ) async {
    await tester.pumpWidget(buatAplikasiUji());
    await tester.pumpAndSettle();

    expect(find.byType(KartuTentangAplikasi), findsNothing);

    await tester.tap(find.byKey(const Key('tombol_tentang')));
    await tester.pumpAndSettle();

    expect(find.text('Tentang Aplikasi'), findsOneWidget);
    expect(find.byType(KartuTentangAplikasi), findsOneWidget);
    expect(find.text('Rahmat Riyadi'), findsOneWidget);
  });

  testWidgets('halaman Tentang bisa digulir di layar pendek tanpa meluber', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const HalamanTentang()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Program Studi Informatika'),
      200,
    );
    expect(find.text('Program Studi Informatika'), findsOneWidget);
  });
}
