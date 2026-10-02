import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

/// Header aplikasi bersama sesuai mockup layar 1 dan 2.
///
/// Menampilkan:
/// - Kiri: Kotak logo kuning stabilo dengan ikon dompet, teks "Insap",
///   dan subjudul [namaLayar] kapital ("BERANDA" / "CATAT").
/// - Kanan: Tombol lonceng notifikasi dan avatar profil yang masing-masing
///   memunculkan SnackBar "Segera hadir".
class HeaderAplikasi extends StatelessWidget implements PreferredSizeWidget {
  final String namaLayar;

  const HeaderAplikasi({
    super.key,
    required this.namaLayar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  void _tampilkanPesanSegeraHadir(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Segera hadir')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(
          bottom: BorderSide(
            color: AppColors.ink,
            width: AppSizes.border,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.garis,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.batasLebarKonten,
            ),
            height: 64.0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.besar,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSizes.kotakIkonAksi,
                      height: AppSizes.kotakIkonAksi,
                      decoration: BoxDecoration(
                        color: AppColors.stabilo,
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppSizes.border,
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: const [AppTheme.bayanganKecilGelap],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: AppSizes.ikonAksi,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sedang),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Insap',
                          style: GoogleFonts.baloo2(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          namaLayar.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _tampilkanPesanSegeraHadir(context),
                      child: Container(
                        width: 38.0,
                        height: 38.0,
                        decoration: BoxDecoration(
                          color: AppColors.kartu,
                          border: Border.all(
                            color: AppColors.ink,
                            width: AppSizes.border,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: const [AppTheme.bayanganKecilGelap],
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: AppSizes.ikonAksi,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.kecil),
                    GestureDetector(
                      onTap: () => _tampilkanPesanSegeraHadir(context),
                      child: Container(
                        width: 34.0,
                        height: 34.0,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.ink,
                            width: AppSizes.border,
                          ),
                          boxShadow: const [AppTheme.bayanganKecilGelap],
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 18.0,
                          color: AppColors.kartu,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
