import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:insap/core/iklan/layanan_iklan.dart';
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

  @override
  Future<void> hapusAkun() async {}
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

    testWidgets(
      'menampilkan menu Pengaturan privasi iklan saat perluTombolPrivasi true dan menyembunyikan saat false',
      (tester) async {
        const pengguna = PenggunaEntity(
          uid: 'uid-3',
          email: 'iklan@insap.id',
        );

        final fakeIklan = _FakeLayananIklanPrivasi(perluPrivasi: false);
        sl.registerSingleton<LayananIklan>(fakeIklan);

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

        expect(find.text('Pengaturan privasi iklan'), findsNothing);

        await sl.unregister<LayananIklan>();
        final fakeIklanWajib = _FakeLayananIklanPrivasi(perluPrivasi: true);
        sl.registerSingleton<LayananIklan>(fakeIklanWajib);

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

        final tombolPrivasi = find.text('Pengaturan privasi iklan');
        expect(tombolPrivasi, findsOneWidget);
        await tester.ensureVisible(tombolPrivasi);
        await tester.tap(tombolPrivasi);
        await tester.pumpAndSettle();

        expect(fakeIklanWajib.jumlahTampilOpsi, 1);
      },
    );

    testWidgets(
      'menu Pengaturan privasi iklan muncul saat notifier berubah ke true tanpa membuka ulang halaman',
      (tester) async {
        const pengguna = PenggunaEntity(
          uid: 'uid-4',
          email: 'reaktif@insap.id',
        );

        final fakeIklan = _FakeLayananIklanPrivasi(perluPrivasi: false);
        sl.registerSingleton<LayananIklan>(fakeIklan);

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

        expect(find.text('Pengaturan privasi iklan'), findsNothing);

        fakeIklan.setPerluPrivasi(true);
        await tester.pumpAndSettle();

        expect(find.text('Pengaturan privasi iklan'), findsOneWidget);
      },
    );
  });
}

class _FakeLayananIklanPrivasi implements LayananIklan {
  final ValueNotifier<bool> _perluPrivasiNotifier;
  int jumlahTampilOpsi = 0;

  _FakeLayananIklanPrivasi({required bool perluPrivasi})
    : _perluPrivasiNotifier = ValueNotifier<bool>(perluPrivasi);

  void setPerluPrivasi(bool nilai) {
    _perluPrivasiNotifier.value = nilai;
  }

  @override
  bool get bolehMintaIklan => true;

  @override
  bool get perluTombolPrivasi => _perluPrivasiNotifier.value;

  @override
  ValueListenable<bool> get perluTombolPrivasiListenable =>
      _perluPrivasiNotifier;

  @override
  Future<void> siapkan() async {}

  @override
  Future<void> tampilkanOpsiPrivasi() async {
    jumlahTampilOpsi++;
  }

  @override
  Future<bool> tontonIklanBonus() async => false;
}
