import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/beranda/presentation/pages/halaman_beranda.dart';
import '../../features/transaksi/presentation/catat/halaman_catat_transaksi.dart';
import '../../features/refleksi/presentation/pages/halaman_refleksi.dart';
import '../../features/transaksi/presentation/riwayat/halaman_riwayat.dart';
import '../../features/transaksi/presentation/riwayat/halaman_detail_transaksi.dart';
import '../../features/kategori/presentation/pages/halaman_kelola_kategori.dart';
import '../../features/perkenalan/presentation/pages/halaman_perkenalan.dart';
import '../theme.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              boxShadow: [AppTheme.bayanganAtas],
            ),
            child: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.paper,
              selectedItemColor: AppColors.ink,
              unselectedItemColor: AppColors.inkSoft,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline),
                  activeIcon: Icon(Icons.add_circle),
                  label: 'Catat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.lightbulb_outline),
                  activeIcon: Icon(Icons.lightbulb),
                  label: 'Refleksi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history),
                  label: 'Riwayat',
                ),
              ],
            ),
          ),
        );
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
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  builder: (context, state) => const HalamanDetailTransaksi(),
                ),
              ],
            ),
          ],
        ),
      ],
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
