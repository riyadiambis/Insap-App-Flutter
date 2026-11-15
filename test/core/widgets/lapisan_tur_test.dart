import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/tur/langkah_tur.dart';
import 'package:insap/core/tur/tur_cubit.dart';
import 'package:insap/core/widgets/lapisan_tur.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';

class _FakePengaturanRepository implements PengaturanRepository {
  final Map<String, String> isi = {};

  @override
  Future<bool> bacaStatusOnboarding() async => true;

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {}

  @override
  Future<int?> bacaTargetBulanan() async => null;

  @override
  Future<void> simpanTargetBulanan(int target) async {}

  @override
  Future<String?> bacaPengaturan(String kunci) async => isi[kunci];

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {
    isi[kunci] = nilai;
  }
}

void main() {
  late _FakePengaturanRepository repo;
  late TurCubit cubit;
  late List<LangkahTur> langkah;
  late GlobalKey kunciSatu;
  late GlobalKey kunciDua;
  late GlobalKey kunciAkun;
  int ketukanTombolAsli = 0;
  int panggilanDaftar = 0;

  void siapkan({bool sudahMasuk = false, bool sudahSelesai = false}) {
    repo = _FakePengaturanRepository();
    if (sudahSelesai) repo.isi[TurCubit.kunciSelesai] = '1';
    kunciSatu = GlobalKey();
    kunciDua = GlobalKey();
    kunciAkun = GlobalKey();
    langkah = [
      LangkahTur(kunci: kunciSatu, judul: 'Judul satu', isi: 'Isi satu'),
      LangkahTur(kunci: kunciDua, judul: 'Judul dua', isi: 'Isi dua'),
      LangkahTur(kunci: kunciAkun, judul: 'Daftar akun', isi: 'Isi akun'),
    ];
    cubit = TurCubit(
      pengaturanRepository: repo,
      jumlahLangkah: langkah.length,
      cekSudahMasuk: () async => sudahMasuk,
    );
    ketukanTombolAsli = 0;
    panggilanDaftar = 0;
  }

  Future<void> pasang(
    WidgetTester tester, {
    bool tanpaTargetDua = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Stack(
          children: [
            Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    key: kunciSatu,
                    onPressed: () => ketukanTombolAsli++,
                    child: const Text('Tombol asli'),
                  ),
                  const Spacer(),
                  if (!tanpaTargetDua) SizedBox(key: kunciDua, height: 40),
                  SizedBox(key: kunciAkun, height: 40, width: 40),
                ],
              ),
            ),
            Positioned.fill(
              child: LapisanTur(
                cubit: cubit,
                langkah: langkah,
                onDaftarAkun: () => panggilanDaftar++,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() async {
    await cubit.close();
  });

  group('LapisanTur', () {
    testWidgets('muncul otomatis di langkah pertama', (tester) async {
      siapkan();
      await pasang(tester);

      expect(find.byKey(const Key('balon_tur')), findsOneWidget);
      expect(find.text('LANGKAH 1 DARI 3'), findsOneWidget);
      expect(find.text('Judul satu'), findsOneWidget);
      expect(find.byKey(const Key('tombol_tur_kembali')), findsNothing);
    });

    testWidgets('tidak muncul bila sudah pernah selesai', (tester) async {
      siapkan(sudahSelesai: true);
      await pasang(tester);

      expect(find.byKey(const Key('balon_tur')), findsNothing);
    });

    testWidgets('menahan ketukan ke layar di bawahnya', (tester) async {
      siapkan();
      await pasang(tester);

      await tester.tap(find.text('Tombol asli'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(ketukanTombolAsli, 0);
    });

    testWidgets('Lanjut dan Kembali berpindah langkah', (tester) async {
      siapkan();
      await pasang(tester);

      await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
      await tester.pumpAndSettle();
      expect(find.text('LANGKAH 2 DARI 3'), findsOneWidget);
      expect(find.text('Judul dua'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tombol_tur_kembali')));
      await tester.pumpAndSettle();
      expect(find.text('Judul satu'), findsOneWidget);
    });

    testWidgets('Lewati menutup petunjuk dan menyimpan penanda', (
      tester,
    ) async {
      siapkan();
      await pasang(tester);

      await tester.tap(find.byKey(const Key('tombol_tur_lewati')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('balon_tur')), findsNothing);
      expect(repo.isi[TurCubit.kunciSelesai], '1');

      // layar di bawahnya bisa diketuk lagi
      await tester.tap(find.text('Tombol asli'));
      expect(ketukanTombolAsli, 1);
    });

    testWidgets('langkah terakhir mengajak daftar akun', (tester) async {
      siapkan();
      await pasang(tester);

      await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
      await tester.pumpAndSettle();

      expect(find.text('Daftar akun'), findsOneWidget);
      expect(find.byKey(const Key('tombol_tur_nanti')), findsOneWidget);
      expect(find.byKey(const Key('tombol_tur_lewati')), findsNothing);

      await tester.tap(find.byKey(const Key('tombol_tur_daftar')));
      await tester.pumpAndSettle();

      expect(panggilanDaftar, 1);
      expect(find.byKey(const Key('balon_tur')), findsNothing);
      expect(repo.isi[TurCubit.kunciSelesai], '1');
    });

    testWidgets('Nanti saja menutup tanpa membuka halaman akun', (
      tester,
    ) async {
      siapkan();
      await pasang(tester);

      await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tombol_tur_nanti')));
      await tester.pumpAndSettle();

      expect(panggilanDaftar, 0);
      expect(find.byKey(const Key('balon_tur')), findsNothing);
      expect(repo.isi[TurCubit.kunciSelesai], '1');
    });

    testWidgets('pengguna yang sudah masuk tidak diajak daftar', (
      tester,
    ) async {
      siapkan(sudahMasuk: true);
      await pasang(tester);

      await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
      await tester.pumpAndSettle();

      expect(find.text(judulAkunSudahMasuk), findsOneWidget);
      expect(find.byKey(const Key('tombol_tur_daftar')), findsNothing);

      await tester.tap(find.byKey(const Key('tombol_tur_selesai')));
      await tester.pumpAndSettle();
      expect(panggilanDaftar, 0);
      expect(find.byKey(const Key('balon_tur')), findsNothing);
    });

    testWidgets('melompati langkah yang widgetnya tidak ada', (tester) async {
      siapkan();
      await pasang(tester, tanpaTargetDua: true);

      await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
      // menunggu batas percobaan pencarian (20 x 100 ms)
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(find.text('LANGKAH 3 DARI 3'), findsOneWidget);
      expect(find.text('Daftar akun'), findsOneWidget);
    });

    testWidgets('balon tidak meluber di layar sempit', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      siapkan();
      await pasang(tester);
      await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final balon = tester.getRect(find.byKey(const Key('balon_tur')));
      expect(balon.left, greaterThanOrEqualTo(0));
      expect(balon.right, lessThanOrEqualTo(320));
      expect(balon.top, greaterThanOrEqualTo(0));
      expect(balon.bottom, lessThanOrEqualTo(640));
    });
  });
}
