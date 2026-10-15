import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_state.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';
import 'package:insap/features/pengaturan/domain/usecases/ambil_target_bulanan.dart';
import 'package:insap/features/pengaturan/domain/usecases/hitung_perbandingan_target.dart';
import 'package:insap/features/pengaturan/domain/usecases/simpan_target_bulanan.dart';
import 'package:insap/features/transaksi/domain/entities/rincian_pengeluaran_entity.dart';
import 'package:insap/features/transaksi/domain/entities/ringkasan_pekan_entity.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_rincian_kategori.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';

class _FakePengaturanRepo implements PengaturanRepository {
  int? target;

  @override
  Future<bool> bacaStatusOnboarding() async => true;

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {}

  @override
  Future<int?> bacaTargetBulanan() async => target;

  @override
  Future<void> simpanTargetBulanan(int t) async {
    target = t;
  }

  @override
  Future<String?> bacaPengaturan(String kunci) async => null;

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {}
}

class _FakeAmbilRingkasanPekan implements AmbilRingkasanPekan {
  @override
  Future<RingkasanPekanEntity> call() async {
    return const RingkasanPekanEntity(
      totalMingguIni: 200000,
      totalMingguLalu: 150000,
      selisihMingguan: 50000,
      transaksiTerakhir: [],
      kuotaPindai: 10,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAmbilRincianKategori implements AmbilRincianKategori {
  @override
  Future<RincianPengeluaranEntity> call() async {
    return const RincianPengeluaranEntity(
      totalBulanIni: 1200000,
      kategoriPekanIni: [],
      kategoriBulanIni: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BerandaCubit Target Bulanan (ISSUE-25)', () {
    late _FakePengaturanRepo pengaturanRepo;
    late AmbilTargetBulanan ambilTarget;
    late SimpanTargetBulanan simpanTarget;
    late BerandaCubit cubit;

    setUp(() {
      pengaturanRepo = _FakePengaturanRepo();
      ambilTarget = AmbilTargetBulanan(pengaturanRepo);
      simpanTarget = SimpanTargetBulanan(pengaturanRepo);

      cubit = BerandaCubit(
        ambilRingkasanPekan: _FakeAmbilRingkasanPekan(),
        ambilRincianKategori: _FakeAmbilRincianKategori(),
        ambilTargetBulanan: ambilTarget,
        simpanTargetBulanan: simpanTarget,
        hitungPerbandinganTarget: const HitungPerbandinganTarget(),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('muatRingkasan memuat target bulanan dan menghitung perbandingan', () async {
      pengaturanRepo.target = 2000000;

      await cubit.muatRingkasan();

      expect(cubit.state, isA<BerandaLoaded>());
      final state = cubit.state as BerandaLoaded;
      expect(state.targetBulanan, equals(2000000));
      expect(state.perbandinganTarget.adaTarget, isTrue);
      expect(state.perbandinganTarget.totalBulanIni, equals(1200000));
      expect(state.perbandinganTarget.sisa, equals(800000));
      expect(state.perbandinganTarget.persen, equals(0.6));
    });

    test('ubahTarget menyimpan target baru ke repository dan memuat ulang state', () async {
      pengaturanRepo.target = 2000000;
      await cubit.muatRingkasan();

      // Ubah target menjadi 3.000.000
      await cubit.ubahTarget(3000000);

      expect(pengaturanRepo.target, equals(3000000));
      expect(cubit.state, isA<BerandaLoaded>());
      final state = cubit.state as BerandaLoaded;
      expect(state.targetBulanan, equals(3000000));
      expect(state.perbandinganTarget.sisa, equals(1800000));
      expect(state.perbandinganTarget.persen, equals(0.4));
    });
  });
}
