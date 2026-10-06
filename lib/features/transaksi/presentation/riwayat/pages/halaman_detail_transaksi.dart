import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/paper_background.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/utils/rupiah_extension.dart';
import '../../../../../core/widgets/badge_kategori.dart';
import '../../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../../core/widgets/tombol_stabilo.dart';
import '../../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../../kategori/domain/entities/kategori_entity.dart';
import '../../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../../kategori/presentation/cubit/kategori_state.dart';
import '../../../domain/entities/transaksi_entity.dart';
import '../cubit/detail_transaksi_cubit.dart';
import '../cubit/detail_transaksi_state.dart';
import '../widgets/riwayat_helper.dart';

// Layar Detail Transaksi (/transaksi/:id, F-02, ISSUE-03)
class HalamanDetailTransaksi extends StatelessWidget {
  final int id;

  const HalamanDetailTransaksi({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DetailTransaksiCubit>()..muat(id),
      child: _HalamanDetailTransaksiView(id: id),
    );
  }
}

class _HalamanDetailTransaksiView extends StatelessWidget {
  final int id;

  const _HalamanDetailTransaksiView({required this.id});

  Future<void> _konfirmasiHapus(
    BuildContext context,
    TransaksiEntity transaksi,
  ) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
          side: const BorderSide(
            color: AppColors.ink,
            width: AppSizes.border,
          ),
        ),
        title: Text(
          'Hapus Transaksi?',
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        content: const Text(
          'Catatan transaksi ini akan dihapus dari riwayat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: AppColors.salah,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (setuju == true && context.mounted) {
      final sukses = await context.read<DetailTransaksiCubit>().hapus();
      if (sukses && context.mounted) {
        context.read<BerandaCubit>().muatRingkasan();
        context.pop(transaksi);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.batasLebarKonten,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header Navigasi Atas
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.besar,
                      vertical: AppSpacing.sedang,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 38.0,
                            height: 38.0,
                            decoration: BoxDecoration(
                              color: AppColors.kartu,
                              border: Border.all(
                                color: AppColors.ink,
                                width: AppSizes.border,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: const [AppTheme.bayanganKecilGelap],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: AppSizes.ikonAksi,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sedang),
                        Text(
                          'Detail Transaksi',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Konten Detail
                  Expanded(
                    child: BlocBuilder<DetailTransaksiCubit, DetailTransaksiState>(
                      builder: (context, state) {
                        if (state is DetailTransaksiLoading ||
                            state is DetailTransaksiInitial) {
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: AppSizes.tebalIndikatorMuat,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.ink),
                            ),
                          );
                        }

                        if (state is DetailTransaksiError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.besar),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 64,
                                    color: AppColors.inkSoft,
                                  ),
                                  const SizedBox(height: AppSpacing.sedang),
                                  Text(
                                    state.pesan,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.besar),
                                  TombolStabilo(
                                    teks: 'Kembali ke Riwayat',
                                    onPressed: () => context.pop(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state is DetailTransaksiLoaded) {
                          return _bangunLembarKuitansi(
                            context,
                            state.transaksi,
                          );
                        }

                        return const SizedBox();
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

  Widget _bangunLembarKuitansi(
    BuildContext context,
    TransaksiEntity trx,
  ) {
    return BlocBuilder<KategoriCubit, KategoriState>(
      builder: (context, katState) {
        final List<KategoriEntity> kategoriList =
            katState is KategoriLoaded ? katState.kategoriList : const [];
        final kategori =
            RiwayatHelper.cariKategori(kategoriList, trx.kategoriId);

        final namaKategori = kategori?.nama ?? 'Lainnya';
        final ikon = RiwayatHelper.parseIkon(kategori?.ikon ?? 'more_horiz');
        final warna =
            RiwayatHelper.parseWarna(kategori?.warna ?? '#5B7793');

        return ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.besar,
            right: AppSpacing.besar,
            bottom: AppSpacing.jarakGulirBawah,
          ),
          children: [
            const SizedBox(height: AppSpacing.kecil),
            // Kuitansi Lembar Buku Tulis
            KartuBukuTulis(
              radius: AppSizes.radiusKartu,
              padding: const EdgeInsets.all(AppSpacing.lebihBesar),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Badge Kategori Besar di Tengah
                  Center(
                    child: BadgeKategori(
                      ikon: ikon,
                      warna: warna,
                      ukuran: 60.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sedang),
                  Center(
                    child: Text(
                      namaKategori,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (kategori != null &&
                      kategori.kelompokKakeibo.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.mini),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.kecil,
                          vertical: AppSpacing.mini,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPil),
                          border: Border.all(
                            color: AppColors.inkSoft,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          kategori.kelompokKakeibo.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.besar),
                  // Nominal Besar
                  Center(
                    child: Text(
                      '-${trx.jumlah.toRupiah()}',
                      style: AppTheme.nominalUtama.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lebihBesar),

                  // Garis Pemisah Kuitansi
                  Container(
                    height: AppSizes.tinggiGarisPemisah,
                    color: AppColors.garis,
                  ),
                  const SizedBox(height: AppSpacing.lebihBesar),

                  // Rincian Baris-Baris
                  _barisRincian(
                    context,
                    label: 'Tanggal',
                    nilai: RiwayatHelper.formatTanggalLengkap(trx.tanggal),
                  ),
                  const SizedBox(height: AppSpacing.sedang),
                  _barisRincian(
                    context,
                    label: 'Waktu Dicatat',
                    nilai: RiwayatHelper.formatWaktuJam(trx.dibuatPada),
                  ),
                  const SizedBox(height: AppSpacing.sedang),
                  _barisRincian(
                    context,
                    label: 'Sumber',
                    nilai: trx.sumber == 'pindai'
                        ? 'Pindai Struk'
                        : 'Manual',
                  ),
                  if (trx.namaToko != null &&
                      trx.namaToko!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sedang),
                    _barisRincian(
                      context,
                      label: 'Toko / Lokasi',
                      nilai: trx.namaToko!,
                    ),
                  ],
                  if (trx.tipeKebutuhan != null &&
                      trx.tipeKebutuhan!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sedang),
                    _barisRincian(
                      context,
                      label: 'Kebutuhan',
                      widgetNilai: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.agakKecil,
                          vertical: AppSpacing.mini,
                        ),
                        decoration: BoxDecoration(
                          color: trx.tipeKebutuhan == 'butuh'
                              ? AppColors.stabilo
                              : AppColors.grid,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLabel),
                          border: Border.all(
                            color: AppColors.ink,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          trx.tipeKebutuhan == 'butuh'
                              ? 'Butuh (Pokok)'
                              : 'Pengen (Keinginan)',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ),
                  ],

                  // Catatan (jika ada)
                  if (trx.catatan != null &&
                      trx.catatan!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lebihBesar),
                    Text(
                      'CATATAN',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.kecil),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sedang),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusTombol),
                        border: Border.all(
                          color: AppColors.garis,
                          width: AppSizes.border,
                        ),
                      ),
                      child: Text(
                        trx.catatan!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.ink,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lebihBesar),

            // Tombol Hapus Transaksi
            GestureDetector(
              onTap: () => _konfirmasiHapus(context, trx),
              child: Container(
                height: AppSizes.tinggiTombol,
                decoration: BoxDecoration(
                  color: AppColors.salahLatar,
                  border: Border.all(
                    color: AppColors.salah,
                    width: AppSizes.border,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                  boxShadow: const [AppTheme.bayanganDefault],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.salah,
                      size: AppSizes.ikonAksi,
                    ),
                    SizedBox(width: AppSpacing.kecil),
                    Text(
                      'Hapus Transaksi',
                      style: TextStyle(
                        color: AppColors.salah,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _barisRincian(
    BuildContext context, {
    required String label,
    String? nilai,
    Widget? widgetNilai,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (widgetNilai != null)
          widgetNilai
        else
          Text(
            nilai ?? '-',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
      ],
    );
  }
}
