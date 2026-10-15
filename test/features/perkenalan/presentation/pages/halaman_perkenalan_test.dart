import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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

    await tester.pumpWidget(buatHalamanUji());
    await tester.pumpAndSettle();

    // Layar 1
    expect(find.byKey(const Key('tombol_lewati')), findsOneWidget);
    expect(find.textContaining('Sadar Sebelum Boncos'), findsOneWidget);
    expect(
      find.textContaining(
        'Insap bantu kamu sadar uangmu habis ke mana, sebelum dompet menipis.',
      ),
      findsOneWidget,
    );

    // Geser ke Layar 2 via tombol Lanjut
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();

    // Layar 2
    expect(find.byKey(const Key('tombol_lewati')), findsOneWidget);
    expect(find.textContaining('Catat Cepat Dua Langkah'), findsOneWidget);

    // Geser ke Layar 3 via tombol Lanjut
    await tester.tap(find.byKey(const Key('tombol_lanjut')));
    await tester.pumpAndSettle();

    // Layar 3
    expect(find.byKey(const Key('tombol_lewati')), findsOneWidget);
    expect(find.textContaining('Refleksi Mingguan'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is Text && widget.data != null) {
          return widget.data!.toLowerCase().contains('refleksi');
        }
        return false;
      }),
      findsWidgets,
    );
  });

  testWidgets('tombol Lewati langsung membuka layar target pengeluaran',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

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
}
