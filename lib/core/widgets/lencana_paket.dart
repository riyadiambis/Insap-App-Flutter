import 'package:flutter/material.dart';

import '../theme.dart';

/// Paket langganan Insap yang ditampilkan pada lencana paket.
enum PaketInsap { gratis, plus, pro }

/// Lencana status paket pengguna (GRATIS, PLUS, PRO) sesuai `LencanaPaket.dc.html`.
class LencanaPaket extends StatelessWidget {
  final PaketInsap paket;

  const LencanaPaket({super.key, this.paket = PaketInsap.gratis});

  @override
  Widget build(BuildContext context) {
    final (String label, Color latar, Color teks, bool denganBayangan) =
        switch (paket) {
          PaketInsap.gratis => (
            'GRATIS',
            AppColors.kartu,
            AppColors.ink,
            false,
          ),
          PaketInsap.plus => (
            'PLUS',
            AppColors.daun,
            AppColors.kartu,
            false,
          ),
          PaketInsap.pro => (
            'PRO',
            AppColors.stabilo,
            AppColors.ink,
            true,
          ),
        };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: latar,
        border: Border.all(color: AppColors.ink, width: AppSizes.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: denganBayangan ? const [AppTheme.bayanganKecilGelap] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (paket == PaketInsap.pro) ...[
            const Icon(
              Icons.star_border_rounded,
              size: 13,
              color: AppColors.ink,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: teks,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
