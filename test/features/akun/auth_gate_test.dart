import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/akun/domain/entities/cadangan_info.dart';
import 'package:insap/features/akun/domain/entities/pengguna_entity.dart';
import 'package:insap/features/akun/domain/entities/rencana_cadangan.dart';
import 'package:insap/features/akun/domain/repositories/akun_repository.dart';
import 'package:insap/features/akun/domain/repositories/cadangan_repository.dart';
import 'package:insap/features/akun/presentation/cubit/akun_cubit.dart';
import 'package:insap/features/akun/presentation/cubit/cadangan_cubit.dart';
import 'package:insap/features/akun/presentation/pages/auth_gate.dart';
import 'package:insap/features/akun/presentation/pages/halaman_akun.dart';
import 'package:insap/features/akun/presentation/pages/halaman_masuk.dart';

class _FakeAkunRepository implements AkunRepository {
  final _controller = StreamController<PenggunaEntity?>.broadcast();

  @override
  Stream<PenggunaEntity?> pantauPengguna() => _controller.stream;

  @override
  Future<PenggunaEntity?> ambilPenggunaSaatIni() async => null;

  @override
  Future<PenggunaEntity> daftarDenganEmail({
    required String email,
    required String kataSandi,
  }) async {
    return PenggunaEntity(uid: '123', email: email);
  }

  @override
  Future<PenggunaEntity> masukDenganEmail({
    required String email,
    required String kataSandi,
  }) async {
    return PenggunaEntity(uid: '123', email: email);
  }

  @override
  Future<PenggunaEntity?> masukDenganGoogle() async => null;

  @override
  Future<void> kirimResetKataSandi(String email) async {}

  @override
  Future<void> keluar() async {}

  void dispose() {
    _controller.close();
  }
}

class _FakeCadanganRepository implements CadanganRepository {
  final _controller = StreamController<CadanganInfo?>.broadcast();

  @override
  Stream<CadanganInfo?> pantauCadanganTerakhir(String uid) =>
      _controller.stream;

  @override
  Future<CadanganInfo?> ambilCadanganTerakhir(String uid) async => null;

  @override
  Future<RencanaCadangan> siapkanCadangan(String uid) async =>
      const RencanaCadangan();

  @override
  Future<void> cadangkanData(String uid) async {}

  @override
  Future<CadanganInfo> pulihkanData(String uid) async => const CadanganInfo();

  void dispose() {
    _controller.close();
  }
}

void main() {
  final sl = GetIt.instance;
  late _FakeAkunRepository fakeAkunRepo;
  late _FakeCadanganRepository fakeCadanganRepo;
  late StreamController<PenggunaEntity?> streamController;

  setUp(() async {
    await sl.reset();
    fakeAkunRepo = _FakeAkunRepository();
    fakeCadanganRepo = _FakeCadanganRepository();
    streamController = StreamController<PenggunaEntity?>.broadcast();

    sl.registerLazySingleton<AkunRepository>(() => fakeAkunRepo);
    sl.registerFactory<AkunCubit>(
      () => AkunCubit(akunRepository: sl<AkunRepository>()),
    );
    sl.registerLazySingleton<CadanganRepository>(() => fakeCadanganRepo);
    sl.registerFactory<CadanganCubit>(
      () => CadanganCubit(cadanganRepository: sl<CadanganRepository>()),
    );
  });

  tearDown(() async {
    streamController.close();
    fakeAkunRepo.dispose();
    fakeCadanganRepo.dispose();
    await sl.reset();
  });

  Widget buatWidgetUji(Stream<PenggunaEntity?> stream) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: AuthGate(streamPengguna: stream),
    );
  }

  group('AuthGate Widget Test (StreamBuilder + authStateChanges)', () {
    testWidgets(
      'menampilkan HalamanMasuk ketika stream status auth bernilai null',
      (tester) async {
        await tester.pumpWidget(buatWidgetUji(streamController.stream));
        // Status awal belum ada pengguna masuk
        streamController.add(null);
        await tester.pumpAndSettle();

        expect(find.byType(HalamanMasuk), findsOneWidget);
        expect(find.byType(HalamanAkun), findsNothing);
      },
    );

    testWidgets(
      'menampilkan HalamanAkun secara reaktif ketika stream status auth memancarkan pengguna masuk',
      (tester) async {
        await tester.pumpWidget(buatWidgetUji(streamController.stream));

        // Pengguna berhasil login di Firebase
        const pengguna = PenggunaEntity(
          uid: 'uid-reaktif',
          email: 'pengguna@insap.id',
        );
        streamController.add(pengguna);
        await tester.pumpAndSettle();

        expect(find.byType(HalamanAkun), findsOneWidget);
        expect(find.byType(HalamanMasuk), findsNothing);
        expect(find.text('pengguna@insap.id'), findsOneWidget);
      },
    );

    testWidgets(
      'beralih dari HalamanAkun ke HalamanMasuk ketika pengguna keluar (stream berubah jadi null)',
      (tester) async {
        await tester.pumpWidget(buatWidgetUji(streamController.stream));

        // Mula-mula masuk
        const pengguna = PenggunaEntity(
          uid: 'uid-logout',
          email: 'keluar@insap.id',
        );
        streamController.add(pengguna);
        await tester.pumpAndSettle();
        expect(find.byType(HalamanAkun), findsOneWidget);

        // Lalu logout
        streamController.add(null);
        await tester.pumpAndSettle();

        expect(find.byType(HalamanMasuk), findsOneWidget);
        expect(find.byType(HalamanAkun), findsNothing);
      },
    );
  });
}
