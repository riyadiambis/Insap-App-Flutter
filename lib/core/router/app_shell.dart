import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/pengaturan/domain/usecases/baca_status_panduan_pindai.dart';
import '../../features/pindai/presentation/widgets/dialog_panduan_pindai.dart';
import '../di/injection_container.dart';
import '../theme.dart';
import '../tur/langkah_tur.dart';
import '../tur/tur_cubit.dart';
import '../widgets/header_aplikasi.dart';
import '../widgets/lapisan_tur.dart';

/// Kerangka navigasi utama dengan 4 cabang tab dan tombol Pindai bulat di tengah.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  String _dapatkanSubjudul(int index) {
    switch (index) {
      case 0:
        return 'BERANDA';
      case 1:
        return 'CATAT';
      case 2:
        return 'REFLEKSI';
      case 3:
        return 'RIWAYAT';
      default:
        return 'BERANDA';
    }
  }

  void _pindahTab(int index) {
    // Tap tab yang sedang aktif mengembalikan ke halaman awal tab tersebut.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _bukaPindai(BuildContext context) async {
    if (!sl.isRegistered<BacaStatusPanduanPindai>()) {
      context.push('/pindai?mulai=1');
      return;
    }
    final sembunyikan = await sl<BacaStatusPanduanPindai>().call();
    if (!context.mounted) return;
    if (!sembunyikan) {
      await tampilkanDialogPanduanPindai(
        context,
        onLanjut: () {
          if (context.mounted) {
            context.push('/pindai?mulai=1');
          }
        },
      );
    } else {
      context.push('/pindai?mulai=1');
    }
  }

  // Tab yang disorot petunjuk (ISSUE-37).
  Key? _kunciTurTab(int index) {
    if (index == 2) return KunciTur.tabRefleksi;
    if (index == 3) return KunciTur.tabRiwayat;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const destinations = [
      (
        index: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Beranda',
      ),
      (
        index: 1,
        icon: Icons.edit_outlined,
        activeIcon: Icons.edit,
        label: 'Catat',
      ),
      (
        index: 2,
        icon: Icons.lightbulb_outline,
        activeIcon: Icons.lightbulb,
        label: 'Refleksi',
      ),
      (
        index: 3,
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: 'Riwayat',
      ),
    ];

    final kerangka = Scaffold(
      appBar: HeaderAplikasi(
        namaLayar: _dapatkanSubjudul(navigationShell.currentIndex),
        kunciAvatar: KunciTur.akun,
      ),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.kartu,
          border: Border(
            top: BorderSide(color: AppColors.ink, width: AppSizes.border),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppSizes.tinggiNavigasiBawah - AppSizes.border,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.kecil,
                0,
                AppSpacing.kecil,
                10.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ItemNavigasiBawah(
                    dest: destinations[0],
                    aktif: navigationShell.currentIndex == 0,
                    onTap: () => _pindahTab(0),
                  ),
                  const SizedBox(width: AppSpacing.sangatKecil),
                  _ItemNavigasiBawah(
                    dest: destinations[1],
                    aktif: navigationShell.currentIndex == 1,
                    onTap: () => _pindahTab(1),
                  ),
                  const SizedBox(width: AppSpacing.sangatKecil),
                  const SizedBox(width: AppSizes.lebarSlotPindaiNav),
                  const SizedBox(width: AppSpacing.sangatKecil),
                  _ItemNavigasiBawah(
                    key: _kunciTurTab(2),
                    dest: destinations[2],
                    aktif: navigationShell.currentIndex == 2,
                    onTap: () => _pindahTab(2),
                  ),
                  const SizedBox(width: AppSpacing.sangatKecil),
                  _ItemNavigasiBawah(
                    key: _kunciTurTab(3),
                    dest: destinations[3],
                    aktif: navigationShell.currentIndex == 3,
                    onTap: () => _pindahTab(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Tombol Pindai dipasang di atas Scaffold dalam Stack agar area menonjol
    // 26 dp di atas bilah bawah tetap menerima sentuhan secara penuh.
    final bawahTombolPindai =
        MediaQuery.paddingOf(context).bottom +
        (AppSizes.tinggiNavigasiBawah -
            (AppSizes.ukuranTombolPindaiNav -
                AppSizes.tonjolanTombolPindaiNav));

    final kerangkaDenganPindai = Stack(
      children: [
        kerangka,
        Positioned(
          left: 0,
          right: 0,
          bottom: bawahTombolPindai,
          child: Center(
            child: _TombolPindaiNav(onTap: () => _bukaPindai(context)),
          ),
        ),
      ],
    );

    // Petunjuk sorotan hanya dipasang kalau cubit-nya terdaftar (tidak di tes).
    if (!sl.isRegistered<TurCubit>()) return kerangkaDenganPindai;

    return Stack(
      children: [
        kerangkaDenganPindai,
        Positioned.fill(
          child: LapisanTur(
            cubit: sl<TurCubit>(),
            langkah: daftarLangkahTur,
            onMulai: () {
              if (navigationShell.currentIndex != 0) {
                navigationShell.goBranch(0);
              }
            },
            onDaftarAkun: () => context.push('/akun'),
          ),
        ),
      ],
    );
  }
}

class _ItemNavigasiBawah extends StatelessWidget {
  final ({int index, IconData icon, IconData activeIcon, String label}) dest;
  final bool aktif;
  final VoidCallback onTap;

  const _ItemNavigasiBawah({
    super.key,
    required this.dest,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: aktif,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.tinggiPillNavigasi,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppDurations.animasiTekan,
                  width: AppSizes.lebarPilNavigasi,
                  height: AppSizes.tinggiPilIkonNavigasi,
                  decoration: BoxDecoration(
                    color: aktif ? AppColors.stabilo : Colors.transparent,
                    border: Border.all(
                      color: aktif ? AppColors.ink : Colors.transparent,
                      width: AppSizes.border,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                  ),
                  child: Icon(
                    aktif ? dest.activeIcon : dest.icon,
                    size: AppSizes.ikonNavigasiKecil,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3.0),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    dest.label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 13.0,
                      letterSpacing: 0,
                      color: AppColors.ink,
                      fontWeight: aktif ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TombolPindaiNav extends StatelessWidget {
  final VoidCallback onTap;

  const _TombolPindaiNav({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pindai struk',
      button: true,
      child: GestureDetector(
        key: const Key('tombol_pindai_nav'),
        onTap: onTap,
        child: Container(
          width: AppSizes.ukuranTombolPindaiNav,
          height: AppSizes.ukuranTombolPindaiNav,
          decoration: BoxDecoration(
            color: AppColors.kartu,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.ink,
              width: AppSizes.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.stabilo,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSizes.borderTombolPindaiNav),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: AppSizes.ikonPindaiNav,
                  color: AppColors.stabilo,
                ),
                const SizedBox(height: 1.0),
                Text(
                  'Pindai',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11.0,
                    letterSpacing: 0,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.kartu,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
