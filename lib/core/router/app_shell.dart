import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

// kerangka navigasi bawah 4 tab (P04-Router, P05). di v0.4 Luthfi bikin
// versi adaptif pakai NavigationRail buat layar lebar
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _pindahTab(int index) {
    // tap tab yang lagi aktif = balik ke halaman awal tab itu
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.ink, width: AppSizes.border),
          ),
          boxShadow: [AppTheme.bayanganAtas],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _pindahTab,
          backgroundColor: AppColors.kartu,
          indicatorColor: AppColors.stabilo,
          // jangan pakai elevation Material, bayangannya dari bayanganAtas
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppColors.inkSoft),
              selectedIcon: Icon(Icons.home, color: AppColors.ink),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline, color: AppColors.inkSoft),
              selectedIcon: Icon(Icons.add_circle, color: AppColors.ink),
              label: 'Catat',
            ),
            NavigationDestination(
              icon: Icon(Icons.lightbulb_outline, color: AppColors.inkSoft),
              selectedIcon: Icon(Icons.lightbulb, color: AppColors.ink),
              label: 'Refleksi',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: AppColors.inkSoft),
              selectedIcon: Icon(Icons.history, color: AppColors.ink),
              label: 'Riwayat',
            ),
          ],
        ),
      ),
    );
  }
}
