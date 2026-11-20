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

        expect(find.byType(Image), findsOneWidget);
        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect(imageWidget.image, isA<AssetImage>());
        final assetImage = imageWidget.image as AssetImage;
        expect(assetImage.assetName, equals('assets/images/logo_insap.png'));

        expect(find.text('Insap: Catat Keuangan'), findsOneWidget);
        expect(find.text('Versi 2.1.1'), findsOneWidget);

        expect(find.text('TIM PENGEMBANG'), findsOneWidget);
        expect(find.textContaining('Rahmat Riyadi'), findsOneWidget);
        expect(find.textContaining('Muh Ghazy Daffa Sampe'), findsOneWidget);
        expect(find.textContaining('Luthfi Farros Athailah'), findsOneWidget);

        expect(find.textContaining('Rahmad'), findsNothing);
      },
    );

    testWidgets('menampilkan dosen pengampu, instansi, dan tautan privasi',
        (tester) async {
      await pasang(tester);

      expect(find.text('DOSEN PENGAMPU'), findsOneWidget);
      expect(find.textContaining('Anton Prafanto, S.Kom., MT'), findsOneWidget);
      expect(
        find.textContaining('Gubtha Mahendra Putra, S.Kom., M.Eng.'),
        findsOneWidget,
      );

      expect(
        find.text('Program Studi Informatika, Fakultas Teknik\nUniversitas Mulawarman'),
        findsOneWidget,
      );
      expect(find.text('Kebijakan privasi'), findsOneWidget);
      expect(find.text('Lisensi'), findsOneWidget);
    });

    testWidgets('tautan Kebijakan privasi dan Lisensi membuka dialog informasi',
        (tester) async {
      await pasang(tester);

      await tester.tap(find.text('Kebijakan privasi'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Catatan keuangan disimpan secara lokal'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lisensi'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Baloo 2 dan Nunito'),
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
