import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/paper_background.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/widgets/header_aplikasi.dart';
import '../../../../../core/widgets/kartu_buku_tulis.dart';
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

/// Layar utama Riwayat Transaksi (F-02, P03-Widget, P05-Tema).
/// Menampilkan daftar transaksi yang dikelompokkan per tanggal menurun,
/// saringan rentang tanggal & kategori, serta alur geser hapus dengan SnackBar Batal.
class HalamanRiwayat extends StatelessWidget {
  const HalamanRiwayat({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RiwayatCubit>()..muatRiwayat(),
      child: const _RiwayatView(),
    );
  }
}

class _RiwayatView extends StatelessWidget {
  const _RiwayatView();

  void _bukaFilter(BuildContext context) {
    final state = context.read<RiwayatCubit>().state;
    BottomSheetFilter.tampilkan(
      context: context,
      initialTanggalMulai: state.filterTanggalMulai,
      initialTanggalAkhir: state.filterTanggalAkhir,
      initialKategoriId: state.filterKategoriId,
      onTerapkan: ({tanggalMulai, tanggalAkhir, kategoriId}) {
        context.read<RiwayatCubit>().terapkanFilter(
              tanggalMulai: tanggalMulai,
              tanggalAkhir: tanggalAkhir,
              kategoriId: kategoriId,
            );
      },
      onReset: () {
        context.read<RiwayatCubit>().resetFilter();
      },
    );
  }

  void _hapusTransaksi(BuildContext context, TransaksiEntity trx) {
    final cubit = context.read<RiwayatCubit>();
    cubit.hapus(trx);

    try {
      context.read<BerandaCubit>().muatRingkasan();
    } catch (_) {}

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaksi berhasil dihapus'),
        action: SnackBarAction(
          label: 'Batal',
          textColor: AppColors.stabilo,
          onPressed: () async {
            await cubit.batalHapus(trx);
            if (context.mounted) {
              try {
                context.read<BerandaCubit>().muatRingkasan();
              } catch (_) {}
            }
          },
        ),
      ),
    );
  }

  Future<bool> _konfirmasiHapus(BuildContext context) async {
    final hasil = await showDialog<bool>(
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
          'Apakah kamu yakin ingin menghapus catatan transaksi ini?',
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
    return hasil ?? false;
  }

  List<_ItemRiwayat> _susunItemRiwayat(List<TransaksiEntity> daftar) {
    final List<_ItemRiwayat> items = [];
    final Map<String, List<TransaksiEntity>> perTanggal = {};

    for (final trx in daftar) {
      perTanggal.putIfAbsent(trx.tanggal, () => []).add(trx);
    }

    // Urutkan tanggal secara menurun (terbaru di atas)
    final tanggalTersortir = perTanggal.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final tgl in tanggalTersortir) {
      items.add(_HeaderTanggalItem(tgl));
      for (final trx in perTanggal[tgl]!) {
        items.add(_TransaksiItem(trx));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
            child: BlocBuilder<RiwayatCubit, RiwayatState>(
              builder: (context, state) {
                final isFilterAktif = state.isFilterAktif;

                return Column(
                  children: [
                    // Bagian Kepala Atas (Padding tetap di atas)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.besar,
                        top: AppSpacing.besar,
                        right: AppSpacing.besar,
                        bottom: AppSpacing.sedang,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.sangatKecil),
                          const HeaderAplikasi(namaLayar: 'RIWAYAT'),
                          const SizedBox(height: AppSpacing.lebihBesar),
                          _JudulRiwayat(
                            isFilterAktif: isFilterAktif,
                            onTapFilter: () => _bukaFilter(context),
                          ),
                        ],
                      ),
                    ),

                    // Konten Daftar / Status
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
    if (state.status == RiwayatStatus.loading &&
        state.daftarTransaksi.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.tebalIndikatorMuat,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
        ),
      );
    }

    if (state.status == RiwayatStatus.error &&
        state.daftarTransaksi.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.besar),
          child: KartuBukuTulis(
            padding: const EdgeInsets.all(AppSpacing.lebihBesar),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.salah,
                ),
                const SizedBox(height: AppSpacing.sedang),
                Text(
                  'Gagal Memuat Riwayat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.kecil),
                Text(
                  state.pesanError ?? 'Terjadi kesalahan sistem.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.besar),
                TombolStabilo(
                  teks: 'Coba Lagi',
                  onPressed: () =>
                      context.read<RiwayatCubit>().muatRiwayat(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Keadaan Kosong (Tanpa data)
    if (state.daftarTransaksi.isEmpty) {
      return _bangunKeadaanKosong(context, state.isFilterAktif);
    }

    // Daftar Transaksi Terisi
    final listItems = _susunItemRiwayat(state.daftarTransaksi);

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
          itemCount: listItems.length,
          itemBuilder: (context, index) {
            final item = listItems[index];

            if (item is _HeaderTanggalItem) {
              return Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sedang,
                  bottom: AppSpacing.kecil,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: const BoxDecoration(
                        color: AppColors.inkSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.kecil),
                    Text(
                      RiwayatHelper.formatTanggalGrup(item.tanggal),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkSoft,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              );
            }

            final trxItem = item as _TransaksiItem;
            final trx = trxItem.transaksi;
            final kat = RiwayatHelper.cariKategori(kategoriList, trx.kategoriId);

            final namaKat = kat != null
                ? RiwayatHelper.kapitalPertama(kat.nama)
                : 'Lainnya';
            final ikonKat = RiwayatHelper.parseIkon(kat?.ikon);
            final warnaKat = RiwayatHelper.parseWarna(kat?.warna);

            final jam = RiwayatHelper.formatJam(trx.dibuatPada);
            final waktuTampil =
                trx.sumber == 'pindai' ? '$jam • Struk' : jam;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sedang),
              child: Dismissible(
                key: Key('transaksi_${trx.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) => _konfirmasiHapus(context),
                onDismissed: (direction) => _hapusTransaksi(context, trx),
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Hapus',
                        style: TextStyle(
                          color: AppColors.salah,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: AppSpacing.kecil),
                      Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.salah,
                        size: AppSizes.ikonAksi,
                      ),
                    ],
                  ),
                ),
                child: KartuTransaksi(
                  nominal: trx.jumlah,
                  namaKategori: namaKat,
                  catatan: trx.catatan,
                  waktu: waktuTampil,
                  ikonKategori: ikonKat,
                  warnaKategori: warnaKat,
                  tipeKebutuhan: trx.tipeKebutuhan,
                  onTap: () async {
                    final hasil =
                        await context.push<dynamic>('/transaksi/${trx.id}');
                    if (!context.mounted) return;

                    if (hasil is TransaksiEntity) {
                      final cubit = context.read<RiwayatCubit>();
                      await cubit.muatRiwayat();
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Transaksi berhasil dihapus'),
                          action: SnackBarAction(
                            label: 'Batal',
                            textColor: AppColors.stabilo,
                            onPressed: () async {
                              await cubit.batalHapus(hasil);
                              if (context.mounted) {
                                try {
                                  context
                                      .read<BerandaCubit>()
                                      .muatRingkasan();
                                } catch (_) {}
                              }
                            },
                          ),
                        ),
                      );
                    } else {
                      context.read<RiwayatCubit>().muatRiwayat();
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _bangunKeadaanKosong(BuildContext context, bool isFilterAktif) {
    if (isFilterAktif) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.besar),
          child: KartuBukuTulis(
            padding: const EdgeInsets.all(AppSpacing.lebihBesar),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.filter_alt_off_rounded,
                  size: 48,
                  color: AppColors.inkSoft,
                ),
                const SizedBox(height: AppSpacing.sedang),
                Text(
                  'Tidak ada transaksi yang cocok',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.kecil),
                Text(
                  'Coba ubah atau atur ulang saringan tanggal dan kategori yang kamu pilih.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lebihBesar),
                TombolStabilo(
                  teks: 'Reset Saringan',
                  ikon: Icons.refresh_rounded,
                  onPressed: () =>
                      context.read<RiwayatCubit>().resetFilter(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.besar),
        child: KartuBukuTulis(
          padding: const EdgeInsets.all(AppSpacing.lebihBesar),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 54,
                color: AppColors.inkSoft,
              ),
              const SizedBox(height: AppSpacing.sedang),
              Text(
                'Belum Ada Catatan Boncos',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.kecil),
              Text(
                'Yuk catat pengeluaran pertamamu agar sadar dan kendalikan boncos!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                    ),
              ),
              const SizedBox(height: AppSpacing.lebihBesar),
              TombolStabilo(
                teks: 'Catat Pengeluaran',
                ikon: Icons.add_circle_outline_rounded,
                onPressed: () => context.go('/catat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Judul layar dengan aksen stabilo dan tombol saringan di kanan atas
class _JudulRiwayat extends StatelessWidget {
  final bool isFilterAktif;
  final VoidCallback onTapFilter;

  const _JudulRiwayat({
    required this.isFilterAktif,
    required this.onTapFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
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
              const SizedBox(width: AppSpacing.agakKecil),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            bottom: AppSizes.geserStabiloJudul,
                            left: -AppSizes.geserStabiloJudul,
                            right: -AppSizes.geserStabiloJudul,
                            height: AppSizes.tinggiStabiloJudul,
                            child: Container(color: AppColors.stabilo),
                          ),
                          Text(
                            'Riwayat',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.kecil),
                      Text(
                        'Transaksi',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sedang),
        GestureDetector(
          onTap: onTapFilter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: AppSizes.kotakIkonAksi,
                height: AppSizes.kotakIkonAksi,
                decoration: BoxDecoration(
                  color: isFilterAktif ? AppColors.stabilo : AppColors.kartu,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.border,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: const [AppTheme.bayanganKecilGelap],
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: AppSizes.ikonAksi,
                  color: AppColors.ink,
                ),
              ),
              if (isFilterAktif)
                Positioned(
                  top: -2.0,
                  right: -2.0,
                  child: Container(
                    width: AppSizes.ukuranTitikIndikator + 2,
                    height: AppSizes.ukuranTitikIndikator + 2,
                    decoration: BoxDecoration(
                      color: AppColors.salah,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Model bantu untuk item flat di ListView
sealed class _ItemRiwayat {}

class _HeaderTanggalItem extends _ItemRiwayat {
  final String tanggal;
  _HeaderTanggalItem(this.tanggal);
}

class _TransaksiItem extends _ItemRiwayat {
  final TransaksiEntity transaksi;
  _TransaksiItem(this.transaksi);
}
