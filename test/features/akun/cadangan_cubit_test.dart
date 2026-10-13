import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/akun/domain/entities/cadangan_info.dart';
import 'package:insap/features/akun/domain/repositories/cadangan_repository.dart';
import 'package:insap/features/akun/presentation/cubit/cadangan_cubit.dart';
import 'package:insap/features/akun/presentation/cubit/cadangan_state.dart';

class _FakeCadanganRepository implements CadanganRepository {
  final _controller = StreamController<CadanganInfo?>.broadcast();
  bool lemparGalat = false;
  String pesanGalat = 'Gagal memproses cadangan';
  CadanganInfo? mockInfo;

  @override
  Stream<CadanganInfo?> pantauCadanganTerakhir(String uid) =>
      _controller.stream;

  @override
  Future<CadanganInfo?> ambilCadanganTerakhir(String uid) async {
    if (lemparGalat) throw Exception(pesanGalat);
    return mockInfo;
  }

  @override
  Future<void> cadangkanData(String uid) async {
    if (lemparGalat) throw Exception(pesanGalat);
    final info = CadanganInfo(
      waktuCadanganTerakhir: DateTime.now(),
      jumlahTransaksi: 10,
      jumlahKategori: 4,
      jumlahRefleksi: 1,
    );
    mockInfo = info;
    _controller.add(info);
  }

  @override
  Future<CadanganInfo> pulihkanData(String uid) async {
    if (lemparGalat) throw Exception(pesanGalat);
    return mockInfo ??
        CadanganInfo(waktuCadanganTerakhir: DateTime.now(), jumlahTransaksi: 5);
  }

  void close() {
    _controller.close();
  }
}

void main() {
  late _FakeCadanganRepository repo;
  late CadanganCubit cubit;

  setUp(() {
    repo = _FakeCadanganRepository();
    cubit = CadanganCubit(cadanganRepository: repo);
  });

  tearDown(() {
    cubit.close();
    repo.close();
  });

  group('CadanganCubit', () {
    test('state awal adalah CadanganAwal', () {
      expect(cubit.state, isA<CadanganAwal>());
    });

    test(
      'cadangkanData sukses memancarkan CadanganMemuat dan CadanganSukses',
      () async {
        final expected = [
          isA<CadanganMemuat>(),
          isA<CadanganSukses>().having(
            (s) => s.pesan,
            'pesan',
            contains('berhasil dicadangkan'),
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expected));

        await cubit.cadangkanData('uid-user-1');
      },
    );

    test(
      'cadangkanData gagal memancarkan CadanganMemuat dan CadanganGalat',
      () async {
        repo.lemparGalat = true;
        repo.pesanGalat = 'Koneksi jaringan terputus';

        final expected = [
          isA<CadanganMemuat>(),
          isA<CadanganGalat>().having(
            (s) => s.pesan,
            'pesan',
            contains('Koneksi jaringan terputus'),
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expected));

        await cubit.cadangkanData('uid-user-1');
      },
    );

    test(
      'pulihkanData sukses memancarkan CadanganMemuat dan CadanganPulihSukses',
      () async {
        repo.mockInfo = CadanganInfo(
          waktuCadanganTerakhir: DateTime(2026, 10, 14),
          jumlahTransaksi: 15,
        );

        final expected = [
          isA<CadanganMemuat>(),
          isA<CadanganPulihSukses>().having(
            (s) => s.info.jumlahTransaksi,
            'jumlahTransaksi',
            15,
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expected));

        await cubit.pulihkanData('uid-user-1');
      },
    );

    test(
      'pulihkanData gagal memancarkan CadanganMemuat dan CadanganGalat',
      () async {
        repo.lemparGalat = true;
        repo.pesanGalat = 'Belum ada data cadangan di akun ini.';

        final expected = [
          isA<CadanganMemuat>(),
          isA<CadanganGalat>().having(
            (s) => s.pesan,
            'pesan',
            contains('Belum ada data cadangan'),
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expected));

        await cubit.pulihkanData('uid-user-1');
      },
    );

    test('resetStatus mengembalikan state ke CadanganAwal', () {
      cubit.resetStatus();
      expect(cubit.state, isA<CadanganAwal>());
    });

    test('pantauCadanganTerakhir mengalirkan data secara reaktif', () async {
      expectLater(
        cubit.pantauCadanganTerakhir('uid-user-1'),
        emits(
          isA<CadanganInfo>().having(
            (i) => i.jumlahTransaksi,
            'jumlahTransaksi',
            10,
          ),
        ),
      );

      await cubit.cadangkanData('uid-user-1');
    });
  });
}
