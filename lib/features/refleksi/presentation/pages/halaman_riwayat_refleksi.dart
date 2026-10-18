import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/iso_week.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
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

  void _kembali() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.batasLebarKonten,
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.besar),
                    child: Row(
                      children: [
                        IconButton(
                          key: const Key('tombol_kembali_riwayat_refleksi'),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.ink,
                          ),
                          onPressed: _kembali,
                        ),
                        const SizedBox(width: AppSpacing.sangatKecil),
                        Expanded(
                          child: Text(
                            'Riwayat Refleksi',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<RefleksiMingguanEntity>>(
                      future: _futureRefleksi,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.ink),
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
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.stabilo,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.ink,
                                        width: AppSizes.border,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_outlined,
                                      size: 32,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.besar),
                                  Text(
                                    'Belum ada refleksi tersimpan.',
                                    key: const Key('teks_riwayat_kosong'),
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.besar,
                            right: AppSpacing.besar,
                            bottom: AppSpacing.jarakGulirBawah,
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
                            final teksTarget = item.targetPengeluaran != null &&
                                    item.targetPengeluaran! > 0
                                ? item.targetPengeluaran!.toRupiah()
                                : 'Belum diatur';
                            final teksRealisasi = item.realisasi.toRupiah();

                            return KartuBukuTulis(
                              radius: AppSizes.radiusTombol,
                              padding: const EdgeInsets.all(AppSpacing.besar),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          teksRentang,
                                          style:
                                              textTheme.titleMedium?.copyWith(
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
                                  Container(
                                    height: 1,
                                    color: AppColors.garis,
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
                                        '•',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.garis,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
