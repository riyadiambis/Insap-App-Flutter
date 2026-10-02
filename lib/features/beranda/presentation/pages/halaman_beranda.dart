import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/iso_week.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../kategori/domain/entities/kategori_entity.dart';
import '../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../kategori/presentation/cubit/kategori_state.dart';
import '../../../transaksi/domain/entities/transaksi_entity.dart';
import '../../../transaksi/domain/entities/ringkasan_pekan_entity.dart';
import '../../../transaksi/presentation/widgets/kartu_transaksi.dart';
import '../cubit/beranda_cubit.dart';
import '../cubit/beranda_state.dart';

Color _parseWarna(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse(hexColor, radix: 16));
}

IconData _parseIkon(String namaIkon) {
  switch (namaIkon) {
    case 'restaurant':
      return Icons.restaurant;
    case 'two_wheeler':
      return Icons.two_wheeler;
    case 'home':
      return Icons.home;
    case 'school':
      return Icons.school;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'local_cafe':
      return Icons.local_cafe;
    case 'sports_esports':
      return Icons.sports_esports;
    case 'medical_services':
      return Icons.medical_services;
    case 'more_horiz':
    default:
      return Icons.more_horiz;
  }
}

String _kapitalPertama(String teks) {
  if (teks.isEmpty) return teks;
  return teks[0].toUpperCase() + teks.substring(1);
}

class HalamanBeranda extends StatelessWidget {
  const HalamanBeranda({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
            child: BlocBuilder<BerandaCubit, BerandaState>(
              builder: (context, state) {
                if (state is BerandaLoading || state is BerandaInitial) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                    ),
                  );
                } else if (state is BerandaError) {
                  return Center(
                    child: Text(
                      'Ups, ada masalah:\n${state.pesan}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                } else if (state is BerandaLoaded) {
                  return _BerandaContent(ringkasan: state.ringkasan);
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BerandaContent extends StatelessWidget {
  final RingkasanPekanEntity ringkasan;

  const _BerandaContent({required this.ringkasan});

  @override
  Widget build(BuildContext context) {
    final pekanIni = isoWeekNumber(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.besar),
      children: [
        const SizedBox(height: AppSpacing.sangatKecil),
        // Greeting Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Halo, Kawan!',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(width: AppSpacing.agakKecil),
                    const Text(
                      '👋',
                      style: TextStyle(fontSize: AppSizes.indikatorMuat),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.mini),
                Text(
                  'Yuk sadar boncos hari ini.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sedang,
                vertical: AppSpacing.agakKecil,
              ),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(
                  color: AppColors.ink,
                  width: AppSizes.border,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                boxShadow: const [AppTheme.bayanganKecil],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSizes.ukuranTitikIndikator,
                    height: AppSizes.ukuranTitikIndikator,
                    decoration: BoxDecoration(
                      color: AppColors.stabilo,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink,
                        width: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sangatKecil),
                  Text(
                    'Pekan ke-$pekanIni',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.besar),
        // Kartu Ringkasan Pekan
        KartuBukuTulis(
          radius: AppSizes.radiusTombol,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: AppSizes.ikonKalender,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: AppSpacing.agakKecil),
                      Text(
                        'PENGELUARAN PEKAN INI',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.inkSoft,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.kecil,
                      vertical: AppSpacing.mini,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grid,
                      border: Border.all(color: AppColors.ink, width: 1.0),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                    ),
                    child: Text(
                      'PEKAN INI',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sedang),
              Text(
                ringkasan.totalMingguIni.toRupiah(),
                style: AppTheme.nominalUtama,
              ),
              const SizedBox(height: AppSpacing.sedang),
              _IndikatorSelisih(selisih: ringkasan.selisihMingguan),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.besar),
        // Kartu Kuota Pindai
        KartuBukuTulis(
          radius: AppSizes.radiusTombol,
          padding: const EdgeInsets.all(AppSpacing.besar),
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
                          width: AppSizes.kotakIkonKuota,
                          height: AppSizes.kotakIkonKuota,
                          decoration: BoxDecoration(
                            color: AppColors.grid,
                            border: Border.all(
                              color: AppColors.ink,
                              width: AppSizes.border,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusKotakIkonKuota,
                            ),
                            boxShadow: const [AppTheme.bayanganKecilGelap],
                          ),
                          child: const Icon(
                            Icons.document_scanner_outlined,
                            size: AppSizes.ikonKuota,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sedang),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Sisa Kuota Pindai AI',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.agakKecil),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.agakKecil,
                                      vertical: AppSpacing.mini,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.stabilo,
                                      border: Border.all(
                                        color: AppColors.ink,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusLabel,
                                      ),
                                    ),
                                    child: Text(
                                      'AI',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.mini),
                              Text(
                                'Reset tiap hari Senin jam 00:00',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.inkSoft),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.kecil),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${ringkasan.kuotaPindai} ',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                            ),
                            TextSpan(
                              text: '/ 10',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkSoft,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'struk sisa',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sedang),
              Row(
                children: List.generate(10, (index) {
                  final bool terisi = index < ringkasan.kuotaPindai;
                  return Expanded(
                    child: Container(
                      height: AppSizes.tinggiSegmenKuota,
                      margin: EdgeInsets.only(
                        right: index < 9 ? AppSpacing.sangatKecil : 0,
                      ),
                      decoration: BoxDecoration(
                        color: terisi ? AppColors.ink : AppColors.grid,
                        border: Border.all(
                          color: AppColors.ink,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSegmenKuota,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.besar),
        // Quick Action Buttons
        Row(
          children: [
            Expanded(
              child: KartuBukuTulis(
                onTap: () => context.go('/catat'),
                backgroundColor: AppColors.stabilo,
                shadow: AppTheme.bayanganGelap,
                pressedShadow: AppTheme.bayanganGelapTertekan,
                radius: AppSizes.radiusTombol,
                padding: const EdgeInsets.all(AppSpacing.sedang),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: AppSizes.kotakIkonAksi,
                      height: AppSizes.kotakIkonAksi,
                      decoration: BoxDecoration(
                        color: AppColors.kartu,
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppSizes.border,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusKotakIkonAksi),
                        boxShadow: const [AppTheme.bayanganKecilGelap],
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: AppSizes.ikonAksi,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sedang),
                    Text(
                      'Catat Cepat',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.mini),
                    Text(
                      'Ketik manual instan',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sedang),
            Expanded(
              child: KartuBukuTulis(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Segera hadir')),
                  );
                },
                backgroundColor: AppColors.kartu,
                shadow: AppTheme.bayanganDefault,
                pressedShadow: AppTheme.bayanganDefaultTertekan,
                radius: AppSizes.radiusTombol,
                padding: const EdgeInsets.all(AppSpacing.sedang),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: AppSizes.kotakIkonAksi,
                      height: AppSizes.kotakIkonAksi,
                      decoration: BoxDecoration(
                        color: AppColors.grid,
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppSizes.border,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusKotakIkonAksi),
                        boxShadow: const [AppTheme.bayanganKecilGelap],
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: AppSizes.ikonAksi,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sedang),
                    Text(
                      'Pindai Struk',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.mini),
                    Text(
                      'OCR otomatis AI',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lebihBesar),
        // Recent Transactions Section Header
        Row(
          children: [
            Text(
              'Catatan Terakhir',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: AppSpacing.kecil),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.kecil,
                vertical: AppSpacing.mini,
              ),
              decoration: BoxDecoration(
                color: AppColors.grid,
                border: Border.all(color: AppColors.ink, width: 1.0),
                borderRadius: BorderRadius.circular(AppSizes.radiusPil),
              ),
              child: Text(
                '${ringkasan.transaksiTerakhir.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sedang),
        if (ringkasan.transaksiTerakhir.isEmpty)
          KartuBukuTulis(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.besar),
                child: Text(
                  'Belum ada transaksi. Yuk catat pengeluaran pertamamu!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else
          ...ringkasan.transaksiTerakhir.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sedang),
                child: _ItemTransaksi(transaksi: t),
              )),
      ],
    );
  }
}

class _IndikatorSelisih extends StatelessWidget {
  final int selisih;

  const _IndikatorSelisih({required this.selisih});

  @override
  Widget build(BuildContext context) {
    final bool hemat = selisih < 0;
    final bool boros = selisih > 0;
    final nominalAbsolut = selisih.abs().toRupiah();
    final teksStatus = hemat ? 'lebih hemat' : 'lebih boros';
    final warnaLatar = hemat
        ? AppColors.benarLatar
        : (boros ? AppColors.salahLatar : AppColors.grid);
    final ikon = hemat
        ? Icons.arrow_downward
        : (boros ? Icons.arrow_upward : Icons.remove);
    final ikonTren = hemat
        ? Icons.trending_down
        : (boros ? Icons.trending_up : Icons.trending_flat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: AppSizes.tinggiGarisPemisah,
          color: AppColors.garis,
        ),
        const SizedBox(height: AppSpacing.sedang),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sedang,
                vertical: AppSpacing.sangatKecil,
              ),
              decoration: BoxDecoration(
                color: warnaLatar,
                border: Border.all(color: AppColors.ink, width: 1.0),
                borderRadius: BorderRadius.circular(AppSizes.radiusPil),
              ),
              child: Row(
                children: [
                  Icon(ikon, size: AppSizes.ikonSelisih, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.sangatKecil),
                  Text(
                    selisih == 0
                        ? 'Sama persis dengan pekan lalu'
                        : '$nominalAbsolut $teksStatus dibanding pekan lalu',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Icon(ikonTren, size: AppSizes.ikonAksi, color: AppColors.ink),
          ],
        ),
      ],
    );
  }
}

class _ItemTransaksi extends StatelessWidget {
  final TransaksiEntity transaksi;

  const _ItemTransaksi({required this.transaksi});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<KategoriCubit, KategoriState, KategoriEntity?>(
      selector: (state) {
        if (state is KategoriLoaded) {
          for (final k in state.kategoriList) {
            if (k.id == transaksi.kategoriId) return k;
          }
        }
        return null;
      },
      builder: (context, kategori) {
        final namaKategori = kategori != null
            ? _kapitalPertama(kategori.nama)
            : 'Tidak diketahui';
        final ikon = kategori != null ? _parseIkon(kategori.ikon) : Icons.help;
        final warna = kategori != null
            ? _parseWarna(kategori.warna)
            : AppColors.inkSoft;

        String waktu = '';
        try {
          final dt = DateTime.parse(transaksi.dibuatPada).toLocal();
          final jam = dt.hour.toString().padLeft(2, '0');
          final menit = dt.minute.toString().padLeft(2, '0');
          waktu = '$jam:$menit WIB';
        } catch (_) {
          waktu = '-';
        }

        return KartuTransaksi(
          nominal: transaksi.jumlah,
          namaKategori: namaKategori,
          catatan: transaksi.catatan,
          tipeKebutuhan: transaksi.tipeKebutuhan,
          waktu: waktu,
          ikonKategori: ikon,
          warnaKategori: warna,
          onTap: () => context.push('/transaksi/${transaksi.id}'),
        );
      },
    );
  }
}
