import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final _controller = StreamController<CadanganInfo?>.broadcast();
  RencanaCadangan rencana = const RencanaCadangan();
  int jumlahCadangkan = 0;

  bool lemparGalatPulihkan = false;

  @override
  Stream<CadanganInfo?> pantauCadanganTerakhir(String uid) =>
      _controller.stream;

  @override
  Future<CadanganInfo?> ambilCadanganTerakhir(String uid) async => null;

  @override
  Future<RencanaCadangan> siapkanCadangan(String uid) async => rencana;

  @override
  Future<void> cadangkanData(String uid) async => jumlahCadangkan++;

  @override
  Future<CadanganInfo> pulihkanData(String uid) async {
    if (lemparGalatPulihkan) {
      throw const PerangkatTidakKosongException();
    }
    return const CadanganInfo();
  }

  void dispose() => _controller.close();
}

void main() {
  final sl = GetIt.instance;
  late _FakeCadanganRepository repo;

  setUp(() async {
    await sl.reset();
    repo = _FakeCadanganRepository();
    sl.registerFactory<CadanganCubit>(
      () => CadanganCubit(cadanganRepository: repo),
    );
  });

  tearDown(() async {
    repo.dispose();
    await sl.reset();
  });

  Future<void> bukaHalamanAkun(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider(
          create: (_) => AkunCubit(akunRepository: _FakeAkunRepository()),
          child: const HalamanAkun(
            pengguna: PenggunaEntity(uid: 'uid-uji', email: 'uji@insap.id'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tekanCadangkan(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('tombol_cadangkan')));
    await tester.tap(find.byKey(const Key('tombol_cadangkan')));
    await tester.pumpAndSettle();
  }

  group('Tombol Cadangkan pada HalamanAkun', () {
    testWidgets(
      'perangkat kosong menampilkan dialog penolakan tanpa mencadangkan',
      (tester) async {
        repo.rencana = const RencanaCadangan(
          transaksi: SelisihKoleksi(jumlahAwan: 5, akanDihapus: 5),
          refleksi: SelisihKoleksi(jumlahAwan: 2, akanDihapus: 2),
        );
        await bukaHalamanAkun(tester);
        await tekanCadangkan(tester);

        expect(
          find.byKey(const Key('dialog_perangkat_kosong')),
          findsOneWidget,
        );
        expect(
          find.text('Awan menyimpan 5 transaksi dan 2 refleksi.'),
          findsOneWidget,
        );
        expect(repo.jumlahCadangkan, 0);

        // Arahan ke Pulihkan Data membuka dialog konfirmasi pemulihan
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('dialog_perangkat_kosong')),
            matching: find.text('Pulihkan Data'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pulihkan Data dari Awan?'), findsOneWidget);
        expect(repo.jumlahCadangkan, 0);
      },
    );

    testWidgets(
      'pasang ulang + 1 transaksi baru menampilkan jumlah dihapus dan ditimpa',
      (tester) async {
        repo.rencana = const RencanaCadangan(
          transaksi: SelisihKoleksi(
            jumlahLokal: 1,
            jumlahAwan: 5,
            akanDihapus: 4,
            akanDitimpa: 1,
          ),
          refleksi: SelisihKoleksi(jumlahAwan: 2, akanDihapus: 2),
        );
        await bukaHalamanAkun(tester);
        await tekanCadangkan(tester);

        expect(
          find.byKey(const Key('dialog_konfirmasi_cadangkan')),
          findsOneWidget,
        );
        expect(find.text('Transaksi: 4 dihapus, 1 ditimpa'), findsOneWidget);
        expect(find.text('Refleksi: 2 dihapus'), findsOneWidget);
        expect(find.textContaining('Kategori:'), findsNothing);

        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(repo.jumlahCadangkan, 0);

        await tekanCadangkan(tester);
        await tester.tap(find.text('Tetap Cadangkan'));
        await tester.pumpAndSettle();
        expect(repo.jumlahCadangkan, 1);
      },
    );

    testWidgets('hanya penambahan data langsung dicadangkan tanpa dialog', (
      tester,
    ) async {
      repo.rencana = const RencanaCadangan(
        transaksi: SelisihKoleksi(jumlahLokal: 3, jumlahAwan: 2),
      );
      await bukaHalamanAkun(tester);
      await tekanCadangkan(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.jumlahCadangkan, 1);
    });
  });

  group('Tombol Pulihkan pada HalamanAkun', () {
    testWidgets(
      'menampilkan pesan ramah penolakan bila perangkat tidak kosong',
      (tester) async {
        repo.lemparGalatPulihkan = true;
        await bukaHalamanAkun(tester);

        await tester.ensureVisible(find.byKey(const Key('tombol_pulihkan')));
        await tester.tap(find.byKey(const Key('tombol_pulihkan')));
        await tester.pumpAndSettle();

        expect(find.text('Pulihkan Data dari Awan?'), findsOneWidget);

        await tester.tap(find.text('Pulihkan'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Data di perangkat ini masih ada. Pemulihan hanya untuk perangkat kosong, supaya data barumu tidak tertimpa.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
