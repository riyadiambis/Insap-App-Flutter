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
import '../cubit/detail_transaksi_cubit.dart';
import '../cubit/detail_transaksi_state.dart';
import '../widgets/riwayat_helper.dart';

/// Layar Detail Transaksi (/transaksi/:id, P04-Router, P06-Cubit).
/// Menampilkan informasi lengkap transaksi yang dicatat dan tombol hapus
/// dengan dialog konfirmasi serta pembatalan di layar riwayat.
class HalamanDetailTransaksi extends StatelessWidget {
  final int id;

  const HalamanDetailTransaksi({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DetailTransaksiCubit>()..muat(id),
      child: const _DetailTransaksiView(),
    );
  }
}

class _DetailTransaksiView extends StatelessWidget {
  const _DetailTransaksiView();

  Future<void> _konfirmasiHapus(
    BuildContext context,
    DetailTransaksiLoaded state,
  ) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
          side: const BorderSide(color: AppColors.ink, width: AppSizes.border),
        ),
        title: Text(
          'Hapus Transaksi?',
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        content: const Text(
          'Catatan transaksi ini akan dihapus. Kamu masih bisa membatalkannya di layar riwayat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.salah,
              foregroundColor: AppColors.kartu,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                side: const BorderSide(
                  color: AppColors.ink,
                  width: AppSizes.border,
                ),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (setuju == true && context.mounted) {
      final cubit = context.read<DetailTransaksiCubit>();
      final sukses = await cubit.hapus();
      if (sukses && context.mounted) {
        try {
          context.read<BerandaCubit>().muatRingkasan();
        } catch (_) {}
        // Kembalikan objek transaksi ke halaman riwayat
        context.pop(state.transaksi);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
            child: BlocBuilder<DetailTransaksiCubit, DetailTransaksiState>(
              builder: (context, state) {
                return Column(
                  children: [
                    // Header Navigasi Atas
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.besar,
                        top: AppSpacing.besar,
                        right: AppSpacing.besar,
                        bottom: AppSpacing.sedang,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: AppSizes.kotakIkonAksi,
                              height: AppSizes.kotakIkonAksi,
                              decoration: BoxDecoration(
                                color: AppColors.kartu,
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: AppSizes.border,
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: const [
                                  AppTheme.bayanganKecilGelap,
                                ],
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

                    // Konten Utama
                    Expanded(
                      child: _bangunKonten(context, state),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _bangunKonten(BuildContext context, DetailTransaksiState state) {
    if (state is DetailTransaksiLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.tebalIndikatorMuat,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
        ),
      );
    }

    if (state is DetailTransaksiError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.besar),
          child: KartuBukuTulis(
            padding: const EdgeInsets.all(AppSpacing.lebihBesar),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 48,
                  color: AppColors.salah,
                ),
                const SizedBox(height: AppSpacing.sedang),
                Text(
                  state.pesan,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.kecil),
                Text(
                  'Catatan ini mungkin sudah dihapus atau tidak pernah ada di basis data.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lebihBesar),
                TombolStabilo(
                  teks: 'Kembali',
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is DetailTransaksiLoaded) {
      final trx = state.transaksi;

      return BlocBuilder<KategoriCubit, KategoriState>(
        builder: (context, katState) {
          final List<KategoriEntity> kategoriList =
              katState is KategoriLoaded ? katState.kategoriList : const [];
          final kat =
              RiwayatHelper.cariKategori(kategoriList, trx.kategoriId);

          final namaKat = kat != null
              ? RiwayatHelper.kapitalPertama(kat.nama)
              : 'Lainnya';
          final kelompokKat = kat != null
              ? RiwayatHelper.kapitalPertama(kat.kelompokKakeibo)
              : '-';
          final ikonKat = RiwayatHelper.parseIkon(kat?.ikon);
          final warnaKat = RiwayatHelper.parseWarna(kat?.warna);

          final sumberTeks =
              trx.sumber == 'pindai' ? 'Pindai Struk' : 'Manual';
          final kebutuhanTeks = trx.tipeKebutuhan == 'butuh'
              ? 'Butuh'
              : (trx.tipeKebutuhan == 'pengen'
                  ? 'Pengen'
                  : '-');

          return ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.besar,
              right: AppSpacing.besar,
              bottom: AppSpacing.jarakGulirBawah,
            ),
            children: [
              // Kartu Ringkasan Utama
              KartuBukuTulis(
                padding: const EdgeInsets.all(AppSpacing.lebihBesar),
                child: Column(
                  children: [
                    BadgeKategori(
                      ikon: ikonKat,
                      warna: warnaKat,
                      ukuran: 64.0,
                    ),
                    const SizedBox(height: AppSpacing.sedang),
                    Text(
                      namaKat,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sangatKecil),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sedang,
                        vertical: AppSpacing.sangatKecil,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPil),
                        border: Border.all(
                          color: AppColors.garis,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        'Kelompok: $kelompokKat',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.inkSoft,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.besar),
                    Text(
                      '-${trx.jumlah.toRupiah()}',
                      style: AppTheme.nominalUtama,
                    ),
                    const SizedBox(height: AppSpacing.besar),
                    const Divider(
                      color: AppColors.garis,
                      thickness: AppSizes.tebalGarisGrid,
                    ),
                    const SizedBox(height: AppSpacing.sedang),

                    // Rincian Baris demi Baris
                    _BarisDetail(
                      label: 'TANGGAL TRANSAKSI',
                      nilai: RiwayatHelper.formatTanggalLengkap(trx.tanggal),
                    ),
                    const SizedBox(height: AppSpacing.sedang),
                    _BarisDetail(
                      label: 'WAKTU DICATAT',
                      nilai: RiwayatHelper.formatJam(trx.dibuatPada),
                    ),
                    const SizedBox(height: AppSpacing.sedang),
                    _BarisDetail(
                      label: 'SUMBER PENCATATAN',
                      nilai: sumberTeks,
                      nilaiWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.kecil,
                          vertical: AppSpacing.mini,
                        ),
                        decoration: BoxDecoration(
                          color: trx.sumber == 'pindai'
                              ? AppColors.benarLatar
                              : AppColors.paper,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLabel),
                          border: Border.all(
                            color: trx.sumber == 'pindai'
                                ? AppColors.benar
                                : AppColors.garis,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trx.sumber == 'pindai'
                                  ? Icons.document_scanner_rounded
                                  : Icons.edit_note_rounded,
                              size: AppSizes.ikonKecil,
                              color: trx.sumber == 'pindai'
                                  ? AppColors.benar
                                  : AppColors.inkSoft,
                            ),
                            const SizedBox(width: AppSpacing.agakKecil),
                            Text(
                              sumberTeks,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: trx.sumber == 'pindai'
                                        ? AppColors.benar
                                        : AppColors.inkSoft,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sedang),
                    _BarisDetail(
                      label: 'TIPE KEBUTUHAN',
                      nilai: kebutuhanTeks,
                      nilaiWidget: trx.tipeKebutuhan != null &&
                              trx.tipeKebutuhan!.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sedang,
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
                                kebutuhanTeks,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),

              // Kartu Catatan (Bila ada)
              if (trx.catatan != null && trx.catatan!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.besar),
                KartuBukuTulis(
                  padding: const EdgeInsets.all(AppSpacing.besar),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CATATAN',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkSoft,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.kecil),
                      Text(
                        trx.catatan!.trim(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lebihBesar),

              // Tombol Hapus Transaksi
              GestureDetector(
                onTap: () => _konfirmasiHapus(context, state),
                child: Container(
                  height: AppSizes.tinggiTombol,
                  decoration: BoxDecoration(
                    color: AppColors.salahLatar,
                    borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                    border: Border.all(
                      color: AppColors.salah,
                      width: AppSizes.border,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.salah,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: AppSizes.ikonAksi,
                          color: AppColors.salah,
                        ),
                        SizedBox(width: AppSpacing.kecil),
                        Text(
                          'Hapus Transaksi',
                          style: TextStyle(
                            color: AppColors.salah,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class _BarisDetail extends StatelessWidget {
  final String label;
  final String nilai;
  final Widget? nilaiWidget;

  const _BarisDetail({
    required this.label,
    required this.nilai,
    this.nilaiWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(width: AppSpacing.sedang),
        Flexible(
          child: nilaiWidget ??
              Text(
                nilai,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
              ),
        ),
      ],
    );
  }
}
