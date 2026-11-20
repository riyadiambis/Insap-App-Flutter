import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../pengaturan/domain/usecases/simpan_status_panduan_pindai.dart';

/// Menampilkan popup dialog panduan pemindaian struk baru (Tahap 3).
Future<void> tampilkanDialogPanduanPindai(
  BuildContext context, {
  VoidCallback? onLanjut,
  SimpanStatusPanduanPindai? simpanStatusPanduanPindai,
}) async {
  final simpanStatus =
      simpanStatusPanduanPindai ?? sl<SimpanStatusPanduanPindai>();
  bool janganTampilkanLagi = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lebihBesar,
              vertical: AppSpacing.besar,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.batasLebarKonten,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.kartu,
                  borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.border,
                  ),
                  boxShadow: const [AppTheme.bayanganIlustrasi],
                ),
                child: Material(
                  color: AppColors.kartu,
                  borderRadius: BorderRadius.circular(
                    AppSizes.radiusKartu - AppSizes.border,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.besar),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
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
                                  width: AppSizes.border,
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.ink,
                                size: AppSizes.ikonAksi,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sedang),
                            Expanded(
                              child: Text(
                                'Panduan Pindai Struk',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sedang),
                        Text(
                          'AI membaca tiap barang dan mengelompokkannya per kategori. '
                          'Kamu bisa hapus centang barang titipan teman sebelum menyimpan.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sedang),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: janganTampilkanLagi,
                          activeColor: AppColors.ink,
                          checkColor: AppColors.kartu,
                          side: const BorderSide(
                            color: AppColors.ink,
                            width: AppSizes.border,
                          ),
                          title: Text(
                            'Jangan tampilkan lagi',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) {
                            setState(() {
                              janganTampilkanLagi = val ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sedang),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: AppSizes.tinggiTombol,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.kartu,
                                    foregroundColor: AppColors.ink,
                                    side: const BorderSide(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusTombol,
                                      ),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (janganTampilkanLagi) {
                                      await simpanStatus.call(true);
                                    }
                                    if (dialogContext.mounted) {
                                      Navigator.of(dialogContext).pop();
                                    }
                                  },
                                  child: const Text(
                                    'Nanti',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sedang),
                            Expanded(
                              flex: 2,
                              child: TombolStabilo(
                                teks: 'Lanjut pindai',
                                onPressed: () async {
                                  if (janganTampilkanLagi) {
                                    await simpanStatus.call(true);
                                  }
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                  onLanjut?.call();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
