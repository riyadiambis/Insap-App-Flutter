import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/akun/domain/entities/pengguna_entity.dart';
import 'package:insap/features/akun/domain/repositories/akun_repository.dart';
import 'package:insap/features/akun/presentation/cubit/akun_cubit.dart';
import 'package:insap/features/akun/presentation/pages/halaman_masuk.dart';

class _FakeAkunRepository implements AkunRepository {
  final _controller = StreamController<PenggunaEntity?>.broadcast();
  String? emailMasuk;
  String? sandiMasuk;
  String? emailDaftar;
  String? sandiDaftar;
  String? emailReset;

  @override
  Stream<PenggunaEntity?> pantauPengguna() => _controller.stream;

  @override
  Future<PenggunaEntity?> ambilPenggunaSaatIni() async => null;

  @override
  Future<PenggunaEntity> daftarDenganEmail({
    required String email,
    required String kataSandi,
  }) async {
    emailDaftar = email;
    sandiDaftar = kataSandi;
    final user = PenggunaEntity(uid: 'uid-daftar', email: email);
    _controller.add(user);
    return user;
  }

  @override
  Future<PenggunaEntity> masukDenganEmail({
    required String email,
    required String kataSandi,
  }) async {
    emailMasuk = email;
    sandiMasuk = kataSandi;
    final user = PenggunaEntity(uid: 'uid-masuk', email: email);
    _controller.add(user);
    return user;
  }

  @override
  Future<PenggunaEntity?> masukDenganGoogle() async => null;

  @override
  Future<void> kirimResetKataSandi(String email) async {
    emailReset = email;
  }

  @override
  Future<void> keluar() async {}

  @override
  Future<void> hapusAkun() async {}

  void dispose() {
    _controller.close();
  }
}

void main() {
  ({
    _FakeAkunRepository repo,
    AkunCubit cubit,
    Widget widget,
  }) siapkanUji(WidgetTester tester, {VoidCallback? onLoginSukses}) {
    final repo = _FakeAkunRepository();
    final cubit = AkunCubit(akunRepository: repo);
    addTearDown(() async {
      await cubit.close();
      repo.dispose();
    });
    final widget = MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider<AkunCubit>.value(
        value: cubit,
        child: HalamanMasuk(onLoginSukses: onLoginSukses),
      ),
    );
    return (repo: repo, cubit: cubit, widget: widget);
  }

  testWidgets(
    'form email terlipat saat awal, terbuka saat mengetuk "Masuk dengan email", dan memiliki target sentuh >= 48 dp',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ctx = siapkanUji(tester);
      await tester.pumpWidget(ctx.widget);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kartu_form_email')), findsNothing);
      final toggleBtn = find.byKey(const Key('tombol_toggle_form_email'));
      expect(toggleBtn, findsOneWidget);
      expect(tester.getSize(toggleBtn).height, greaterThanOrEqualTo(48));

      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kartu_form_email')), findsOneWidget);
      expect(find.byKey(const Key('input_email_masuk')), findsOneWidget);
      expect(find.byKey(const Key('input_sandi_masuk')), findsOneWidget);
      expect(find.byKey(const Key('tombol_masuk_email')), findsOneWidget);
      expect(find.byKey(const Key('tombol_daftar_email')), findsOneWidget);
      final lupaBtn = find.byKey(const Key('tombol_lupa_sandi'));
      expect(lupaBtn, findsOneWidget);
      expect(tester.getSize(lupaBtn).height, greaterThanOrEqualTo(48));

      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('kartu_form_email')), findsNothing);
    },
  );

  testWidgets('tombol Masuk memanggil masukDenganEmail pada AkunCubit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool loginSuksesDipanggil = false;
    final ctx = siapkanUji(
      tester,
      onLoginSukses: () => loginSuksesDipanggil = true,
    );
    await tester.pumpWidget(ctx.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_toggle_form_email')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_email_masuk')),
      'budi@insap.id',
    );
    await tester.enterText(
      find.byKey(const Key('input_sandi_masuk')),
      'rahasia123',
    );
    final tombolMasuk = find.byKey(const Key('tombol_masuk_email'));
    await tester.ensureVisible(tombolMasuk);
    await tester.pumpAndSettle();
    await tester.tap(tombolMasuk);
    await tester.pumpAndSettle();

    expect(ctx.repo.emailMasuk, 'budi@insap.id');
    expect(ctx.repo.sandiMasuk, 'rahasia123');
    expect(loginSuksesDipanggil, isTrue);
  });

  testWidgets('tombol Daftar memanggil daftarDenganEmail pada AkunCubit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ctx = siapkanUji(tester);
    await tester.pumpWidget(ctx.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tombol_toggle_form_email')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_email_masuk')),
      'baru@insap.id',
    );
    await tester.enterText(
      find.byKey(const Key('input_sandi_masuk')),
      'rahasia123',
    );
    final tombolDaftar = find.byKey(const Key('tombol_daftar_email'));
    await tester.ensureVisible(tombolDaftar);
    await tester.pumpAndSettle();
    await tester.tap(tombolDaftar);
    await tester.pumpAndSettle();

    expect(ctx.repo.emailDaftar, 'baru@insap.id');
    expect(ctx.repo.sandiDaftar, 'rahasia123');
  });

  testWidgets(
    'tautan Lupa kata sandi? memanggil kirimResetKataSandi pada AkunCubit',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ctx = siapkanUji(tester);
      await tester.pumpWidget(ctx.widget);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tombol_toggle_form_email')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('input_email_masuk')),
        'lupa@insap.id',
      );
      final tombolLupa = find.byKey(const Key('tombol_lupa_sandi'));
      await tester.ensureVisible(tombolLupa);
      await tester.pumpAndSettle();
      await tester.tap(tombolLupa);
      await tester.pumpAndSettle();

      expect(ctx.repo.emailReset, 'lupa@insap.id');
    },
  );
}
