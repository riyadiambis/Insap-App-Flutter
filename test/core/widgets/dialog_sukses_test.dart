import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/dialog_sukses.dart';

void main() {
  Widget bungkus(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('DialogSukses Widget', () {
    testWidgets('menampilkan judul, ringkasan, dan tombol Oke', (tester) async {
      await tester.pumpWidget(
        bungkus(
          const DialogSukses(
            judul: 'Cadangan berhasil',
            ringkasan: '5 transaksi, 9 kategori, 0 refleksi',
          ),
        ),
      );

      // Verifikasi komponen teks awal
      expect(find.text('Cadangan berhasil'), findsOneWidget);
      expect(find.text('5 transaksi, 9 kategori, 0 refleksi'), findsOneWidget);
      expect(find.text('Oke'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Settle animasi centang (durasi 500ms)
      await tester.pumpAndSettle();

      expect(find.text('Cadangan berhasil'), findsOneWidget);
      expect(find.text('5 transaksi, 9 kategori, 0 refleksi'), findsOneWidget);
    });

    testWidgets('menekan tombol Oke menutup dialog', (tester) async {
      await tester.pumpWidget(
        bungkus(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  tampilkanDialogSukses(
                    context,
                    'Data berhasil dipulihkan',
                    '10 transaksi, 4 kategori, 1 refleksi',
                  );
                },
                child: const Text('Buka Dialog'),
              );
            },
          ),
        ),
      );

      // Buka dialog via tampilkanDialogSukses
      await tester.tap(find.text('Buka Dialog'));
      await tester.pump(); // frame pertama dialog muncul

      expect(find.byType(DialogSukses), findsOneWidget);
      expect(find.text('Data berhasil dipulihkan'), findsOneWidget);
      expect(find.text('10 transaksi, 4 kategori, 1 refleksi'), findsOneWidget);

      // Settle animasi 500ms
      await tester.pumpAndSettle();

      // Tekan tombol Oke
      await tester.tap(find.byKey(const Key('tombol_dialog_sukses_oke')));
      await tester.pumpAndSettle();

      // Dialog harus tertutup
      expect(find.byType(DialogSukses), findsNothing);
    });

    testWidgets('animasi centang membesar dan memudar masuk', (tester) async {
      await tester.pumpWidget(
        bungkus(
          const DialogSukses(
            judul: 'Uji Animasi',
            ringkasan: 'Menguji skala dan opasitas',
          ),
        ),
      );

      // Tepat saat frame 0, TweenAnimationBuilder berada di nilai awal
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);

      // Maju 250ms (setengah durasi animasi 500ms)
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(DialogSukses), findsOneWidget);

      // Maju hingga animasi tuntas
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
