import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/maskot_struki.dart';
import 'package:insap/features/langganan/presentation/pages/halaman_langganan.dart';

void main() {
  Widget bangunHalamanUji() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const HalamanLangganan(),
    );
  }

  testWidgets(
    'menampilkan harga Rp29 rb, kuota 50 pindai/pekan dan 5 pindai/pekan, serta tidak menampilkan Tanya Struki',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(bangunHalamanUji());
      await tester.pumpAndSettle();

      expect(find.text('Pilih paket Insap'), findsOneWidget);
      expect(find.text('Rp0'), findsOneWidget);
      expect(find.text('5 pindai/pekan'), findsOneWidget);
      expect(find.text('Rp15 rb'), findsOneWidget);
      expect(find.text('50 pindai/pekan'), findsOneWidget);
      expect(find.text('Rp29 rb'), findsOneWidget);
      expect(find.text('100 pindai/pekan'), findsOneWidget);
      expect(find.textContaining('Tanya Struki'), findsNothing);

      final maskotFinder = find.byType(MaskotStruki);
      expect(maskotFinder, findsOneWidget);
      expect(tester.widget<MaskotStruki>(maskotFinder).pose, PoseMaskot.nabung);
      expect(
        tester.getSize(maskotFinder),
        const Size(
          AppSizes.ukuranMaskotLangganan,
          AppSizes.ukuranMaskotLangganan,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'memilih paket mengubah CTA dan mengetuk CTA membuka dialog pengembangan',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(bangunHalamanUji());
      await tester.pumpAndSettle();

      expect(find.text('Langganan Pro · Rp29.000/bulan'), findsOneWidget);

      await tester.tap(find.byKey(const Key('kartu_paket_plus')));
      await tester.pumpAndSettle();
      expect(find.text('Langganan Plus · Rp15.000/bulan'), findsOneWidget);

      await tester.tap(find.byKey(const Key('kartu_paket_gratis')));
      await tester.pumpAndSettle();
      expect(find.text('Paketmu sekarang'), findsNWidgets(2));
      await tester.tap(find.byKey(const Key('tombol_langganan_cta')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialog_fitur_dikembangkan')), findsNothing);

      await tester.tap(find.byKey(const Key('kartu_paket_pro')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tombol_langganan_cta')));
      await tester.pumpAndSettle();
      expect(find.text('Insap Pro sedang disiapkan'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('tombol_tutup_dialog_dikembangkan')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialog_fitur_dikembangkan')), findsNothing);
    },
  );
}
