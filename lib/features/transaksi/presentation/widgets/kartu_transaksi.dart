import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/badge_kategori.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';

class KartuTransaksi extends StatelessWidget {
  final int nominal;
  final String namaKategori;
  final String? catatan;
  final String waktu;
  final IconData ikonKategori;
  final Color warnaKategori;
  final String? tipeKebutuhan;
  final VoidCallback? onTap;

  const KartuTransaksi({
    super.key,
    required this.nominal,
    required this.namaKategori,
    this.catatan,
    required this.waktu,
    required this.ikonKategori,
    required this.warnaKategori,
    this.tipeKebutuhan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool adaCatatan = catatan != null && catatan!.trim().isNotEmpty;
    final judul = adaCatatan ? catatan!.trim() : namaKategori;

    return KartuBukuTulis(
      onTap: onTap,
      radius: AppSizes.radiusTombol,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sedang,
        vertical: AppSpacing.sedang,
      ),
      child: Row(
        children: [
          BadgeKategori(
            ikon: ikonKategori,
            warna: warnaKategori,
          ),
          const SizedBox(width: AppSpacing.sedang),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sangatKecil),
                Wrap(
                  spacing: AppSpacing.sangatKecil,
                  runSpacing: AppSpacing.mini,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (adaCatatan)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.kecil,
                          vertical: AppSpacing.mini,
                        ),
                        decoration: BoxDecoration(
                          color: warnaKategori,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPil),
                          border: Border.all(
                            color: AppColors.ink,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          namaKategori,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.kartu,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    if (tipeKebutuhan != null &&
                        tipeKebutuhan!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.agakKecil,
                          vertical: AppSpacing.mini,
                        ),
                        decoration: BoxDecoration(
                          color: tipeKebutuhan == 'butuh'
                              ? AppColors.stabilo
                              : AppColors.grid,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLabel),
                          border: Border.all(
                            color: AppColors.ink,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          tipeKebutuhan == 'butuh'
                              ? 'Butuh'
                              : (tipeKebutuhan == 'pengen'
                                  ? 'Pengen'
                                  : tipeKebutuhan!),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.kecil),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${nominal.toRupiah()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
              ),
              const SizedBox(height: AppSpacing.mini),
              Text(
                waktu,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.inkSoft,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
