import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/widgets/kartu_buku_tulis.dart';
import 'package:insap/features/perkenalan/domain/repositories/pengaturan_repository.dart';
import 'package:insap/features/perkenalan/presentation/cubit/onboarding_cubit.dart';
import 'package:insap/features/perkenalan/presentation/pages/halaman_perkenalan.dart';

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
    return MaterialApp(
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: const HalamanPerkenalan(),
      ),
    );
  }

  testWidgets(
      'tombol Lewati tampil di 3 layar dan layar 3 memuat kata refleksi',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    // Layar 1
    expect(find.byKey(const Key('tombol_lewati')), findsOneWidget);
    expect(find.text('KENALAN DULU'), findsOneWidget);
    expect(
      find.textContaining('Sadar Sebelum', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Boncos', findRichText: true), findsOneWidget);
    expect(
      find.textContaining(
        'Insap bantu kamu sadar uangmu habis',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('ke mana', findRichText: true),
      findsOneWidget,
    );

    // Geser ke Layar 2 via tombol Lanjut
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();

    // Layar 2
    expect(find.byKey(const Key('tombol_lewati')), findsOneWidget);
    expect(find.text('CATAT'), findsOneWidget);
    expect(
      find.textContaining('Catat Cepat', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Dua Langkah', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(KotakLangkah), findsNWidgets(2));
    expect(find.text('Isi nominal'), findsOneWidget);
    expect(find.text('Contoh Rp15.000'), findsOneWidget);
    expect(find.text('Pilih kategori'), findsOneWidget);
    expect(
      find.text('Makan, transport, nongkrong, dan lainnya'),
      findsOneWidget,
    );

    // Geser ke Layar 3 via tombol Lanjut
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();

    // Layar 3
    expect(find.byKey(const Key('tombol_lewati')), findsOneWidget);
    expect(find.text('TIAP AKHIR PEKAN'), findsOneWidget);
    expect(
      find.textContaining('Refleksi', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Mingguan', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(KotakLangkah), findsNWidgets(3));
    expect(find.text('Lihat ulang'), findsOneWidget);
    expect(find.text('Pengeluaran sepekan terakhir'), findsOneWidget);
    expect(find.text('Butuh atau pengen?'), findsOneWidget);
    expect(
      find.text('Tandai belanja yang sebenarnya bisa ditahan'),
      findsOneWidget,
    );
    expect(find.text('Tetapkan target'), findsOneWidget);
    expect(find.text('Batas pengeluaran untuk pekan depan'), findsOneWidget);
    expect(find.text('Santai, tanpa menghakimi.'), findsOneWidget);
  });

  testWidgets('tombol Lewati langsung membuka layar target pengeluaran',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

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

  testWidgets(
      'bebas overflow pada layar kecil 360x640 untuk ketiga layar perkenalan dan tinggi kartu sama',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    // Layar 1
    expect(find.text('KENALAN DULU'), findsOneWidget);
    expect(
      find.textContaining('Sadar Sebelum', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Boncos', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);

    final tinggiKartuLayar1 =
        tester.getSize(find.byType(KartuBukuTulis).first).height;
    expect(tinggiKartuLayar1, greaterThan(0));

    // Pindah ke Layar 2
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();

    // Layar 2
    expect(find.text('CATAT'), findsOneWidget);
    expect(find.byType(KotakLangkah), findsNWidgets(2));
    expect(find.text('Isi nominal'), findsOneWidget);
    expect(find.text('Contoh Rp15.000'), findsOneWidget);
    expect(find.text('Pilih kategori'), findsOneWidget);
    expect(
      find.text('Makan, transport, nongkrong, dan lainnya'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final tinggiKartuLayar2 =
        tester.getSize(find.byType(KartuBukuTulis).first).height;
    expect(tinggiKartuLayar2, equals(tinggiKartuLayar1));

    // Pindah ke Layar 3
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();

    // Layar 3
    expect(find.text('TIAP AKHIR PEKAN'), findsOneWidget);
    expect(find.byType(KotakLangkah), findsNWidgets(3));
    expect(find.text('Lihat ulang'), findsOneWidget);
    expect(find.text('Pengeluaran sepekan terakhir'), findsOneWidget);
    expect(find.text('Butuh atau pengen?'), findsOneWidget);
    expect(
      find.text('Tandai belanja yang sebenarnya bisa ditahan'),
      findsOneWidget,
    );
    expect(find.text('Tetapkan target'), findsOneWidget);
    expect(find.text('Batas pengeluaran untuk pekan depan'), findsOneWidget);
    expect(find.text('Santai, tanpa menghakimi.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final tinggiKartuLayar3 =
        tester.getSize(find.byType(KartuBukuTulis).first).height;
    expect(tinggiKartuLayar3, equals(tinggiKartuLayar1));
  });

  testWidgets(
      'bebas overflow pada layar standar 411x914 untuk ketiga layar perkenalan',
      (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    // Layar 1
    expect(find.text('KENALAN DULU'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Layar 2
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();
    expect(find.text('CATAT'), findsOneWidget);
    expect(find.byType(KotakLangkah), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    // Layar 3
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();
    expect(find.text('TIAP AKHIR PEKAN'), findsOneWidget);
    expect(find.byType(KotakLangkah), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tidak ada karakter tanda pisah panjang em dash di teks perkenalan',
      (tester) async {
    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    // Layar 1
    expect(find.textContaining('—'), findsNothing);

    // Layar 2
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();
    expect(find.textContaining('—'), findsNothing);

    // Layar 3
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();
    expect(find.textContaining('—'), findsNothing);
  });
}
