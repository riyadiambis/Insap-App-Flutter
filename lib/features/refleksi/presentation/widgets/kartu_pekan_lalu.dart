import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../domain/entities/refleksi_mingguan_entity.dart';

class KartuPekanLalu extends StatelessWidget {
  final RefleksiMingguanEntity refleksi;
  final int? target;
  final VoidCallback? onTap;

  const KartuPekanLalu({
    super.key,
    required this.refleksi,
    this.target,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nominalTarget = target ?? refleksi.targetPengeluaran;
    final teksTarget =
        nominalTarget != null && nominalTarget > 0
            ? nominalTarget.toRupiah()
            : null;

    return KartuBukuTulis(
      key: const Key('kartu_pekan_lalu'),
      onTap: onTap,
      radius: AppSizes.radiusTombol,
      padding: const EdgeInsets.all(AppSpacing.sedang),
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
                      width: AppSizes.kotakIkonAksi,
                      height: AppSizes.kotakIkonAksi,
                      decoration: BoxDecoration(
                        color: AppColors.stabilo,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusKotakIkonAksi,
                        ),
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppSizes.borderTipis,
                        ),
                        boxShadow: const [AppTheme.bayanganKecilGelap],
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: AppSizes.ikonAksi,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sedang),
                    Expanded(
                      child: Text(
                        'Pekan lalu kamu ingin:',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppSizes.ikonKecil,
                  color: AppColors.inkSoft,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sedang),
          Text(
            '"${refleksi.catatanRefleksi ?? ''}"',
            style: textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (teksTarget != null) ...[
            const SizedBox(height: AppSpacing.kecil),
            Row(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  size: AppSizes.ikonKecil,
                  color: AppColors.inkSoft,
                ),
                const SizedBox(width: AppSpacing.sangatKecil),
                Expanded(
                  child: Text(
                    'Target yang ditetapkan: $teksTarget',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
