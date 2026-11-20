import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/paper_background.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/utils/rupiah_extension.dart';
import '../../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../../core/widgets/maskot_struki.dart';
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

enum _FilterSumber { semua, struk, manual }

/// Layar utama Riwayat Transaksi (F-02, P03-Widget, P05-Tema).
/// Menampilkan daftar transaksi yang dikelompokkan per tanggal menurun,
/// saringan rentang tanggal & kategori, serta alur geser hapus dengan SnackBar Batal.
class HalamanRiwayat extends StatelessWidget {
  const HalamanRiwayat({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RiwayatView();
  }
}

class _RiwayatView extends StatefulWidget {
  const _RiwayatView();

  @override
  State<_RiwayatView> createState() => _RiwayatViewState();
}

class _RiwayatViewState extends State<_RiwayatView> {
  final TextEditingController _cariController = TextEditingController();
  String _kataKunci = '';
  _FilterSumber _filterSumber = _FilterSumber.semua;

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

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

  Future<void> _hapusTransaksi(BuildContext context, TransaksiEntity trx) async {
    final cubit = context.read<RiwayatCubit>();
    await cubit.hapus(trx);

    if (!context.mounted) return;

    if (cubit.state.status != RiwayatStatus.error) {
      try {
        context.read<BerandaCubit>().muatRingkasan();
      } catch (_) {}
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaksi berhasil dihapus'),
        action: SnackBarAction(
          label: 'Batal',
          textColor: AppColors.stabilo,
          onPressed: () async {
            await cubit.batalHapus(trx);
            if (context.mounted && cubit.state.status != RiwayatStatus.error) {
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
          style: Theme.of(
            ctx,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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

  List<TransaksiEntity> _saringLokal(
    List<TransaksiEntity> daftar,
    List<KategoriEntity> kategoriList,
  ) {
    final q = _kataKunci.trim().toLowerCase();
    return daftar.where((trx) {
      if (_filterSumber == _FilterSumber.struk && trx.sumber != 'pindai') {
        return false;
      }
      if (_filterSumber == _FilterSumber.manual && trx.sumber == 'pindai') {
        return false;
      }
      if (q.isNotEmpty) {
        final kat = RiwayatHelper.cariKategori(kategoriList, trx.kategoriId);
        final cocokCatatan = trx.catatan?.toLowerCase().contains(q) ?? false;
        final cocokToko = trx.namaToko?.toLowerCase().contains(q) ?? false;
        final cocokKat = kat?.nama.toLowerCase().contains(q) ?? false;
        if (!cocokCatatan && !cocokToko && !cocokKat) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<_ItemRiwayat> _susunItemRiwayat(List<TransaksiEntity> daftar) {
    final List<_ItemRiwayat> items = [];
    final Map<String, List<TransaksiEntity>> perTanggal = {};

    for (final trx in daftar) {
      perTanggal.putIfAbsent(trx.tanggal, () => []).add(trx);
    }

    final tanggalTersortir = perTanggal.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final tgl in tanggalTersortir) {
      final listTgl = perTanggal[tgl]!;
      final totalHarian = listTgl.fold<int>(0, (sum, trx) => sum + trx.jumlah);
      items.add(_HeaderTanggalItem(tgl, totalHarian));
      for (final trx in listTgl) {
        items.add(_TransaksiItem(trx));
      }
    }

    return items;
  }

  bool get _adaFilterLokal =>
      _kataKunci.trim().isNotEmpty || _filterSumber != _FilterSumber.semua;

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
                final isFilterAktif = state.isFilterAktif;
                final bool benarKosong =
                    state.status != RiwayatStatus.loading &&
                    state.status != RiwayatStatus.error &&
                    state.daftarTransaksi.isEmpty &&
                    !isFilterAktif &&
                    !_adaFilterLokal;

                return Column(
                  children: [
                    // Baris cari + tombol filter + chip sumber (disembunyikan saat benar-benar kosong sesuai Kosong.dc.html)
                    if (!benarKosong)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.besar,
                          AppSpacing.besar,
                          AppSpacing.besar,
                          AppSpacing.sedang,
                        ),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  padding: EdgeInsets.only(
                                    left: 14,
                                    right: _kataKunci.isNotEmpty ? 0 : 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.kartu,
                                    border: Border.all(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusBadge,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search_rounded,
                                        size: 18,
                                        color: AppColors.inkSoft,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          key: const Key('input_cari_riwayat'),
                                          controller: _cariController,
                                          onChanged: (val) =>
                                              setState(() => _kataKunci = val),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                          decoration: InputDecoration(
                                            hintText: 'Cari catatan',
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.inkSoft,
                                                ),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                      if (_kataKunci.isNotEmpty)
                                        Semantics(
                                          button: true,
                                          label: 'Hapus pencarian',
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              _cariController.clear();
                                              setState(() => _kataKunci = '');
                                            },
                                            child: const SizedBox(
                                              width: 48,
                                              height: 48,
                                              child: Center(
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  size: 18,
                                                  color: AppColors.inkSoft,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.kecil),
                              GestureDetector(
                                onTap: () => _bukaFilter(context),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isFilterAktif
                                            ? AppColors.stabilo
                                            : AppColors.kartu,
                                        border: Border.all(
                                          color: AppColors.ink,
                                          width: AppSizes.border,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusBadge,
                                        ),
                                        boxShadow: const [
                                          AppTheme.bayanganKecilGelap,
                                        ],
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
                                          width: 10,
                                          height: 10,
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
                          ),
                          if (state.daftarTransaksi.isNotEmpty ||
                              _adaFilterLokal ||
                              isFilterAktif) ...[
                            const SizedBox(height: AppSpacing.sedang),
                            Wrap(
                              spacing: AppSpacing.kecil,
                              runSpacing: AppSpacing.kecil,
                              children: [
                                _ChipFilterSumber(
                                  label: 'Semua',
                                  aktif: _filterSumber == _FilterSumber.semua,
                                  onTap: () => setState(
                                    () => _filterSumber = _FilterSumber.semua,
                                  ),
                                ),
                                _ChipFilterSumber(
                                  label: 'Dari struk',
                                  aktif: _filterSumber == _FilterSumber.struk,
                                  onTap: () => setState(
                                    () => _filterSumber = _FilterSumber.struk,
                                  ),
                                ),
                                _ChipFilterSumber(
                                  label: 'Manual',
                                  aktif: _filterSumber == _FilterSumber.manual,
                                  onTap: () => setState(
                                    () => _filterSumber = _FilterSumber.manual,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    Expanded(child: _bangunKonten(context, state)),
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

    if (state.status == RiwayatStatus.error && state.daftarTransaksi.isEmpty) {
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
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.salah,
                ),
                const SizedBox(height: AppSpacing.sedang),
                Text(
                  'Gagal Memuat Riwayat',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                  onPressed: () => context.read<RiwayatCubit>().muatRiwayat(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.daftarTransaksi.isEmpty) {
      return _bangunKeadaanKosong(
        context,
        state.isFilterAktif || _adaFilterLokal,
      );
    }

    return BlocBuilder<KategoriCubit, KategoriState>(
      builder: (context, katState) {
        final List<KategoriEntity> kategoriList = katState is KategoriLoaded
            ? katState.kategoriList
            : const [];
        final tersaring = _saringLokal(state.daftarTransaksi, kategoriList);

        if (tersaring.isEmpty) {
          return _bangunKeadaanKosong(context, true);
        }

        final listItems = _susunItemRiwayat(tersaring);

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
                padding: EdgeInsets.only(
                  top: index == 0 ? AppSpacing.sangatKecil : AppSpacing.besar,
                  bottom: AppSpacing.sangatKecil,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        RiwayatHelper.formatTanggalGrup(
                          item.tanggal,
                        ).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkSoft,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.kecil),
                    Text(
                      item.totalHarian.toRupiah(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkSoft,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              );
            }

            final trxItem = item as _TransaksiItem;
            final trx = trxItem.transaksi;
            final kat = RiwayatHelper.cariKategori(
              kategoriList,
              trx.kategoriId,
            );

            final namaKat = kat != null
                ? RiwayatHelper.kapitalPertama(kat.nama)
                : 'Lainnya';
            final ikonKat = RiwayatHelper.parseIkon(kat?.ikon);
            final warnaKat = RiwayatHelper.parseWarna(kat?.warna);

            final jam = RiwayatHelper.formatJam(trx.dibuatPada);
            final waktuTampil = trx.sumber == 'pindai' ? '$jam · Struk' : jam;

            return Dismissible(
              key: Key('transaksi_${trx.id}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) => _konfirmasiHapus(context),
              onDismissed: (direction) => _hapusTransaksi(context, trx),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.besar),
                decoration: BoxDecoration(
                  color: AppColors.salahLatar,
                  borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
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
                  final hasil = await context.push<dynamic>(
                    '/transaksi/${trx.id}',
                  );
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
                                context.read<BerandaCubit>().muatRingkasan();
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
            );
          },
        );
      },
    );
  }

  Widget _bangunKeadaanKosong(BuildContext context, bool isFilterAktif) {
    if (isFilterAktif) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.besar),
          child: KartuBukuTulis(
            shadow: AppTheme.bayanganGelap,
            pressedShadow: AppTheme.bayanganGelapTertekan,
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                  onPressed: () {
                    _cariController.clear();
                    setState(() {
                      _kataKunci = '';
                      _filterSumber = _FilterSumber.semua;
                    });
                    context.read<RiwayatCubit>().resetFilter();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.besar,
        AppSpacing.besar,
        AppSpacing.besar,
        AppSpacing.jarakGulirBawah,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MaskotStruki(
                      pose: PoseMaskot.catat,
                      ukuran: AppSizes.ukuranMaskotKosong,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada catatan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Catat belanja pertamamu, atau pindai struk biar Struki yang mengetik.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        color: AppColors.ink,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sedang),
          Semantics(
            button: true,
            label: 'Catat manual',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.go('/catat'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Container(
                  height: AppSizes.tinggiTombol,
                  decoration: BoxDecoration(
                    color: AppColors.kartu,
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppSizes.border,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                    boxShadow: const [AppTheme.bayanganTombolGelap],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        color: AppColors.ink,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.kecil),
                      Text(
                        'Catat manual',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipFilterSumber extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  const _ChipFilterSumber({
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: aktif,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            widthFactor: 1.0,
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: aktif ? AppColors.ink : AppColors.kartu,
                border: Border.all(color: AppColors.ink, width: AppSizes.border),
                borderRadius: BorderRadius.circular(AppSizes.radiusPil),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: aktif ? AppColors.kartu : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

sealed class _ItemRiwayat {}

class _HeaderTanggalItem extends _ItemRiwayat {
  final String tanggal;
  final int totalHarian;
  _HeaderTanggalItem(this.tanggal, this.totalHarian);
}

class _TransaksiItem extends _ItemRiwayat {
  final TransaksiEntity transaksi;
  _TransaksiItem(this.transaksi);
}
