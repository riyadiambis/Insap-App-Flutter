import 'package:flutter/material.dart';

import '../theme.dart';

/// Dialog popup yang menampilkan umpan balik sukses dengan animasi centang
/// yang membesar dan memudar masuk (400-600 ms).
class DialogSukses extends StatelessWidget {
  final String judul;
  final String ringkasan;

  const DialogSukses({
    super.key,
    required this.judul,
    required this.ringkasan,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('dialog_sukses'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.besar),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(AppSpacing.lebihBesar),
        decoration: BoxDecoration(
          color: AppColors.kartu,
          borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
          border: Border.all(
            color: AppColors.ink,
            width: AppSizes.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.benarLatar,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.benar,
                    width: AppSizes.border,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.ink,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.benar,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.besar),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(height: AppSpacing.sedang),
            Text(
              ringkasan,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.lebihBesar),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('tombol_dialog_sukses_oke'),
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.stabilo,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sedang,
                  ),
                  side: const BorderSide(
                    color: AppColors.ink,
                    width: AppSizes.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                  ),
                ),
                child: const Text(
                  'Oke',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menampilkan [DialogSukses] dengan [judul] dan [ringkasan].
Future<T?> tampilkanDialogSukses<T>(
  BuildContext context,
  String judul,
  String ringkasan,
) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => DialogSukses(
      judul: judul,
      ringkasan: ringkasan,
    ),
  );
}
