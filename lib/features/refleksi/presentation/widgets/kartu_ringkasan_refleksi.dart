import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../domain/entities/refleksi_mingguan_entity.dart';

class KartuRingkasanRefleksi extends StatelessWidget {
  final RefleksiMingguanEntity refleksi;
  final int? targetPekanDepan;
  final VoidCallback onUbah;

  const KartuRingkasanRefleksi({
    super.key,
    required this.refleksi,
    this.targetPekanDepan,
    required this.onUbah,
  });

  String _formatWaktuSimpan(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const namaBulan = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final bulan = namaBulan[dt.month - 1];
      final jam = dt.hour.toString().padLeft(2, '0');
      final menit = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $bulan ${dt.year}, $jam:$menit';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final teksTarget = targetPekanDepan != null && targetPekanDepan! > 0
        ? targetPekanDepan!.toRupiah()
        : 'Belum diatur';

    return KartuBukuTulis(
      key: const Key('kartu_ringkasan_refleksi_tersimpan'),
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
                        Icons.check_circle_outline_rounded,
                        size: AppSizes.ikonAksi,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sedang),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refleksi Pekan Ini Sudah Tersimpan',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Disimpan: ${_formatWaktuSimpan(refleksi.dibuatPada)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.inkSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.kecil),
              OutlinedButton.icon(
                key: const Key('tombol_ubah_refleksi'),
                onPressed: onUbah,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(
                    color: AppColors.ink,
                    width: AppSizes.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sedang,
                    vertical: AppSpacing.sangatKecil,
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: AppSizes.ikonKecil),
                label: const Text(
                  'Ubah',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.besar),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sedang),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
              border: Border.all(
                color: AppColors.ink,
                width: AppSizes.border,
              ),
              boxShadow: const [AppTheme.bayanganKecil],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        'Rencana Perbaikan Pekan Depan:',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sangatKecil),
                Text(
                  refleksi.catatanRefleksi ?? '-',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sedang),
                Container(
                  height: 1,
                  color: AppColors.garis,
                ),
                const SizedBox(height: AppSpacing.sedang),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sangatKecil,
                  runSpacing: AppSpacing.mini,
                  children: [
                    const Icon(
                      Icons.savings_outlined,
                      size: AppSizes.ikonKecil,
                      color: AppColors.inkSoft,
                    ),
                    Text(
                      'Target Pekan Depan: ',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      teksTarget,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
