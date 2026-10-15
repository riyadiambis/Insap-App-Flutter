import 'package:flutter/material.dart';

import '../theme.dart';

/// Data representasi anggota tim pengembang.
class AnggotaTim {
  final String peran;
  final String nama;

  const AnggotaTim({required this.peran, required this.nama});
}

/// Daftar resmi anggota tim pengembang Insap sesuai PRD.md.
const List<AnggotaTim> daftarTimPengembang = [
  AnggotaTim(peran: 'Anggota A (Lead & Fondasi)', nama: 'Rahmat Riyadi'),
  AnggotaTim(peran: 'Anggota B (Riwayat & Pindai)', nama: 'Dafa'),
  AnggotaTim(peran: 'Anggota C (Kategori & Refleksi)', nama: 'Luthfi'),
];

/// Widget kartu ringkas yang menampilkan identitas aplikasi dan tim pengembang.
/// Ditaruh di bagian bawah HalamanAkun dan HalamanMasuk sesuai keputusan ISSUE-20.
class KartuTentangAplikasi extends StatelessWidget {
  const KartuTentangAplikasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.besar),
      decoration: BoxDecoration(
        color: AppColors.kartu,
        border: Border.all(color: AppColors.ink, width: AppSizes.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
        boxShadow: const [AppTheme.bayanganDefault],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Header: Logo + Judul + Versi
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.border,
                  ),
                  boxShadow: const [AppTheme.bayanganKecilGelap],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo_insap.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sedang),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insap: Yuk Sadar Boncos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Versi 0.1.0',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sedang),
          Text(
            'Aplikasi pencatat pengeluaran harian mahasiswa dengan prinsip Kakeibo agar sadar dan kendalikan boncos.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.besar),
          const Divider(
            color: AppColors.garis,
            thickness: AppSizes.borderTipis,
            height: 1,
          ),
          const SizedBox(height: AppSpacing.sedang),

          // Daftar Tim Pengembang
          Text(
            'TIM PENGEMBANG',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.agakKecil),
          for (final anggota in daftarTimPengembang) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      anggota.nama,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    anggota.peran,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
