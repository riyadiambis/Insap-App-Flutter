import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/router/app_shell.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/tur/langkah_tur.dart';
import 'package:insap/core/tur/tur_cubit.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';

class _FakePengaturanRepository implements PengaturanRepository {
  final Map<String, String> isi = {};

  @override
  Future<bool> bacaStatusOnboarding() async => true;

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {}

  @override
  Future<int?> bacaTargetBulanan() async => null;

  @override
  Future<void> simpanTargetBulanan(int target) async {}

  @override
  Future<String?> bacaPengaturan(String kunci) async => isi[kunci];

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {
    isi[kunci] = nilai;
  }
}

/// Menguji petunjuk sorotan saat terpasang di AppShell yang asli:
/// kunci tab, kunci avatar header, dan tombol Daftar Akun (ISSUE-37).
void main() {
  final sl = GetIt.instance;
  late _FakePengaturanRepository repo;

  setUp(() async {
    await sl.reset();
    repo = _FakePengaturanRepository();
    sl.registerLazySingleton(
      () => TurCubit(
        pengaturanRepository: repo,
        jumlahLangkah: daftarLangkahTur.length,
      ),
    );
  });

  tearDown(() async {
    await sl<TurCubit>().close();
    await sl.reset();
  });

  Widget buatAplikasiUji() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        key: KunciTur.catatCepat,
                        width: 120,
                        height: 80,
                      ),
                      SizedBox(
                        key: KunciTur.pindaiStruk,
                        width: 120,
                        height: 80,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            for (final jalur in ['/catat', '/refleksi', '/riwayat'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: jalur,
                    builder: (context, state) => const SizedBox(),
                  ),
                ],
              ),
          ],
        ),
        GoRoute(
          path: '/akun',
          builder: (context, state) =>
              const Scaffold(body: Text('Halaman Akun Pengguna')),
        ),
      ],
    );
    return MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router);
  }

  Future<void> tekanLanjut(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tombol_tur_lanjut')));
    await tester.pumpAndSettle();
  }

  testWidgets('kelima langkah menemukan widget aslinya di AppShell', (
    tester,
  ) async {
    await tester.pumpWidget(buatAplikasiUji());
    await tester.pumpAndSettle();

    for (var i = 0; i < daftarLangkahTur.length; i++) {
      expect(
        find.text('LANGKAH ${i + 1} DARI ${daftarLangkahTur.length}'),
        findsOneWidget,
      );
      expect(find.text(daftarLangkahTur[i].judul), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (i < daftarLangkahTur.length - 1) await tekanLanjut(tester);
    }
  });

  testWidgets('Daftar Akun di langkah terakhir membuka halaman akun', (
    tester,
  ) async {
    await tester.pumpWidget(buatAplikasiUji());
    await tester.pumpAndSettle();

    for (var i = 0; i < daftarLangkahTur.length - 1; i++) {
      await tekanLanjut(tester);
    }
    await tester.tap(find.byKey(const Key('tombol_tur_daftar')));
    await tester.pumpAndSettle();

    expect(find.text('Halaman Akun Pengguna'), findsOneWidget);
    expect(repo.isi[TurCubit.kunciSelesai], '1');
  });

  testWidgets('selama petunjuk tampil, tab di bawahnya tidak bisa diketuk', (
    tester,
  ) async {
    await tester.pumpWidget(buatAplikasiUji());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Riwayat'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // masih di langkah pertama, belum pindah tab
    expect(find.text('LANGKAH 1 DARI 5'), findsOneWidget);
    expect(find.text('BERANDA'), findsOneWidget);
  });

  testWidgets('tidak muncul lagi setelah pernah dilewati', (tester) async {
    repo.isi[TurCubit.kunciSelesai] = '1';
    await tester.pumpWidget(buatAplikasiUji());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('balon_tur')), findsNothing);
  });
}
