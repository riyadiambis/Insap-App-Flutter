import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../domain/entities/agregat_kakeibo_entity.dart';

class KartuAgregatKakeibo extends StatelessWidget {
  final AgregatKakeiboEntity agregat;

  const KartuAgregatKakeibo({super.key, required this.agregat});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return KartuBukuTulis(
      radius: AppSizes.radiusKartu,
      shadow: AppTheme.bayanganGelap,
      pressedShadow: AppTheme.bayanganGelapTertekan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '4 Kelompok Kakeibo',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.kecil),
              Text(
                agregat.adaTransaksi ? '100% Tercatat' : 'Belum Ada Data',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sedang),
          _BarisKelompokKakeibo(
            ikon: Icons.restaurant_outlined,
            nama: 'Esensial',
            contoh: 'Makan harian, transport, kos, kuliah',
            persen: agregat.persenEsensial,
            porsi: agregat.porsiEsensial,
            nominal: agregat.totalEsensial,
            warnaBadge: AppColors.paletBadgeKategori[0],
          ),
          const SizedBox(height: AppSpacing.sedang),
          _BarisKelompokKakeibo(
            ikon: Icons.shopping_bag_outlined,
            nama: 'Opsional',
            contoh: 'Jajan daring, kopi kekinian',
            persen: agregat.persenOpsional,
            porsi: agregat.porsiOpsional,
            nominal: agregat.totalOpsional,
            warnaBadge: AppColors.paletBadgeKategori[2],
          ),
          const SizedBox(height: AppSpacing.sedang),
          _BarisKelompokKakeibo(
            ikon: Icons.local_cafe_outlined,
            nama: 'Hiburan',
            contoh: 'Nongkrong, bioskop, top up',
            persen: agregat.persenHiburan,
            porsi: agregat.porsiHiburan,
            nominal: agregat.totalHiburan,
            warnaBadge: AppColors.aksenPengen,
          ),
          const SizedBox(height: AppSpacing.sedang),
          _BarisKelompokKakeibo(
            ikon: Icons.medical_services_outlined,
            nama: 'Ekstra',
            contoh: 'Darurat, obat, keperluan lainnya',
            persen: agregat.persenEkstra,
            porsi: agregat.porsiEkstra,
            nominal: agregat.totalEkstra,
            warnaBadge: AppColors.paletBadgeKategori[5],
          ),
        ],
      ),
    );
  }
}

class _BarisKelompokKakeibo extends StatelessWidget {
  final IconData ikon;
  final String nama;
  final String contoh;
  final int persen;
  final double porsi;
  final int nominal;
  final Color warnaBadge;

  const _BarisKelompokKakeibo({
    required this.ikon,
    required this.nama,
    required this.contoh,
    required this.persen,
    required this.porsi,
    required this.nominal,
    required this.warnaBadge,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(ikon, size: 16, color: warnaBadge),
                  const SizedBox(width: AppSpacing.agakKecil),
                  Flexible(
                    child: Text(
                      '$nama ($persen%)',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.kecil),
            Text(
              nominal.toRupiah(),
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          contoh,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 12.5,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.agakKecil),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.kartu,
            borderRadius: BorderRadius.circular(AppSizes.radiusPil),
            border: Border.all(
              color: AppColors.ink,
              width: AppSizes.border,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusPil),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: porsi.clamp(0.0, 1.0),
              child: Container(color: warnaBadge),
            ),
          ),
        ),
      ],
    );
  }
}
