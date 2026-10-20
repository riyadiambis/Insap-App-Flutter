import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/kartu_buku_tulis.dart';
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
          path: '/perkenalan',
          builder: (context, state) => BlocProvider<OnboardingCubit>.value(
            value: cubit,
            child: const HalamanPerkenalan(),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  const judulLayar = [
    'Kenalan dengan Insap',
    'Catat dalam hitungan detik',
    'Biar AI yang baca struknya',
    'Tutup pekan dengan refleksi',
    'Semua catatan ada di Riwayat',
  ];

  const isiLayar = [
    'Insap mengajakmu sadar ke mana uangmu pergi, ala Kakeibo dari Jepang: catat, lihat, lalu renungkan tiap pekan.',
    'Ketuk Catat Cepat, isi nominal, pilih kategori, lalu simpan.',
    'Foto struk belanjamu. AI membaca tiap barang, kamu cukup periksa lalu simpan.',
    'Tiap akhir pekan, lihat ke mana uangmu pergi dan tulis satu hal yang mau diperbaiki.',
    'Cari dan saring catatanmu kapan saja. Masuk akun kalau mau mencadangkan data.',
  ];

  const ikonLayar = [
    Icons.menu_book,
    Icons.edit,
    Icons.photo_camera,
    Icons.lightbulb,
    Icons.receipt_long,
  ];

  void ukuranLayar(WidgetTester tester, Size ukuran, {double rasio = 1.0}) {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = rasio;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
  }

  Future<void> lanjut(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();
  }

  testWidgets('lima layar sambutan tampil berurutan dengan judul, isi, dan ikon',
      (tester) async {
    ukuranLayar(tester, const Size(1080, 2400), rasio: 2.0);

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    for (var i = 0; i < judulLayar.length; i++) {
      expect(find.text(judulLayar[i]), findsOneWidget, reason: 'judul layar ${i + 1}');
      expect(find.text(isiLayar[i]), findsOneWidget, reason: 'isi layar ${i + 1}');
      expect(
        find.descendant(
          of: find.byKey(const Key('kotak_ilustrasi_sambutan')),
          matching: find.byIcon(ikonLayar[i]),
        ),
        findsOneWidget,
        reason: 'ikon layar ${i + 1}',
      );
      expect(find.byKey(const Key('tombol_lewati')), findsOneWidget);
      if (i < judulLayar.length - 1) await lanjut(tester);
    }
  });

  testWidgets('kotak ilustrasi berukuran 132x132 dengan warna sesuai layar',
      (tester) async {
    ukuranLayar(tester, const Size(411, 914));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    const warna = [
      AppColors.ilustrasiJingga,
      AppColors.stabilo,
      AppColors.aiBiru,
      AppColors.ilustrasiUngu,
      AppColors.ilustrasiHijau,
    ];

    for (var i = 0; i < warna.length; i++) {
      final kotak = find.byKey(const Key('kotak_ilustrasi_sambutan'));
      expect(tester.getSize(kotak), const Size(132, 132));
      final dekor = tester.widget<Container>(kotak).decoration as BoxDecoration;
      expect(dekor.color, warna[i]);
      if (i < warna.length - 1) await lanjut(tester);
    }
  });

  testWidgets('layar 5 diikuti layar target bulanan lewat tombol Lanjut',
      (tester) async {
    ukuranLayar(tester, const Size(1080, 2400), rasio: 2.0);

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await lanjut(tester);
    }
    expect(find.text(judulLayar.last), findsOneWidget);
    expect(find.byKey(const Key('kolom_target_bulanan')), findsNothing);

    await lanjut(tester);
    expect(find.byKey(const Key('kolom_target_bulanan')), findsOneWidget);
    expect(find.byKey(const Key('tombol_simpan_target')), findsOneWidget);
  });

  testWidgets('Kembali nonaktif di layar 1, aktif di layar berikutnya dan mundur satu layar',
      (tester) async {
    ukuranLayar(tester, const Size(1080, 2400), rasio: 2.0);

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    KartuBukuTulis kembali() => tester.widget<KartuBukuTulis>(
          find.descendant(
            of: find.byKey(const Key('tombol_kembali')),
            matching: find.byType(KartuBukuTulis),
          ),
        );

    expect(find.text('Kembali'), findsOneWidget);
    expect(kembali().onTap, isNull);

    // ketuk tombol nonaktif tidak memindahkan layar
    await tester.tap(find.byKey(const Key('tombol_kembali')));
    await tester.pumpAndSettle();
    expect(find.text(judulLayar[0]), findsOneWidget);

    await lanjut(tester);
    expect(find.text(judulLayar[1]), findsOneWidget);
    expect(kembali().onTap, isNotNull);

    await tester.tap(find.byKey(const Key('tombol_kembali')));
    await tester.pumpAndSettle();
    expect(find.text(judulLayar[0]), findsOneWidget);
    expect(kembali().onTap, isNull);
  });

  testWidgets('tombol Kembali dan Lanjut sama lebar dan tingginya minimal 48',
      (tester) async {
    ukuranLayar(tester, const Size(411, 914));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    final kembali = tester.getSize(find.byKey(const Key('tombol_kembali')));
    final lanjutUkuran = tester.getSize(find.byKey(const Key('tombol_lanjut')));
    expect(kembali.width, closeTo(lanjutUkuran.width, 0.5));
    expect(kembali.height, greaterThanOrEqualTo(48));
    expect(lanjutUkuran.height, greaterThanOrEqualTo(48));
  });

  testWidgets('indikator titik: lima titik, satu pil ink aktif yang berpindah',
      (tester) async {
    ukuranLayar(tester, const Size(411, 914));

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    Finder titik() => find.byWidgetPredicate(
          (w) =>
              w is AnimatedContainer &&
              w.constraints?.maxHeight == AppSizes.tinggiTitikSambutan,
        );

    double lebarTitik(int i) => tester
        .widget<AnimatedContainer>(titik().at(i))
        .constraints!
        .maxWidth;

    expect(titik(), findsNWidgets(5));
    expect(lebarTitik(0), AppSizes.lebarTitikAktifSambutan);
    expect(lebarTitik(1), AppSizes.tinggiTitikSambutan);

    await lanjut(tester);
    expect(lebarTitik(0), AppSizes.tinggiTitikSambutan);
    expect(lebarTitik(1), AppSizes.lebarTitikAktifSambutan);
  });

  testWidgets('Lewati dari layar 1 dan layar 3 langsung membuka layar target',
      (tester) async {
    ukuranLayar(tester, const Size(1080, 2400), rasio: 2.0);

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    await lanjut(tester);
    await lanjut(tester);
    expect(find.text(judulLayar[2]), findsOneWidget);

    await tester.tap(find.byKey(const Key('tombol_lewati')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kolom_target_bulanan')), findsOneWidget);
    expect(find.byKey(const Key('tombol_nanti_saja')), findsOneWidget);
  });

  testWidgets('tombol Lewati langsung membuka layar target pengeluaran',
      (tester) async {
    ukuranLayar(tester, const Size(1080, 2400), rasio: 2.0);

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    // Di layar 1 langsung tekan Lewati
    expect(find.byKey(const Key('tombol_lewati')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tombol_lewati')));
    await tester.pumpAndSettle();

    // Harus masuk layar target pengeluaran
    expect(find.byKey(const Key('kolom_target_bulanan')), findsOneWidget);
    expect(find.byKey(const Key('tombol_simpan_target')), findsOneWidget);
    expect(find.byKey(const Key('tombol_nanti_saja')), findsOneWidget);
  });

  testWidgets('perkenalan selesai: penanda tersimpan dan tidak kembali ke sambutan',
      (tester) async {
    ukuranLayar(tester, const Size(1080, 2400), rasio: 2.0);

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await lanjut(tester);
    }
    await tester.tap(find.byKey(const Key('tombol_nanti_saja')));
    await tester.pumpAndSettle();

    expect(repo._sudahOnboarding, isTrue);
    expect(find.text('Beranda Dummy'), findsOneWidget);
    expect(find.text(judulLayar[0]), findsNothing);
  });

  for (final ukuran in const [Size(360, 640), Size(411, 914)]) {
    testWidgets(
        'bebas overflow di ${ukuran.width.toInt()}x${ukuran.height.toInt()} untuk kelima layar sambutan',
        (tester) async {
      ukuranLayar(tester, ukuran);

      await tester.pumpWidget(buatHalamanUji());
      await tester.pumpAndSettle();

      for (var i = 0; i < judulLayar.length; i++) {
        expect(find.text(judulLayar[i]), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'layar ${i + 1}');
        if (i < judulLayar.length - 1) await lanjut(tester);
      }
    });
  }

  testWidgets('tidak ada karakter tanda pisah panjang em dash di teks sambutan',
      (tester) async {
    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    for (var i = 0; i < judulLayar.length; i++) {
      expect(find.textContaining('—'), findsNothing);
      if (i < judulLayar.length - 1) await lanjut(tester);
    }
  });

  testWidgets(
      'layar target: tata letak tanpa KartuBukuTulis, teks baru tanpa kata "mengubahnya nanti", dan tombol simpan nonaktif saat kosong',
      (tester) async {
    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    // Buka layar target
    await tester.tap(find.byKey(const Key('tombol_lewati')));
    await tester.pumpAndSettle();

    // 1. Tidak memakai KartuBukuTulis
    expect(find.byType(KartuBukuTulis), findsNothing);

    // 2. Susunan ikon & badge & judul & teks baru
    expect(find.byIcon(Icons.track_changes_rounded), findsOneWidget);
    expect(find.text('LANGKAH TERAKHIR'), findsOneWidget);
    expect(
      find.textContaining('Tentukan Target', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Bulanan', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text(
        'Berapa batas maksimal pengeluaranmu dalam sebulan? Tidak harus pas, cukup perkiraan kasar dulu.',
      ),
      findsOneWidget,
    );
    // Teks lama tidak ada
    expect(find.textContaining('mengubahnya nanti'), findsNothing);

    // 3. Memakai KolomInputNominal
    expect(find.byType(KolomInputNominal), findsOneWidget);

    // 4. Tombol Simpan nonaktif saat nominal kosong
    final tombolSimpan = tester.widget<TombolStabilo>(
      find.byKey(const Key('tombol_simpan_target')),
    );
    expect(tombolSimpan.onPressed, isNull);

    // 5. Tombol Nanti saja berupa TextButton tepat di atas Simpan Target
    expect(find.byKey(const Key('tombol_nanti_saja')), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Nanti saja'), findsOneWidget);
  });

  testWidgets(
      'layar target: ketik 2000000 tampil "Rp2.000.000" dan tersimpan angka murni 2000000',
      (tester) async {
    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    // Buka layar target
    await tester.tap(find.byKey(const Key('tombol_lewati')));
    await tester.pumpAndSettle();

    final inputNominal = find.descendant(
      of: find.byKey(const Key('kolom_target_bulanan')),
      matching: find.byType(TextFormField),
    );
    expect(inputNominal, findsOneWidget);

    // Ketik 2000000
    await tester.enterText(inputNominal, '2000000');
    await tester.pumpAndSettle();

    // Tampil Rp2.000.000
    expect(find.text('Rp2.000.000'), findsOneWidget);

    // Tombol simpan kini aktif
    final tombolSimpan = tester.widget<TombolStabilo>(
      find.byKey(const Key('tombol_simpan_target')),
    );
    expect(tombolSimpan.onPressed, isNotNull);

    // Simpan target
    await tester.tap(find.byKey(const Key('tombol_simpan_target')));
    await tester.pumpAndSettle();

    // Tersimpan angka murni tanpa titik
    expect(repo._target, equals(2000000));
    expect(repo._sudahOnboarding, isTrue);
  });

  testWidgets(
      'layar target: tidak overflow pada 360x640 (devicePixelRatio 1.0) termasuk saat keyboard terbuka (viewInsets 300)',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    // Buka layar target
    await tester.tap(find.byKey(const Key('tombol_lewati')));
    await tester.pumpAndSettle();

    expect(find.byType(KartuBukuTulis), findsNothing);
    expect(tester.takeException(), isNull);

    // Buka keyboard (viewInsets bottom 300)
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() => tester.view.resetViewInsets());
    await tester.pumpAndSettle();

    // Tidak ada overflow exception
    expect(tester.takeException(), isNull);

    // Tombol simpan target dan nanti saja tetap terlihat di atas keyboard
    expect(find.byKey(const Key('tombol_simpan_target')), findsOneWidget);
    expect(find.byKey(const Key('tombol_nanti_saja')), findsOneWidget);

    // Isi bisa digulir
    await tester.drag(find.text('LANGKAH TERAKHIR'), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'layar target: tombol nanti saja menyelesaikan onboarding tanpa menyimpan target bulanan',
      (tester) async {
    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    // Buka layar target
    await tester.tap(find.byKey(const Key('tombol_lewati')));
    await tester.pumpAndSettle();

    // Tekan tombol nanti saja
    await tester.tap(find.byKey(const Key('tombol_nanti_saja')));
    await tester.pumpAndSettle();

    // Selesai onboarding, target tetap null
    expect(repo._target, isNull);
    expect(repo._sudahOnboarding, isTrue);
  });
}
