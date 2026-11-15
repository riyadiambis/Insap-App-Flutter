import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/tur/tur_cubit.dart';
import 'package:insap/core/tur/tur_state.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';

class _FakePengaturanRepository implements PengaturanRepository {
  final Map<String, String> isi = {};
  bool gagalBaca = false;

  @override
  Future<bool> bacaStatusOnboarding() async => true;

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {}

  @override
  Future<int?> bacaTargetBulanan() async => null;

  @override
  Future<void> simpanTargetBulanan(int target) async {}

  @override
  Future<String?> bacaPengaturan(String kunci) async {
    if (gagalBaca) throw Exception('basis data belum siap');
    return isi[kunci];
  }

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {
    isi[kunci] = nilai;
  }
}

void main() {
  late _FakePengaturanRepository repo;

  TurCubit buatCubit({bool sudahMasuk = false, int jumlahLangkah = 3}) {
    return TurCubit(
      pengaturanRepository: repo,
      jumlahLangkah: jumlahLangkah,
      cekSudahMasuk: () async => sudahMasuk,
    );
  }

  setUp(() {
    repo = _FakePengaturanRepository();
  });

  group('TurCubit', () {
    test('state awal tidak aktif', () {
      final cubit = buatCubit();
      expect(cubit.state, const TurState());
      cubit.close();
    });

    test('periksa memulai petunjuk bila belum pernah selesai', () async {
      final cubit = buatCubit();
      await cubit.periksa();
      expect(cubit.state, const TurState(aktif: true, indeks: 0));
      await cubit.close();
    });

    test('periksa tidak memulai bila sudah pernah selesai', () async {
      repo.isi[TurCubit.kunciSelesai] = '1';
      final cubit = buatCubit();
      await cubit.periksa();
      expect(cubit.state.aktif, isFalse);
      await cubit.close();
    });

    test('periksa tidak memulai bila pengaturan gagal dibaca', () async {
      repo.gagalBaca = true;
      final cubit = buatCubit();
      await cubit.periksa();
      expect(cubit.state.aktif, isFalse);
      await cubit.close();
    });

    test('periksa mencatat pengguna yang sudah masuk akun', () async {
      final cubit = buatCubit(sudahMasuk: true);
      await cubit.periksa();
      expect(cubit.state.sudahMasuk, isTrue);
      await cubit.close();
    });

    test('lanjut dan kembali menggeser langkah', () async {
      final cubit = buatCubit();
      await cubit.periksa();

      cubit.lanjut();
      expect(cubit.state.indeks, 1);

      cubit.kembali();
      expect(cubit.state.indeks, 0);

      // di langkah pertama, kembali tidak berbuat apa-apa
      cubit.kembali();
      expect(cubit.state.indeks, 0);
      await cubit.close();
    });

    test('lanjut di langkah terakhir menutup dan menyimpan penanda', () async {
      final cubit = buatCubit(jumlahLangkah: 2);
      await cubit.periksa();

      cubit.lanjut();
      cubit.lanjut();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.aktif, isFalse);
      expect(repo.isi[TurCubit.kunciSelesai], '1');
      await cubit.close();
    });

    test(
      'selesai (Lewati) menyimpan penanda supaya tidak muncul lagi',
      () async {
        final cubit = buatCubit();
        await cubit.periksa();
        await cubit.selesai();

        expect(cubit.state.aktif, isFalse);
        expect(repo.isi[TurCubit.kunciSelesai], '1');

        await cubit.periksa();
        expect(cubit.state.aktif, isFalse);
        await cubit.close();
      },
    );

    test('mulaiUlang menampilkan lagi walau sudah pernah selesai', () async {
      repo.isi[TurCubit.kunciSelesai] = '1';
      final cubit = buatCubit();
      await cubit.mulaiUlang();
      expect(cubit.state, const TurState(aktif: true, indeks: 0));
      await cubit.close();
    });
  });
}
