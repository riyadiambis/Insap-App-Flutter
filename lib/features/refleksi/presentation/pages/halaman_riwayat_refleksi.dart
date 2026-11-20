import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/iso_week.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/header_aplikasi.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/maskot_struki.dart';
import '../../domain/entities/refleksi_mingguan_entity.dart';
import '../../domain/usecases/ambil_semua_refleksi.dart';

class HalamanRiwayatRefleksi extends StatefulWidget {
  final AmbilSemuaRefleksi? ambilSemuaRefleksi;

  const HalamanRiwayatRefleksi({super.key, this.ambilSemuaRefleksi});

  @override
  State<HalamanRiwayatRefleksi> createState() => _HalamanRiwayatRefleksiState();
}

class _HalamanRiwayatRefleksiState extends State<HalamanRiwayatRefleksi> {
  late Future<List<RefleksiMingguanEntity>> _futureRefleksi;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  void _muatData() {
    final useCase = widget.ambilSemuaRefleksi ?? sl<AmbilSemuaRefleksi>();
    _futureRefleksi = useCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const HeaderAplikasi(
        namaLayar: 'Riwayat Refleksi',
        modeKembali: true,
      ),
      body: PaperBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.batasLebarKonten,
              ),
              child: FutureBuilder<List<RefleksiMingguanEntity>>(
                future: _futureRefleksi,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.ink,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.besar),
                        child: Text(
                          'Gagal memuat riwayat: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.antarBagian),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const MaskotStruki(
                              pose: PoseMaskot.detektif,
                              ukuran: 160,
                            ),
                            const SizedBox(height: AppSpacing.besar),
                            Text(
                              'Belum ada refleksi tersimpan.',
                              key: const Key('teks_riwayat_kosong'),
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.besar,
                      AppSpacing.besar,
                      AppSpacing.besar,
                      AppSpacing.jarakGulirBawah,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.besar),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final rentang = rentangMingguDariIso(
                        item.tahun,
                        item.mingguKe,
                      );
                      final teksRentang = formatRentangMinggu(rentang);
                      final teksTarget =
                          item.targetPengeluaran != null &&
                              item.targetPengeluaran! > 0
                          ? item.targetPengeluaran!.toRupiah()
                          : 'Belum diatur';
                      final teksRealisasi = item.realisasi.toRupiah();

                      return KartuBukuTulis(
                        radius: AppSizes.radiusKartu,
                        shadow: AppTheme.bayanganGelap,
                        pressedShadow: AppTheme.bayanganGelapTertekan,
                        padding: const EdgeInsets.all(AppSpacing.besar),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    teksRentang,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
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
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusPil,
                                    ),
                                    border: Border.all(
                                      color: AppColors.ink,
                                      width: AppSizes.borderTipis,
                                    ),
                                  ),
                                  child: Text(
                                    'Pekan ke-${item.mingguKe}',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sedang),
                            Text(
                              '"${item.catatanRefleksi ?? ''}"',
                              style: textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sedang),
                            CustomPaint(
                              size: const Size(double.infinity, 1.5),
                              painter: _GarisPutusRiwayatPainter(),
                            ),
                            const SizedBox(height: AppSpacing.kecil),
                            Wrap(
                              spacing: AppSpacing.sedang,
                              runSpacing: AppSpacing.sangatKecil,
                              children: [
                                Text(
                                  'Target: $teksTarget',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                Text(
                                  '·',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                Text(
                                  'Realisasi: $teksRealisasi',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GarisPutusRiwayatPainter extends CustomPainter {
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
