import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/router/app_router.dart';
import 'package:insap/features/perkenalan/domain/repositories/pengaturan_repository.dart';

class _FakePengaturanRepository implements PengaturanRepository {
  bool sudahOnboarding;
  int? _target;
  final Map<String, String> _pengaturan = {};

  _FakePengaturanRepository({required this.sudahOnboarding});

  @override
  Future<bool> bacaStatusOnboarding() async => sudahOnboarding;

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {
    sudahOnboarding = selesai;
  }

  @override
  Future<int?> bacaTargetBulanan() async => _target;

  @override
  Future<void> simpanTargetBulanan(int target) async {
    _target = target;
  }

  @override
  Future<String?> bacaPengaturan(String kunci) async => _pengaturan[kunci];

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {
    _pengaturan[kunci] = nilai;
  }
}

void main() {
  group('hitungRedirectOnboarding', () {
    test('onboarding_selesai false (0) mengarahkan ke /perkenalan jika di rute lain', () {
      final redirectBeranda = hitungRedirectOnboarding(
        sudahOnboarding: false,
        matchedLocation: '/',
      );
      expect(redirectBeranda, '/perkenalan');

      final redirectCatat = hitungRedirectOnboarding(
        sudahOnboarding: false,
        matchedLocation: '/catat',
      );
      expect(redirectCatat, '/perkenalan');

      final redirectRiwayat = hitungRedirectOnboarding(
        sudahOnboarding: false,
        matchedLocation: '/riwayat',
      );
      expect(redirectRiwayat, '/perkenalan');
    });

    test('onboarding_selesai false tetap di /perkenalan (tidak redirect berulang)', () {
      final redirect = hitungRedirectOnboarding(
        sudahOnboarding: false,
        matchedLocation: '/perkenalan',
      );
      expect(redirect, isNull);
    });

    test('onboarding_selesai true (1) mengarahkan /perkenalan kembali ke Beranda (/)', () {
      final redirect = hitungRedirectOnboarding(
        sudahOnboarding: true,
        matchedLocation: '/perkenalan',
      );
      expect(redirect, '/');
    });

    test('onboarding_selesai true membiarkan rute biasa bebas diakses', () {
      final redirectBeranda = hitungRedirectOnboarding(
        sudahOnboarding: true,
        matchedLocation: '/',
      );
      expect(redirectBeranda, isNull);

      final redirectCatat = hitungRedirectOnboarding(
        sudahOnboarding: true,
        matchedLocation: '/catat',
      );
      expect(redirectCatat, isNull);

      final redirectAkun = hitungRedirectOnboarding(
        sudahOnboarding: true,
        matchedLocation: '/akun',
      );
      expect(redirectAkun, isNull);
    });
  });

  group('GoRouter redirect dengan PengaturanRepository', () {
    testWidgets('belum onboarding (0) otomatis dialihkan ke /perkenalan', (tester) async {
      final fakeRepo = _FakePengaturanRepository(sudahOnboarding: false);
      final router = GoRouter(
        initialLocation: '/',
        redirect: (context, state) => evaluasiRedirectOnboarding(
          context,
          state,
          repo: fakeRepo,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Halaman Utama')),
          ),
          GoRoute(
            path: '/perkenalan',
            builder: (context, state) => const Scaffold(body: Text('Halaman Perkenalan')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Halaman Perkenalan'), findsOneWidget);
      expect(find.text('Halaman Utama'), findsNothing);
    });

    testWidgets('sudah onboarding (1) tetap di rute utama (/)', (tester) async {
      final fakeRepo = _FakePengaturanRepository(sudahOnboarding: true);
      final router = GoRouter(
        initialLocation: '/',
        redirect: (context, state) => evaluasiRedirectOnboarding(
          context,
          state,
          repo: fakeRepo,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Halaman Utama')),
          ),
          GoRoute(
            path: '/perkenalan',
            builder: (context, state) => const Scaffold(body: Text('Halaman Perkenalan')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Halaman Utama'), findsOneWidget);
      expect(find.text('Halaman Perkenalan'), findsNothing);
    });
  });
}
