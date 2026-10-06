import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/paper_background.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/widgets/header_aplikasi.dart';
import '../../../../../core/widgets/tombol_stabilo.dart';
import '../../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../../kategori/domain/entities/kategori_entity.dart';
import '../../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../../kategori/presentation/cubit/kategori_state.dart';
import '../../../domain/entities/transaksi_entity.dart';
import '../../widgets/kartu_transaksi.dart';
import '../cubit/riwayat_cubit.dart';
import '../cubit/riwayat_state.dart';
import '../widgets/bottom_sheet_filter.dart';
import '../widgets/riwayat_helper.dart';

// Layar Riwayat Transaksi (F-02, ISSUE-03)
class HalamanRiwayat extends StatelessWidget {
  const HalamanRiwayat({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RiwayatCubit>()..muatRiwayat(),
      child: const _HalamanRiwayatView(),
    );
  }
}

class _HalamanRiwayatView extends StatelessWidget {
  const _HalamanRiwayatView();

  void _konfirmasiDanHapus(
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
          'Hapus Catatan Ini?',
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        content: const Text(
          'Catatan pengeluaran ini akan dihapus dari riwayat transaksi.',
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
      await context.read<RiwayatCubit>().hapus(transaksi);
      if (context.mounted) {
        context.read<BerandaCubit>().muatRingkasan();
        _tampilkanSnackbarUndo(context, transaksi);
      }
    }
  }

  void _tampilkanSnackbarUndo(BuildContext context, TransaksiEntity transaksi) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaksi dihapus'),
        action: SnackBarAction(
          label: 'Batal',
          textColor: AppColors.stabilo,
          onPressed: () async {
            await context.read<RiwayatCubit>().batalHapus(transaksi);
            if (context.mounted) {
              context.read<BerandaCubit>().muatRingkasan();
            }
          },
        ),
      ),
    );
  }

  Future<void> _bukaDetail(
    BuildContext context,
    TransaksiEntity transaksi,
  ) async {
    final hasil = await context.push('/transaksi/${transaksi.id}');
    if (hasil is TransaksiEntity && context.mounted) {
      // Kembali dari detail karena dihapus
      await context.read<RiwayatCubit>().muatRiwayat();
      if (context.mounted) {
        context.read<BerandaCubit>().muatRingkasan();
        _tampilkanSnackbarUndo(context, hasil);
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
            child: BlocBuilder<RiwayatCubit, RiwayatState>(
              builder: (context, state) {
                return Column(
                  children: [
                    // Area Kepala Halaman
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.besar,
                        top: AppSpacing.besar,
                        right: AppSpacing.besar,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.sangatKecil),
                          const HeaderAplikasi(namaLayar: 'RIWAYAT'),
                          const SizedBox(height: AppSpacing.besar),
                          // Judul + Tombol Saringan
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.bottomLeft,
                                  children: [
                                    Positioned(
                                      bottom: 4,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: AppSizes.tinggiStabiloJudul,
                                        color: AppColors.stabilo,
                                      ),
                                    ),
                                    Text(
                                      'Riwayat Transaksi',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sedang),
                              // Tombol Ikon Saringan
                              GestureDetector(
                                onTap: () =>
                                    BottomSheetFilter.tampilkan(context),
                                child: Container(
                                  width: AppSizes.kotakIkonAksi,
                                  height: AppSizes.kotakIkonAksi,
                                  decoration: BoxDecoration(
                                    color: state.isFilterAktif
                                        ? AppColors.stabilo
                                        : AppColors.kartu,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                    boxShadow: const [
                                      AppTheme.bayanganKecilGelap
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(
                                        Icons.tune_rounded,
                                        size: AppSizes.ikonAksi,
                                        color: AppColors.ink,
                                      ),
                                      if (state.isFilterAktif)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.salah,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sedang),
                        ],
                      ),
                    ),

                    // Area Konten Daftar Transaksi
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

  Widget _bangunKonten(BuildContext context, RiwayatState state) {
    if (state.status == RiwayatStatus.loading ||
        state.status == RiwayatStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.tebalIndikatorMuat,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
        ),
      );
    }

    if (state.status == RiwayatStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.besar),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ups, gagal memuat riwayat:\n${state.pesanError}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.besar),
              TombolStabilo(
                teks: 'Coba Lagi',
                onPressed: () => context.read<RiwayatCubit>().muatRiwayat(),
              ),
            ],
          ),
        ),
      );
    }

    // Keadaan Kosong
    if (state.daftarTransaksi.isEmpty) {
      if (state.isFilterAktif) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.besar),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: AppColors.inkSoft,
                ),
                const SizedBox(height: AppSpacing.sedang),
                Text(
                  'Tidak ada transaksi yang cocok',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sangatKecil),
                Text(
                  'Coba ubah rentang tanggal atau kategori saringan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                ),
                const SizedBox(height: AppSpacing.besar),
                OutlinedButton(
                  onPressed: () => context.read<RiwayatCubit>().resetFilter(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(
                      color: AppColors.ink,
                      width: AppSizes.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusTombol),
                    ),
                  ),
                  child: const Text('Reset Saringan'),
                ),
              ],
            ),
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.besar),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: AppColors.inkSoft,
              ),
              const SizedBox(height: AppSpacing.sedang),
              Text(
                'Belum ada catatan boncos.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sangatKecil),
              Text(
                'Yuk catat pengeluaran pertamamu!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                    ),
              ),
              const SizedBox(height: AppSpacing.lebihBesar),
              TombolStabilo(
                teks: 'Catat Pengeluaran',
                onPressed: () => context.go('/catat'),
              ),
            ],
          ),
        ),
      );
    }

    // Kelompokkan per tanggal
    final grupList = _kelompokkanTransaksi(state.daftarTransaksi);

    return BlocBuilder<KategoriCubit, KategoriState>(
      builder: (context, katState) {
        final List<KategoriEntity> kategoriList =
            katState is KategoriLoaded ? katState.kategoriList : const [];

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: AppSpacing.besar,
            right: AppSpacing.besar,
            bottom: AppSpacing.jarakGulirBawah,
          ),
          itemCount: grupList.length,
          itemBuilder: (context, index) {
            final item = grupList[index];

            if (item is _HeaderItem) {
              return Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.besar,
                  bottom: AppSpacing.kecil,
                ),
                child: Text(
                  RiwayatHelper.formatHeaderTanggal(item.tanggal),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                ),
              );
            }

            if (item is _TransaksiItem) {
              final trx = item.transaksi;
              final kategori =
                  RiwayatHelper.cariKategori(kategoriList, trx.kategoriId);

              final namaKategori = kategori?.nama ?? 'Lainnya';
              final ikon = RiwayatHelper.parseIkon(
                kategori?.ikon ?? 'more_horiz',
              );
              final warna = RiwayatHelper.parseWarna(
                kategori?.warna ?? '#5B7793',
              );

              final waktuJam = RiwayatHelper.formatWaktuJam(trx.dibuatPada);
              final waktuTampil = trx.sumber == 'pindai'
                  ? '$waktuJam • Struk'
                  : waktuJam;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sedang),
                child: Dismissible(
                  key: ValueKey('trx_${trx.id}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    _konfirmasiDanHapus(context, trx);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.besar),
                    decoration: BoxDecoration(
                      color: AppColors.salahLatar,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusTombol),
                      border: Border.all(
                        color: AppColors.salah,
                        width: AppSizes.border,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.salah,
                          size: AppSizes.ikonAksi,
                        ),
                        SizedBox(width: AppSpacing.kecil),
                        Text(
                          'Hapus',
                          style: TextStyle(
                            color: AppColors.salah,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: KartuTransaksi(
                    nominal: trx.jumlah,
                    namaKategori: namaKategori,
                    catatan: trx.catatan,
                    waktu: waktuTampil,
                    ikonKategori: ikon,
                    warnaKategori: warna,
                    tipeKebutuhan: trx.tipeKebutuhan,
                    onTap: () => _bukaDetail(context, trx),
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        );
      },
    );
  }

  List<_BarisListItem> _kelompokkanTransaksi(
    List<TransaksiEntity> daftar,
  ) {
    final Map<String, List<TransaksiEntity>> peta = {};
    for (final trx in daftar) {
      peta.putIfAbsent(trx.tanggal, () => []).add(trx);
    }

    final hasil = <_BarisListItem>[];
    for (final entry in peta.entries) {
      hasil.add(_HeaderItem(entry.key));
      for (final trx in entry.value) {
        hasil.add(_TransaksiItem(trx));
      }
    }
    return hasil;
  }
}

sealed class _BarisListItem {}

class _HeaderItem extends _BarisListItem {
  final String tanggal;
  _HeaderItem(this.tanggal);
}

class _TransaksiItem extends _BarisListItem {
  final TransaksiEntity transaksi;
  _TransaksiItem(this.transaksi);
}
