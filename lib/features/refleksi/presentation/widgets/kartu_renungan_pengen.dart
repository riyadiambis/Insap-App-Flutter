import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../domain/entities/agregat_kakeibo_entity.dart';

class KartuRenunganPengen extends StatelessWidget {
  final AgregatKakeiboEntity agregat;

  const KartuRenunganPengen({super.key, required this.agregat});

  String _buatKalimatRenungan() {
    if (!agregat.adaTransaksi) {
      return 'Pekan ini belum ada pengeluaran tercatat (Rp0). Kamu tetap bisa menulis rencana perbaikan untuk pekan depan.';
    }
    if (agregat.totalPengen == 0) {
      return 'Pekan ini 0% pengeluaranmu ditandai pengen (Rp0). Seluruh pengeluaran pekan ini tercatat sebagai kebutuhan.';
    }
    return 'Pekan ini ${agregat.persentasePengen}% pengeluaranmu ditandai pengen (${agregat.totalPengen.toRupiah()}). Yuk lihat kembali apakah ada kebiasaan yang ingin disesuaikan pekan depan.';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return KartuBukuTulis(
      radius: AppSizes.radiusTombol,
      backgroundColor: AppColors.paper,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSizes.kotakIkonAksi,
            height: AppSizes.kotakIkonAksi,
            decoration: BoxDecoration(
              color: AppColors.stabilo,
              borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonAksi),
              border: Border.all(color: AppColors.ink, width: AppSizes.border),
              boxShadow: const [AppTheme.bayanganKecilGelap],
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: AppSizes.ikonAksi,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: AppSpacing.sedang),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Porsi Belanja Pengen',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.kecil),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.kecil,
                        vertical: AppSpacing.mini,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.stabilo,
                        borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppSizes.borderTipis,
                        ),
                      ),
                      child: Text(
                        '${agregat.persentasePengen}% Pengen',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.agakKecil),
                Text(
                  _buatKalimatRenungan(),
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
