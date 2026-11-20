import 'package:flutter/material.dart';

import '../theme.dart';
import 'maskot_struki.dart';
import 'tombol_stabilo.dart';

/// Menampilkan dialog informasi bahwa fitur langganan berbayar sedang disiapkan
/// sesuai acuan `PopupDikembangkan.dc.html`.
Future<void> tampilkanDialogFiturDikembangkan(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.ink.withValues(alpha: 0.5),
    builder: (dialogContext) {
      return Dialog(
        key: const Key('dialog_fitur_dikembangkan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lebihBesar,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: BoxDecoration(
              color: AppColors.kartu,
              borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
              border: Border.all(
                color: AppColors.ink,
                width: AppSizes.border,
              ),
              boxShadow: const [AppTheme.bayanganIlustrasi],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MaskotStruki(
                    pose: PoseMaskot.nabung,
                    ukuran: AppSizes.ukuranMaskotPopup,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Insap Pro sedang disiapkan',
                    textAlign: TextAlign.center,
                    style: Theme.of(dialogContext).textTheme.headlineSmall
                        ?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.15,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pembayaran langganan belum aktif. Fitur ini masih kami kembangkan dan akan dibuka di pembaruan berikutnya.',
                    textAlign: TextAlign.center,
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(
                          fontSize: 15,
                          color: AppColors.ink,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 14),
                  TombolStabilo(
                    key: const Key('tombol_tutup_dialog_dikembangkan'),
                    teks: 'Oke, ditunggu',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
