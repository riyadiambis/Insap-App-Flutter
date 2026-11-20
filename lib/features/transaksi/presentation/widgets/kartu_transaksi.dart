import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/rupiah_extension.dart';

class KartuTransaksi extends StatelessWidget {
  final int nominal;
  final String namaKategori;
  final String? catatan;
  final String waktu;
  final IconData ikonKategori;
  final Color warnaKategori;
  final String? tipeKebutuhan;
  final VoidCallback? onTap;

  const KartuTransaksi({
    super.key,
    required this.nominal,
    required this.namaKategori,
    this.catatan,
    required this.waktu,
    required this.ikonKategori,
    required this.warnaKategori,
    this.tipeKebutuhan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool adaCatatan = catatan != null && catatan!.trim().isNotEmpty;
    final judul = adaCatatan ? catatan!.trim() : namaKategori;
    final bool dariStruk = waktu.toLowerCase().contains('struk');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: warnaKategori,
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppSizes.border,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
                  ),
                  child: Icon(
                    ikonKategori,
                    color: AppColors.ikonBadge,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '$namaKategori ·',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 13,
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (dariStruk)
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 13,
                              color: AppColors.inkSoft,
                            ),
                          Text(
                            waktu,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 13,
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (tipeKebutuhan != null &&
                              tipeKebutuhan!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: tipeKebutuhan == 'butuh'
                                    ? AppColors.kuningMuda
                                    : AppColors.hijauMuda,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                tipeKebutuhan == 'butuh'
                                    ? 'Butuh'
                                    : (tipeKebutuhan == 'pengen'
                                        ? 'Pengen'
                                        : tipeKebutuhan!),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontSize: 11,
                                      letterSpacing: 0.2,
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.kecil),
                Text(
                  '-${nominal.toRupiah()}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(double.infinity, 1.5),
            painter: _GarisPutusPainter(),
          ),
        ],
      ),
    );
  }
}

class _GarisPutusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.garisPutus
      ..strokeWidth = 1.5;
    const double dash = 5;
    const double gap = 4;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
