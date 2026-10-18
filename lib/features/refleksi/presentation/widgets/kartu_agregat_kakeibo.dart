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
      radius: AppSizes.radiusTombol,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: AppSizes.ukuranTitikIndikator,
                      height: AppSizes.ukuranTitikIndikator,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.kecil),
                    Flexible(
                      child: Text(
                        '4 Kelompok Kakeibo',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.kecil),
              Text(
                agregat.adaTransaksi ? '100% Tercatat' : 'Belum Ada Data',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sedang),
          _BarisKelompokKakeibo(
            nama: 'Esensial',
            contoh: 'Makan harian, transport, kos, kuliah',
            persen: agregat.persenEsensial,
            porsi: agregat.porsiEsensial,
            nominal: agregat.totalEsensial,
            warnaBadge: AppColors.paletBadgeKategori[3],
          ),
          const SizedBox(height: AppSpacing.sedang),
          _BarisKelompokKakeibo(
            nama: 'Opsional',
            contoh: 'Jajan daring, kopi kekinian',
            persen: agregat.persenOpsional,
            porsi: agregat.porsiOpsional,
            nominal: agregat.totalOpsional,
            warnaBadge: AppColors.paletBadgeKategori[0],
          ),
          const SizedBox(height: AppSpacing.sedang),
          _BarisKelompokKakeibo(
            nama: 'Hiburan',
            contoh: 'Nongkrong, bioskop, top up',
            persen: agregat.persenHiburan,
            porsi: agregat.porsiHiburan,
            nominal: agregat.totalHiburan,
            warnaBadge: AppColors.paletBadgeKategori[2],
          ),
          const SizedBox(height: AppSpacing.sedang),
          _BarisKelompokKakeibo(
            nama: 'Ekstra',
            contoh: 'Darurat, obat, keperluan lainnya',
            persen: agregat.persenEkstra,
            porsi: agregat.porsiEkstra,
            nominal: agregat.totalEkstra,
            warnaBadge: AppColors.aksenPengen,
          ),
        ],
      ),
    );
  }
}

class _BarisKelompokKakeibo extends StatelessWidget {
  final String nama;
  final String contoh;
  final int persen;
  final double porsi;
  final int nominal;
  final Color warnaBadge;

  const _BarisKelompokKakeibo({
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
                  Container(
                    width: AppSizes.ukuranTitikIndikator,
                    height: AppSizes.ukuranTitikIndikator,
                    decoration: BoxDecoration(
                      color: warnaBadge,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLabel),
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppSizes.borderTipis,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.agakKecil),
                  Flexible(
                    child: Text(
                      '$nama ($persen%)',
                      style: textTheme.bodyMedium?.copyWith(
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
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.mini),
        Text(contoh, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.agakKecil),
        Container(
          height: AppSizes.tinggiBatangPorsi,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.grid,
            borderRadius: BorderRadius.circular(AppSizes.radiusBatangPorsi),
            border: Border.all(
              color: AppColors.ink,
              width: AppSizes.borderTipis,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusBatangPorsi),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: porsi,
              child: Container(color: warnaBadge),
            ),
          ),
        ),
      ],
    );
  }
}
