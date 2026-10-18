import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../di/injection_container.dart';
import '../../features/beranda/presentation/pages/halaman_beranda.dart';
import '../../features/kategori/presentation/pages/halaman_kelola_kategori.dart';
import '../../features/pengaturan/domain/repositories/pengaturan_repository.dart';
import '../../features/perkenalan/presentation/pages/halaman_perkenalan.dart';
import '../../features/refleksi/presentation/pages/halaman_refleksi.dart';
import '../../features/transaksi/presentation/catat/pages/halaman_catat_transaksi.dart';
import '../../features/transaksi/presentation/riwayat/pages/halaman_detail_transaksi.dart';
import '../../features/transaksi/presentation/riwayat/pages/halaman_riwayat.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/akun/presentation/pages/auth_gate.dart';
import '../../features/pindai/presentation/cubit/pindai_cubit.dart';
import '../../features/pindai/presentation/pages/halaman_pindai.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

String? hitungRedirectOnboarding({
  required bool sudahOnboarding,
  required String matchedLocation,
}) {
  final diPerkenalan = matchedLocation == '/perkenalan';

  if (!sudahOnboarding && !diPerkenalan) {
    return '/perkenalan';
  }
  if (sudahOnboarding && diPerkenalan) {
    return '/';
  }
  return null;
}

Future<String?> evaluasiRedirectOnboarding(
  BuildContext context,
  GoRouterState state, {
  PengaturanRepository? repo,
}) async {
  try {
    final pengaturanRepo = repo ?? sl<PengaturanRepository>();
    final sudahOnboarding = await pengaturanRepo.bacaStatusOnboarding();
    return hitungRedirectOnboarding(
      sudahOnboarding: sudahOnboarding,
      matchedLocation: state.matchedLocation,
    );
  } catch (_) {
    // Jika repository belum siap atau dalam pengujian terisolasi, jangan halangi rute
  }
  return null;
}

GoRouter buatAppRouter({
  GlobalKey<NavigatorState>? navigatorKey,
  String initialLocation = '/',
  PengaturanRepository? pengaturanRepository,
}) {
  return GoRouter(
    navigatorKey: navigatorKey ?? _rootNavigatorKey,
    initialLocation: initialLocation,
    redirect: (context, state) => evaluasiRedirectOnboarding(
      context,
      state,
      repo: pengaturanRepository,
    ),
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
                builder: (context, state) => const HalamanBeranda(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catat',
                builder: (context, state) => const HalamanCatatTransaksi(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/refleksi',
                builder: (context, state) => const HalamanRefleksi(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/riwayat',
                builder: (context, state) => const HalamanRiwayat(),
              ),
            ],
          ),
        ],
      ),
      // di luar shell, jadi layar detail tampil penuh tanpa navigasi bawah
      GoRoute(
        path: '/transaksi/:id',
        builder: (context, state) =>
            HalamanDetailTransaksi(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/kategori',
        builder: (context, state) => const HalamanKelolaKategori(),
      ),
      GoRoute(
        path: '/perkenalan',
        builder: (context, state) => const HalamanPerkenalan(),
      ),
      GoRoute(path: '/akun', builder: (context, state) => const AuthGate()),
      GoRoute(
        path: '/pindai',
        builder: (context, state) {
          final mulaiLangsung = state.uri.queryParameters['mulai'] == '1';
          return BlocProvider(
            create: (_) => sl<PindaiCubit>(),
            child: HalamanPindai(mulaiLangsung: mulaiLangsung),
          );
        },
      ),
    ],
  );
}

final GoRouter appRouter = buatAppRouter();
