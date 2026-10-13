import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/header_aplikasi.dart';
import 'package:insap/features/beranda/presentation/pages/halaman_tentang.dart';

void main() {
  testWidgets(
    'HalamanTentang menampilkan informasi aplikasi, logo, dan tim pengembang',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HalamanTentang()),
      );

      // cek judul, versi, dan deskripsi
      expect(find.text('Insap: Yuk Sadar Boncos'), findsOneWidget);
      expect(find.text('Versi 0.1.0'), findsOneWidget);
      expect(find.text('TIM PENGEMBANG'), findsOneWidget);
      expect(find.text('Rahmad Riyadi'), findsOneWidget);
      expect(find.text('Dafa'), findsOneWidget);
      expect(find.text('Luthfi'), findsOneWidget);

      // cek keberadaan Image.asset logo
      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<AssetImage>());
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, equals('assets/images/logo_insap.png'));
    },
  );

  testWidgets(
    'mengetuk tombol kembali di HalamanTentang memicu Navigator.pop',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HalamanTentang()),
                    );
                  },
                  child: const Text('Buka'),
                ),
              ),
            ),
          ),
        ),
      );

      // buka HalamanTentang
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      expect(find.byType(HalamanTentang), findsOneWidget);

      // ketuk tombol kembali
      await tester.tap(find.byKey(const Key('tombol_kembali_tentang')));
      await tester.pumpAndSettle();

      // kembali ke halaman awal
      expect(find.byType(HalamanTentang), findsNothing);
      expect(find.text('Buka'), findsOneWidget);
    },
  );

  testWidgets(
    'ikon profil di HeaderAplikasi membuka HalamanTentang via Navigator.push',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            appBar: HeaderAplikasi(namaLayar: 'BERANDA'),
            body: SizedBox(),
          ),
        ),
      );

      // ketuk avatar profil
      await tester.tap(find.byKey(const Key('tombol_profil_header')));
      await tester.pumpAndSettle();

      // HalamanTentang terbuka
      expect(find.byType(HalamanTentang), findsOneWidget);
      expect(find.text('Insap: Yuk Sadar Boncos'), findsOneWidget);
    },
  );
}
