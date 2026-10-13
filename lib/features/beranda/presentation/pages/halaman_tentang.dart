import 'package:flutter/material.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';

// layar tentang aplikasi dengan navigasi imperatif dan aset gambar (Modul 3 praktikum)
class HalamanTentang extends StatelessWidget {
  const HalamanTentang({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.batasLebarKonten,
              ),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.besar),
                children: [
                  // tombol kembali di pojok kiri atas (Modul 3 Navigator.pop)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      key: const Key('tombol_kembali_tentang'),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.agakKecil),
                        decoration: BoxDecoration(
                          color: AppColors.kartu,
                          border: Border.all(
                            color: AppColors.ink,
                            width: AppSizes.border,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusKotakIkonKuota,
                          ),
                          boxShadow: const [AppTheme.bayanganKecilGelap],
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.ink,
                          size: AppSizes.ikonAksi,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lebihBesar),

                  // kartu profil dan logo aplikasi
                  KartuBukuTulis(
                    radius: AppSizes.radiusTombol,
                    padding: const EdgeInsets.all(AppSpacing.lebihBesar),
                    child: Column(
                      children: [
                        // logo aplikasi resmi (Modul 3 Image.asset)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.ink,
                              width: AppSizes.border,
                            ),
                            boxShadow: const [AppTheme.bayanganKecilGelap],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/images/logo_insap.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.besar),
                        Text(
                          'Insap: Yuk Sadar Boncos',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sangatKecil),
                        Text(
                          'Versi 0.1.0',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sedang),
                        Text(
                          'Aplikasi pencatat pengeluaran harian mahasiswa dengan prinsip Kakeibo agar sadar dan kendalikan boncos.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.besar),

                  // kartu daftar pengembang
                  KartuBukuTulis(
                    radius: AppSizes.radiusTombol,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIM PENGEMBANG',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sedang),
                        const _BarisAnggota(
                          peran: 'Anggota A (Lead & Fondasi)',
                          nama: 'Rahmad Riyadi',
                        ),
                        const SizedBox(height: AppSpacing.agakKecil),
                        const _BarisAnggota(
                          peran: 'Anggota B (Riwayat & Pindai)',
                          nama: 'Dafa',
                        ),
                        const SizedBox(height: AppSpacing.agakKecil),
                        const _BarisAnggota(
                          peran: 'Anggota C (Kategori & Refleksi)',
                          nama: 'Luthfi',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarisAnggota extends StatelessWidget {
  final String nama;
  final String peran;

  const _BarisAnggota({required this.nama, required this.peran});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSizes.ukuranTitikIndikator,
          height: AppSizes.ukuranTitikIndikator,
          decoration: BoxDecoration(
            color: AppColors.stabilo,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: 1.0),
          ),
        ),
        const SizedBox(width: AppSpacing.agakKecil),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nama,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                peran,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
