import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/kartu_buku_tulis.dart';
import 'package:insap/core/widgets/maskot_struki.dart';
import 'package:insap/core/widgets/tombol_stabilo.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';
import 'package:insap/features/perkenalan/presentation/cubit/onboarding_cubit.dart';
import 'package:insap/features/perkenalan/presentation/pages/halaman_perkenalan.dart';
import 'package:insap/features/transaksi/presentation/catat/widgets/kolom_input_nominal.dart';

class _FakePengaturanRepository implements PengaturanRepository {
  bool _sudahOnboarding = false;
  int? _target;
  final Map<String, String> _pengaturan = {};

  @override
  Future<bool> bacaStatusOnboarding() async => _sudahOnboarding;

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {
    _sudahOnboarding = selesai;
  }

  @override
  Future<int?> bacaTargetBulanan() async => _target;

  @override
  Future<void> simpanTargetBulanan(int target) async {
    _target = target;
  }

  @override
  Future<String?> bacaPengaturan(String kunci) async => _pengaturan[kunci];

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {
    _pengaturan[kunci] = nilai;
  }
}

void main() {
  late _FakePengaturanRepository repo;
  late OnboardingCubit cubit;

  setUp(() {
    repo = _FakePengaturanRepository();
    cubit = OnboardingCubit(pengaturanRepository: repo);
  });

  tearDown(() {
    cubit.close();
  });

  Widget buatHalamanUji() {
    final router = GoRouter(
      initialLocation: '/perkenalan',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Beranda Dummy')),
        ),
        GoRoute(
          path: '/akun',
          builder: (context, state) =>
              const Scaffold(body: Text('Halaman Masuk Dummy')),
        ),
        GoRoute(
          path: '/perkenalan',
          builder: (context, state) => BlocProvider<OnboardingCubit>.value(
            value: cubit,
            child: const HalamanPerkenalan(),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  const judulLayar = [
    'Halo, aku Struki!',
    'Biar AI yang baca struknya',
    'Tutup pekan dengan refleksi',
  ];

  const isiLayar = [
    'Kirim struk belanjamu ke aku. Aku catat, kamu tinggal insaf sebelum boncos.',
    'Foto struk belanjamu. AI membaca tiap barang, kamu cukup periksa lalu simpan.',
    'Tiap akhir pekan, lihat ke mana uangmu pergi dan tulis satu hal yang mau diperbaiki.',
  ];

  const poseLayar = [
    PoseMaskot.mulai,
    PoseMaskot.scan,
    PoseMaskot.detektif,
  ];

  void ukuranLayar(WidgetTester tester, Size ukuran, {double rasio = 1.0}) {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = rasio;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
  }

  Future<void> geserKeLayarBerikutnya(WidgetTester tester) async {
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'tiga layar sambutan tampil berurutan saat digeser dengan judul, isi, dan maskot',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    for (var i = 0; i < judulLayar.length; i++) {
      expect(
        find.text(judulLayar[i]),
        findsOneWidget,
        reason: 'judul layar ${i + 1}',
      );
      expect(
        find.text(isiLayar[i]),
        findsOneWidget,
        reason: 'isi layar ${i + 1}',
      );
      final maskot = tester.widget<MaskotStruki>(
        find.byKey(const Key('maskot_sambutan')),
      );
      expect(maskot.pose, poseLayar[i], reason: 'pose layar ${i + 1}');
      expect(find.byKey(const Key('tombol_mulai_sambutan')), findsOneWidget);
      expect(find.byKey(const Key('tombol_sudah_punya_akun')), findsOneWidget);
      if (i < judulLayar.length - 1) await geserKeLayarBerikutnya(tester);
    }
  });

  testWidgets('maskot sambutan berukuran 220x220 pada setiap layar',
      (tester) async {
    ukuranLayar(tester, const Size(411, 914));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    for (var i = 0; i < poseLayar.length; i++) {
      final maskotFinder = find.byKey(const Key('maskot_sambutan'));
      expect(tester.getSize(maskotFinder), const Size(220, 220));
      final maskot = tester.widget<MaskotStruki>(maskotFinder);
      expect(maskot.pose, poseLayar[i]);
      if (i < poseLayar.length - 1) await geserKeLayarBerikutnya(tester);
    }
  });

  testWidgets(
      'layar sambutan menampilkan maskot mulai 220x220, teks kanvas, 3 titik, Mulai, dan Sudah punya akun? Masuk',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    expect(find.text('Halo, aku Struki!'), findsOneWidget);
    expect(
      find.text(
        'Kirim struk belanjamu ke aku. Aku catat, kamu tinggal insaf sebelum boncos.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mulai'), findsOneWidget);
    expect(find.text('Sudah punya akun? Masuk'), findsOneWidget);

    final maskotFinder = find.byKey(const Key('maskot_sambutan'));
    expect(maskotFinder, findsOneWidget);
    expect(tester.getSize(maskotFinder), const Size(220, 220));
    expect(tester.widget<MaskotStruki>(maskotFinder).pose, PoseMaskot.mulai);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'indikator titik: tiga titik, satu pil ink aktif yang berpindah saat digeser',
      (tester) async {
    ukuranLayar(tester, const Size(411, 914));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    Finder titik() => find.byWidgetPredicate(
          (w) => w is AnimatedContainer && w.constraints?.maxHeight == 8.0,
        );

    double lebarTitik(int i) =>
        tester.widget<AnimatedContainer>(titik().at(i)).constraints!.maxWidth;

    Color? warnaTitik(int i) =>
        (tester.widget<AnimatedContainer>(titik().at(i)).decoration
                as BoxDecoration)
            .color;

    expect(titik(), findsNWidgets(3));
    expect(lebarTitik(0), 22.0);
    expect(warnaTitik(0), AppColors.ink);
    expect(lebarTitik(1), 8.0);
    expect(warnaTitik(1), AppColors.garisPutus);

    await geserKeLayarBerikutnya(tester);
    expect(lebarTitik(0), 8.0);
    expect(warnaTitik(0), AppColors.garisPutus);
    expect(lebarTitik(1), 22.0);
    expect(warnaTitik(1), AppColors.ink);

    await geserKeLayarBerikutnya(tester);
    expect(lebarTitik(1), 8.0);
    expect(lebarTitik(2), 22.0);
    expect(warnaTitik(2), AppColors.ink);
  });

  testWidgets('tombol Mulai dari layar 1 dan layar 3 langsung membuka layar target',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    await geserKeLayarBerikutnya(tester);
    await geserKeLayarBerikutnya(tester);
    expect(find.text(judulLayar[2]), findsOneWidget);
    expect(find.byKey(const Key('kolom_target_bulanan')), findsNothing);

    await tester.tap(find.byKey(const Key('tombol_mulai_sambutan')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kolom_target_bulanan')), findsOneWidget);
    expect(find.byKey(const Key('tombol_simpan_target')), findsOneWidget);
    expect(find.byKey(const Key('tombol_nanti_saja')), findsOneWidget);
  });

  testWidgets('tombol kembali di layar target mengembalikan ke layar sambutan',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_mulai_sambutan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kolom_target_bulanan')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Kembali'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kolom_target_bulanan')), findsNothing);
    expect(find.text('Halo, aku Struki!'), findsOneWidget);
  });

  testWidgets('tombol Mulai membuka layar Target bulanan sesuai Target.dc.html',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_mulai_sambutan')));
    await tester.pumpAndSettle();

    expect(find.byType(KartuBukuTulis), findsNothing);
    expect(find.text('Target bulanan'), findsOneWidget);
    expect(find.text('LANGKAH 2 DARI 3'), findsOneWidget);
    expect(find.text('Berapa batas belanja sebulan?'), findsOneWidget);
    expect(
      find.text(
        'Angka ini jadi patokan refleksi. Bisa diubah kapan saja di Akun.',
      ),
      findsOneWidget,
    );
    expect(find.text('TARGET BULANAN'), findsOneWidget);
    expect(find.text('Rp 1 jt'), findsOneWidget);
    expect(find.text('Rp 1,5 jt'), findsOneWidget);
    expect(find.text('Rp 2 jt'), findsOneWidget);
    expect(find.text('Rp 3 jt'), findsOneWidget);
    expect(find.byType(KolomInputNominal), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.text('Nanti saja'), findsOneWidget);

    final maskotTarget = find.byKey(const Key('maskot_target_sambutan'));
    expect(tester.getSize(maskotTarget), const Size(120, 120));
    expect(tester.widget<MaskotStruki>(maskotTarget).pose, PoseMaskot.nabung);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'layar target: tata letak tanpa KartuBukuTulis, teks baru tanpa kata "mengubahnya nanti", dan tombol simpan nonaktif saat kosong',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_mulai_sambutan')));
    await tester.pumpAndSettle();

    expect(find.byType(KartuBukuTulis), findsNothing);
    expect(find.textContaining('mengubahnya nanti'), findsNothing);

    final inputNominal = find.descendant(
      of: find.byKey(const Key('kolom_target_bulanan')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(inputNominal, '0');
    await tester.pumpAndSettle();

    final tombolSimpan = tester.widget<TombolStabilo>(
      find.byKey(const Key('tombol_simpan_target')),
    );
    expect(tombolSimpan.onPressed, isNull);
  });

  testWidgets('chip preset Target bulanan mengubah nominal dan info mingguan',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_mulai_sambutan')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rp 3 jt'));
    await tester.pumpAndSettle();

    expect(find.text('Rp3.000.000'), findsOneWidget);
    expect(
      find.textContaining('Rp750.000 per pekan', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('tombol_simpan_target')));
    await tester.pumpAndSettle();

    expect(repo._target, equals(3000000));
    expect(repo._sudahOnboarding, isTrue);
    expect(find.text('Beranda Dummy'), findsOneWidget);
    expect(find.text(judulLayar[0]), findsNothing);
  });

  testWidgets(
      'layar target: ketik 2000000 tampil "Rp2.000.000" dan tersimpan angka murni 2000000',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_mulai_sambutan')));
    await tester.pumpAndSettle();

    final inputNominal = find.descendant(
      of: find.byKey(const Key('kolom_target_bulanan')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(inputNominal, '2000000');
    await tester.pumpAndSettle();

    expect(find.text('Rp2.000.000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tombol_simpan_target')));
    await tester.pumpAndSettle();

    expect(repo._target, equals(2000000));
    expect(repo._sudahOnboarding, isTrue);
  });

  testWidgets('tombol Nanti saja menyelesaikan onboarding tanpa menyimpan target',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_mulai_sambutan')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_nanti_saja')));
    await tester.pumpAndSettle();

    expect(repo._target, isNull);
    expect(repo._sudahOnboarding, isTrue);
    expect(find.text('Beranda Dummy'), findsOneWidget);
    expect(find.text(judulLayar[0]), findsNothing);
  });

  for (final ukuran in const [Size(360, 640), Size(411, 914)]) {
    testWidgets(
        'bebas overflow di ${ukuran.width.toInt()}x${ukuran.height.toInt()} untuk ketiga layar sambutan',
        (tester) async {
      ukuranLayar(tester, ukuran);

      await tester.pumpWidget(buatHalamanUji());
      await tester.pumpAndSettle();

      for (var i = 0; i < judulLayar.length; i++) {
        expect(find.text(judulLayar[i]), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'layar ${i + 1}');
        if (i < judulLayar.length - 1) await geserKeLayarBerikutnya(tester);
      }
    });
  }

  testWidgets(
      'tidak ada karakter tanda pisah panjang em dash di teks sambutan dan target',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    for (var i = 0; i < judulLayar.length; i++) {
      expect(find.textContaining('—'), findsNothing);
      if (i < judulLayar.length - 1) await geserKeLayarBerikutnya(tester);
    }

    await tester.tap(find.byKey(const Key('tombol_mulai_sambutan')));
    await tester.pumpAndSettle();
    expect(find.textContaining('—'), findsNothing);
  });

  testWidgets('layar target tidak overflow di 360x640 saat keyboard terbuka',
      (tester) async {
    ukuranLayar(tester, const Size(360, 640));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_mulai_sambutan')));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() => tester.view.resetViewInsets());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('tombol_simpan_target')), findsOneWidget);
    expect(find.byKey(const Key('tombol_nanti_saja')), findsOneWidget);

    await tester.drag(find.text('LANGKAH 2 DARI 3'), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sudah punya akun? Masuk mengarahkan ke /akun', (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_sudah_punya_akun')));
    await tester.pumpAndSettle();

    expect(repo._sudahOnboarding, isTrue);
    expect(find.text('Halaman Masuk Dummy'), findsOneWidget);
  });

  testWidgets(
      'tombol dan chip di layar sambutan dan target memiliki target sentuh minimal 48',
      (tester) async {
    ukuranLayar(tester, const Size(390, 844));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('tombol_mulai_sambutan'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('tombol_sudah_punya_akun'))).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byKey(const Key('tombol_mulai_sambutan')));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.bySemanticsLabel('Kembali')).width,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.bySemanticsLabel('Kembali')).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('tombol_simpan_target'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('tombol_nanti_saja'))).height,
      greaterThanOrEqualTo(48),
    );
    for (final preset in const ['Rp 1 jt', 'Rp 1,5 jt', 'Rp 2 jt', 'Rp 3 jt']) {
      final ukuranPreset = tester.getSize(
        find.ancestor(
          of: find.text(preset),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(ukuranPreset.width, greaterThanOrEqualTo(48));
      expect(ukuranPreset.height, greaterThanOrEqualTo(48));
    }
  });
}
