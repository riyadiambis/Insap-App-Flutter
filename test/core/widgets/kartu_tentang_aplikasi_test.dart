import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/kartu_tentang_aplikasi.dart';

void main() {
  group('KartuTentangAplikasi Widget Test', () {
    testWidgets(
      'menampilkan logo, judul aplikasi, versi, dan tim pengembang dengan benar',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(child: KartuTentangAplikasi()),
            ),
          ),
        );

        // Verifikasi logo aplikasi
        expect(find.byType(Image), findsOneWidget);
        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect(imageWidget.image, isA<AssetImage>());
        final assetImage = imageWidget.image as AssetImage;
        expect(assetImage.assetName, equals('assets/images/logo_insap.png'));

        // Verifikasi judul dan versi
        expect(find.text('Insap: Yuk Sadar Boncos'), findsOneWidget);
        expect(find.text('Versi 0.1.0'), findsOneWidget);

        // Verifikasi header tim pengembang
        expect(find.text('TIM PENGEMBANG'), findsOneWidget);

        // Verifikasi nama anggota tim (Rahmat Riyadi, Dafa, Luthfi)
        expect(find.text('Rahmat Riyadi'), findsOneWidget);
        expect(find.text('Dafa'), findsOneWidget);
        expect(find.text('Luthfi'), findsOneWidget);

        // Pastikan tidak ada typo "Rahmad"
        expect(find.textContaining('Rahmad'), findsNothing);
      },
    );
  });
}
