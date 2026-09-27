import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/beranda/presentation/pages/halaman_beranda.dart';
import '../../features/kategori/presentation/pages/halaman_kelola_kategori.dart';
import '../../features/perkenalan/presentation/pages/halaman_perkenalan.dart';
import '../../features/refleksi/presentation/pages/halaman_refleksi.dart';
import '../../features/transaksi/presentation/catat/pages/halaman_catat_transaksi.dart';
import '../../features/transaksi/presentation/riwayat/pages/halaman_detail_transaksi.dart';
import '../../features/transaksi/presentation/riwayat/pages/halaman_riwayat.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
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
      builder: (context, state) => HalamanDetailTransaksi(
        id: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/kategori',
      builder: (context, state) => const HalamanKelolaKategori(),
    ),
    GoRoute(
      path: '/perkenalan',
      builder: (context, state) => const HalamanPerkenalan(),
    ),
  ],
);
