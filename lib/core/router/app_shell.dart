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
    final destinations = [
      (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
      (
        icon: Icons.edit_note_outlined,
        activeIcon: Icons.edit_note,
        label: 'Catat',
      ),
      (
        icon: Icons.lightbulb_outline,
        activeIcon: Icons.lightbulb,
        label: 'Refleksi',
      ),
      (
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: 'Riwayat',
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.kartu,
          border: Border(
            top: BorderSide(color: AppColors.ink, width: AppSizes.border),
          ),
          boxShadow: [AppTheme.bayanganAtas],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppSizes.tinggiNavigasiBawah,
            child: Row(
              children: List.generate(destinations.length, (index) {
                final aktif = navigationShell.currentIndex == index;
                final dest = destinations[index];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _pindahTab(index),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.mini,
                        ),
                        child: AnimatedContainer(
                          duration: AppDurations.animasiTekan,
                          width: double.infinity,
                          height: AppSizes.tinggiPillNavigasi,
                          decoration: BoxDecoration(
                            color: aktif
                                ? AppColors.stabilo
                                : Colors.transparent,
                            border: Border.all(
                              color: aktif ? AppColors.ink : Colors.transparent,
                              width: AppSizes.border,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusItemNavigasi,
                            ),
                            boxShadow: aktif
                                ? const [AppTheme.bayanganKecilGelap]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                aktif ? dest.activeIcon : dest.icon,
                                size: AppSizes.ikonNavigasi,
                                color: aktif
                                    ? AppColors.ink
                                    : AppColors.inkSoft,
                              ),
                              const SizedBox(height: AppSpacing.mini),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  dest.label,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: aktif
                                            ? AppColors.ink
                                            : AppColors.inkSoft,
                                        fontWeight: aktif
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
