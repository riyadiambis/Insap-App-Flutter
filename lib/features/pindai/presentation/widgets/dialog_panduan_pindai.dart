import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme.dart';
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
          return AlertDialog(
            backgroundColor: AppColors.paper,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
              side: const BorderSide(
                color: AppColors.ink,
                width: AppSizes.border,
              ),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.ink,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.agakKecil),
                Text(
                  'Panduan Pindai Struk',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI membaca tiap barang dan mengelompokkannya per kategori. '
                  'Kamu bisa hapus centang barang titipan teman sebelum menyimpan.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.sedang),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: janganTampilkanLagi,
                  activeColor: AppColors.ink,
                  checkColor: AppColors.paper,
                  title: Text(
                    'Jangan tampilkan lagi',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
                    setState(() {
                      janganTampilkanLagi = val ?? false;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
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
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.stabilo,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                    side: const BorderSide(
                      color: AppColors.ink,
                      width: AppSizes.border,
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
                  onLanjut?.call();
                },
                child: const Text(
                  'Lanjut pindai',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
