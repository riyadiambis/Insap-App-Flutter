import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/avatar_profil.dart';
import 'package:insap/features/akun/domain/entities/cadangan_info.dart';
import 'package:insap/features/akun/domain/entities/pengguna_entity.dart';
import 'package:insap/features/akun/domain/entities/rencana_cadangan.dart';
import 'package:insap/features/akun/domain/repositories/akun_repository.dart';
import 'package:insap/features/akun/domain/repositories/cadangan_repository.dart';
import 'package:insap/features/akun/presentation/cubit/akun_cubit.dart';
import 'package:insap/features/akun/presentation/cubit/cadangan_cubit.dart';
import 'package:insap/features/akun/presentation/pages/halaman_akun.dart';

class _FakeAkunRepository implements AkunRepository {
  @override
  Stream<PenggunaEntity?> pantauPengguna() => const Stream.empty();

  @override
  Future<PenggunaEntity?> ambilPenggunaSaatIni() async => null;

  @override
  Future<PenggunaEntity> daftarDenganEmail({
    required String email,
    required String kataSandi,
  }) async => PenggunaEntity(uid: '123', email: email);

  @override
  Future<PenggunaEntity> masukDenganEmail({
    required String email,
    required String kataSandi,
  }) async => PenggunaEntity(uid: '123', email: email);

  @override
  Future<PenggunaEntity?> masukDenganGoogle() async => null;

  @override
  Future<void> kirimResetKataSandi(String email) async {}

  @override
  Future<void> keluar() async {}
}

class _FakeCadanganRepository implements CadanganRepository {
  @override
  Stream<CadanganInfo?> pantauCadanganTerakhir(String uid) =>
      const Stream.empty();

  @override
  Future<CadanganInfo?> ambilCadanganTerakhir(String uid) async => null;

  @override
  Future<RencanaCadangan> siapkanCadangan(String uid) async =>
      const RencanaCadangan();

  @override
  Future<void> cadangkanData(String uid) async {}

  @override
  Future<CadanganInfo> pulihkanData(String uid) async => const CadanganInfo();
}

void main() {
  final sl = GetIt.instance;

  setUp(() async {
    await sl.reset();
    sl.registerFactory<CadanganCubit>(
      () => CadanganCubit(cadanganRepository: _FakeCadanganRepository()),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  group('HalamanAkun Tampilan Profil', () {
    testWidgets(
      'menampilkan namaTampilan dan email jika namaTampilan tersedia',
      (tester) async {
        const pengguna = PenggunaEntity(
          uid: 'uid-1',
          email: 'riyadi@google.com',
          namaTampilan: 'Riyadi Ambis',
          fotoUrl: 'https://example.com/riyadi.png',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: BlocProvider(
              create: (_) => AkunCubit(akunRepository: _FakeAkunRepository()),
              child: const HalamanAkun(pengguna: pengguna),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Riyadi Ambis'), findsOneWidget);
        expect(find.text('riyadi@google.com'), findsOneWidget);
        expect(find.byType(AvatarProfil), findsOneWidget);
      },
    );

    testWidgets(
      'hanya menampilkan surel tanpa teks nama jika namaTampilan null',
      (tester) async {
        const pengguna = PenggunaEntity(
          uid: 'uid-2',
          email: 'polos@insap.id',
          namaTampilan: null,
          fotoUrl: null,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: BlocProvider(
              create: (_) => AkunCubit(akunRepository: _FakeAkunRepository()),
              child: const HalamanAkun(pengguna: pengguna),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('polos@insap.id'), findsOneWidget);
        expect(find.byType(AvatarProfil), findsOneWidget);
        // Memastikan tidak ada placeholder teks nama sembarangan
        expect(find.text('null'), findsNothing);
      },
    );
  });
}
