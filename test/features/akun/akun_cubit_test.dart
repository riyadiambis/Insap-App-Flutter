import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/akun/domain/entities/pengguna_entity.dart';
import 'package:insap/features/akun/domain/repositories/akun_repository.dart';
import 'package:insap/features/akun/presentation/cubit/akun_cubit.dart';
import 'package:insap/features/akun/presentation/cubit/akun_state.dart';

class _FakeAkunRepository implements AkunRepository {
  final _controller = StreamController<PenggunaEntity?>.broadcast();
  bool lemparGalat = false;
  String pesanGalat = 'Terjadi galat autentikasi';

  @override
  Stream<PenggunaEntity?> pantauPengguna() => _controller.stream;

  @override
  Future<PenggunaEntity?> ambilPenggunaSaatIni() async {
    if (lemparGalat) throw Exception(pesanGalat);
    return const PenggunaEntity(uid: 'uid-123', email: 'test@insap.id');
  }

  @override
  Future<PenggunaEntity> masukDenganEmail({
    required String email,
    required String kataSandi,
  }) async {
    if (lemparGalat) throw Exception(pesanGalat);
    final user = PenggunaEntity(uid: 'uid-email', email: email);
    _controller.add(user);
    return user;
  }

  @override
  Future<PenggunaEntity> daftarDenganEmail({
    required String email,
    required String kataSandi,
  }) async {
    if (lemparGalat) throw Exception(pesanGalat);
    final user = PenggunaEntity(uid: 'uid-daftar', email: email);
    _controller.add(user);
    return user;
  }

  @override
  Future<PenggunaEntity?> masukDenganGoogle() async {
    if (lemparGalat) throw Exception(pesanGalat);
    const user = PenggunaEntity(uid: 'uid-google', email: 'google@insap.id');
    _controller.add(user);
    return user;
  }

  @override
  Future<void> kirimResetKataSandi(String email) async {
    if (lemparGalat) throw Exception(pesanGalat);
  }

  @override
  Future<void> keluar() async {
    if (lemparGalat) throw Exception(pesanGalat);
    _controller.add(null);
  }

  void close() {
    _controller.close();
  }
}

void main() {
  late _FakeAkunRepository repo;
  late AkunCubit cubit;

  setUp(() {
    repo = _FakeAkunRepository();
    cubit = AkunCubit(akunRepository: repo);
  });

  tearDown(() {
    cubit.close();
    repo.close();
  });

  group('AkunCubit', () {
    test('state awal adalah AkunAwal sebelum ada pembaruan status auth', () {
      expect(cubit.state, isA<AkunAwal>());
    });

    test(
      'masukDenganEmail sukses memancarkan AkunMemuat dan AkunMasuk',
      () async {
        final expected = [
          isA<AkunMemuat>(),
          isA<AkunMasuk>().having(
            (s) => s.pengguna.email,
            'email',
            'user@insap.id',
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expected));

        await cubit.masukDenganEmail(
          email: 'user@insap.id',
          kataSandi: 'rahasia123',
        );
      },
    );

    test(
      'masukDenganEmail gagal memancarkan AkunMemuat dan AkunGalat',
      () async {
        repo.lemparGalat = true;
        repo.pesanGalat = 'Kata sandi salah';

        final expected = [
          isA<AkunMemuat>(),
          isA<AkunGalat>().having(
            (s) => s.pesan,
            'pesan',
            contains('Kata sandi salah'),
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expected));

        await cubit.masukDenganEmail(
          email: 'user@insap.id',
          kataSandi: 'salah',
        );
      },
    );

    test(
      'daftarDenganEmail sukses memancarkan AkunMemuat dan AkunMasuk',
      () async {
        final expected = [
          isA<AkunMemuat>(),
          isA<AkunMasuk>().having(
            (s) => s.pengguna.email,
            'email',
            'baru@insap.id',
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expected));

        await cubit.daftarDenganEmail(
          email: 'baru@insap.id',
          kataSandi: 'rahasia123',
        );
      },
    );

    test(
      'daftarDenganEmail gagal memancarkan AkunMemuat dan AkunGalat',
      () async {
        repo.lemparGalat = true;
        repo.pesanGalat = 'Surel sudah dipakai';

        final expected = [
          isA<AkunMemuat>(),
          isA<AkunGalat>().having(
            (s) => s.pesan,
            'pesan',
            contains('Surel sudah dipakai'),
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expected));

        await cubit.daftarDenganEmail(
          email: 'baru@insap.id',
          kataSandi: 'rahasia123',
        );
      },
    );

    test(
      'kirimResetKataSandi sukses memancarkan AkunMemuat dan AkunPesanSukses',
      () async {
        final expected = [
          isA<AkunMemuat>(),
          isA<AkunPesanSukses>().having(
            (s) => s.pesan,
            'pesan',
            contains('Tautan atur ulang kata sandi'),
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expected));

        await cubit.kirimResetKataSandi('user@insap.id');
      },
    );

    test(
      'masukDenganGoogle sukses memancarkan AkunMemuat dan AkunMasuk',
      () async {
        final expected = [
          isA<AkunMemuat>(),
          isA<AkunMasuk>().having((s) => s.pengguna.uid, 'uid', 'uid-google'),
        ];

        expectLater(cubit.stream, emitsInOrder(expected));

        await cubit.masukDenganGoogle();
      },
    );

    test('keluar akun memancarkan AkunMemuat dan AkunKeluar', () async {
      final expected = [isA<AkunMemuat>(), isA<AkunKeluar>()];

      expectLater(cubit.stream, emitsInOrder(expected));

      await cubit.keluar();
    });
  });
}
