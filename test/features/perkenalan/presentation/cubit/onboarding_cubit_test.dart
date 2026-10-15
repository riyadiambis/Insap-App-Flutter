import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';
import 'package:insap/features/perkenalan/presentation/cubit/onboarding_cubit.dart';
import 'package:insap/features/perkenalan/presentation/cubit/onboarding_state.dart';

class _FakePengaturanRepository implements PengaturanRepository {
  bool statusOnboarding = false;
  int? targetBulanan;
  final Map<String, String> _pengaturanLain = {};

  @override
  Future<bool> bacaStatusOnboarding() async => statusOnboarding;

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {
    statusOnboarding = selesai;
  }

  @override
  Future<int?> bacaTargetBulanan() async => targetBulanan;

  @override
  Future<void> simpanTargetBulanan(int target) async {
    targetBulanan = target;
  }

  @override
  Future<String?> bacaPengaturan(String kunci) async => _pengaturanLain[kunci];

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {
    _pengaturanLain[kunci] = nilai;
  }
}

void main() {
  late _FakePengaturanRepository fakeRepository;
  late OnboardingCubit cubit;

  setUp(() {
    fakeRepository = _FakePengaturanRepository();
    cubit = OnboardingCubit(pengaturanRepository: fakeRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('OnboardingCubit (ISSUE-23)', () {
    test('state awal adalah OnboardingInitial', () {
      expect(cubit.state, const OnboardingInitial());
    });

    test(
      'selesai menyimpan "1" dan target tersimpan saat simpanTargetDanSelesai dipanggil',
      () async {
        await cubit.simpanTargetDanSelesai(3000000);

        expect(fakeRepository.statusOnboarding, isTrue);
        expect(fakeRepository.targetBulanan, 3000000);
        expect(
          cubit.state,
          const OnboardingSuccess(selesai: true, targetBulanan: 3000000),
        );
      },
    );

    test(
      '"Nanti saja" (lewatiTargetDanSelesai) menyimpan "1" dan TIDAK menyimpan target',
      () async {
        await cubit.lewatiTargetDanSelesai();

        expect(fakeRepository.statusOnboarding, isTrue);
        expect(fakeRepository.targetBulanan, isNull);
        expect(
          cubit.state,
          const OnboardingSuccess(selesai: true, targetBulanan: null),
        );
      },
    );

    test('periksaStatus mengalirkan status onboarding dan target saat ini', () async {
      fakeRepository.statusOnboarding = true;
      fakeRepository.targetBulanan = 4000000;

      await cubit.periksaStatus();

      expect(
        cubit.state,
        const OnboardingSuccess(selesai: true, targetBulanan: 4000000),
      );
    });
  });
}
