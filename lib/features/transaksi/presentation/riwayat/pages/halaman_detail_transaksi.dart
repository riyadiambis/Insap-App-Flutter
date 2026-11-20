import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/paper_background.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/utils/rupiah_extension.dart';
import '../../../../../core/widgets/header_aplikasi.dart';
import '../../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../../core/widgets/tombol_stabilo.dart';
import '../../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../../kategori/domain/entities/kategori_entity.dart';
import '../../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../../kategori/presentation/cubit/kategori_state.dart';
import '../cubit/detail_transaksi_cubit.dart';
import '../cubit/detail_transaksi_state.dart';
import '../cubit/riwayat_cubit.dart';
import '../widgets/riwayat_helper.dart';

/// Layar Detail Transaksi (/transaksi/:id, P04-Router, P06-Cubit).
class HalamanDetailTransaksi extends StatelessWidget {
  final int id;

  const HalamanDetailTransaksi({super.key, required this.id});

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
          style: Theme.of(
            ctx,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
        try {
          context.read<RiwayatCubit>().muatRiwayat();
        } catch (_) {}
        context.pop(state.transaksi);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderAplikasi(
        namaLayar: 'Detail',
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
              child: BlocBuilder<DetailTransaksiCubit, DetailTransaksiState>(
                builder: (context, state) => _bangunKonten(context, state),
              ),
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
            shadow: AppTheme.bayanganGelap,
            pressedShadow: AppTheme.bayanganGelapTertekan,
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
          final List<KategoriEntity> kategoriList = katState is KategoriLoaded
              ? katState.kategoriList
              : const [];
          final kat = RiwayatHelper.cariKategori(kategoriList, trx.kategoriId);

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
              : (trx.tipeKebutuhan == 'pengen' ? 'Pengen' : '-');
          final jam = RiwayatHelper.formatJam(trx.dibuatPada);
          final subJudul = [
            if (trx.namaToko != null && trx.namaToko!.trim().isNotEmpty)
              trx.namaToko!.trim(),
            '${RiwayatHelper.formatTanggalLengkap(trx.tanggal)}, $jam',
          ].join(' · ');

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.besar,
              AppSpacing.besar,
              AppSpacing.besar,
              AppSpacing.jarakGulirBawah,
            ),
            children: [
              // Kartu ringkasan atas sesuai Detail.dc.html
              KartuBukuTulis(
                shadow: AppTheme.bayanganGelap,
                pressedShadow: AppTheme.bayanganGelapTertekan,
                padding: const EdgeInsets.all(AppSpacing.besar),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kartu,
                        border: Border.all(color: warnaKat, width: 2.0),
                        borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(ikonKat, size: 15, color: warnaKat),
                          const SizedBox(width: 5),
                          Text(
                            namaKat,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.kecil),
                    Text(
                      trx.jumlah.toRupiah(),
                      style: AppTheme.nominalBesar.copyWith(fontSize: 38),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subJudul,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          trx.sumber == 'pindai'
                              ? Icons.receipt_long_outlined
                              : Icons.edit_note_rounded,
                          size: 15,
                          color: trx.sumber == 'pindai'
                              ? AppColors.daunTua
                              : AppColors.inkSoft,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sumberTeks,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: trx.sumber == 'pindai'
                                ? AppColors.daunTua
                                : AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.besar),

              // Kartu Rincian dengan garis putus
              KartuBukuTulis(
                shadow: AppTheme.bayanganGelap,
                pressedShadow: AppTheme.bayanganGelapTertekan,
                padding: const EdgeInsets.all(AppSpacing.besar),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rincian',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.kecil),
                    _BarisRincian(label: 'Kelompok Kakeibo', nilai: kelompokKat),
                    _BarisRincian(
                      label: 'Tanggal',
                      nilai: RiwayatHelper.formatTanggalLengkap(trx.tanggal),
                    ),
                    _BarisRincian(label: 'Waktu dicatat', nilai: jam),
                    if (trx.namaToko != null &&
                        trx.namaToko!.trim().isNotEmpty)
                      _BarisRincian(
                        label: 'Toko',
                        nilai: trx.namaToko!.trim(),
                      ),
                    _BarisRincian(
                      label: 'Kebutuhan',
                      nilai: kebutuhanTeks,
                      tampilkanGaris:
                          trx.catatan != null && trx.catatan!.trim().isNotEmpty,
                    ),
                    if (trx.catatan != null && trx.catatan!.trim().isNotEmpty)
                      _BarisRincian(
                        label: 'Catatan',
                        nilai: trx.catatan!.trim(),
                        tampilkanGaris: false,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lebihBesar),

              // Tombol Hapus Transaksi gaya Detail.dc.html
              Semantics(
                button: true,
                label: 'Hapus',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _konfirmasiHapus(context, state),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.kartu,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusTombol,
                        ),
                        border: Border.all(
                          color: AppColors.merahTeks,
                          width: AppSizes.border,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.merahTeks,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.merahTeks,
                          ),
                          SizedBox(width: AppSpacing.kecil),
                          Text(
                            'Hapus',
                            style: TextStyle(
                              color: AppColors.merahTeks,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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

class _BarisRincian extends StatelessWidget {
  final String label;
  final String nilai;
  final bool tampilkanGaris;

  const _BarisRincian({
    required this.label,
    required this.nilai,
    this.tampilkanGaris = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sedang),
              Flexible(
                child: Text(
                  nilai,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (tampilkanGaris)
          CustomPaint(
            size: const Size(double.infinity, 1.5),
            painter: _GarisPutusDetailPainter(),
          ),
      ],
    );
  }
}

class _GarisPutusDetailPainter extends CustomPainter {
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
