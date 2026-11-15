import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/kartu_tentang_aplikasi.dart';

void main() {
  Future<void> pasang(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(child: KartuTentangAplikasi()),
        ),
      ),
    );
  }

  group('KartuTentangAplikasi Widget Test', () {
    testWidgets(
      'menampilkan logo, judul aplikasi, versi, dan tim pengembang dengan benar',
      (tester) async {
        await pasang(tester);

        // Verifikasi logo aplikasi
        expect(find.byType(Image), findsOneWidget);
        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect(imageWidget.image, isA<AssetImage>());
        final assetImage = imageWidget.image as AssetImage;
        expect(assetImage.assetName, equals('assets/images/logo_insap.png'));

        // Verifikasi judul dan versi
        expect(find.text('Insap: Yuk Sadar Boncos'), findsOneWidget);
        expect(find.text('Versi 1.0.2'), findsOneWidget);

        // Verifikasi tim pengembang dengan nama lengkap
        expect(find.text('TIM PENGEMBANG'), findsOneWidget);
        expect(find.text('Rahmat Riyadi'), findsOneWidget);
        expect(find.text('Muh Ghazy Daffa Sampe'), findsOneWidget);
        expect(find.text('Luthfi Farros Athailah'), findsOneWidget);

        // Pastikan tidak ada typo "Rahmad"
        expect(find.textContaining('Rahmad'), findsNothing);
      },
    );

    testWidgets('menampilkan dosen pembimbing dan instansi', (tester) async {
      await pasang(tester);

      expect(find.text('DOSEN PEMBIMBING'), findsOneWidget);
      expect(find.text('Anton Prafanto, S.Kom., MT'), findsOneWidget);
      expect(find.text('Dosen Pembimbing I'), findsOneWidget);
      expect(
        find.text('Gubtha Mahendra Putra, S.Kom., M.Eng.'),
        findsOneWidget,
      );
      expect(find.text('Dosen Pembimbing II'), findsOneWidget);

      expect(find.text('Program Studi Informatika'), findsOneWidget);
      expect(
        find.text('Fakultas Teknik · Universitas Mulawarman'),
        findsOneWidget,
      );
    });

    testWidgets('tidak meluber di layar sempit 320 piksel', (tester) async {
      tester.view.physicalSize = const Size(320, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pasang(tester);

      expect(tester.takeException(), isNull);
    });
  });

  test('inisial diambil dari dua kata pertama', () {
    expect(daftarTimPengembang[0].inisial, 'RR');
    expect(daftarTimPengembang[1].inisial, 'MG');
    expect(daftarTimPengembang[2].inisial, 'LF');
    expect(const AnggotaTim(nama: 'Dafa', peran: '').inisial, 'D');
  });
}
