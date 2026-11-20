import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/header_aplikasi.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../beranda/presentation/widgets/tampilan_kategori.dart';
import '../../../kategori/domain/entities/kategori_entity.dart';
import '../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../kategori/presentation/cubit/kategori_state.dart';
import '../../../transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';
import '../../domain/entities/hasil_pindai_entity.dart';
import '../../domain/usecases/simpan_transaksi_pindai.dart';
import '../cubit/konfirmasi_pindai_cubit.dart';
import '../cubit/konfirmasi_pindai_state.dart';
import '../cubit/pindai_cubit.dart';

/// Layar konfirmasi multi-barang pemindaian struk belanja (Insap 2.0).
class HalamanKonfirmasiPindai extends StatelessWidget {
  final HasilPindaiEntity hasilPindai;

  const HalamanKonfirmasiPindai({
    super.key,
    required this.hasilPindai,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KonfirmasiPindaiCubit(
        simpanTransaksiPindai: GetIt.I<SimpanTransaksiPindai>(),
        hasilPindai: hasilPindai,
      ),
      child: const _KonfirmasiPindaiView(),
    );
  }
}

class _KonfirmasiPindaiView extends StatelessWidget {
  const _KonfirmasiPindaiView();

  static const Set<String> _kelompokTanyaNiat = {'opsional', 'hiburan'};

  void _kembaliDanBuangDraf(BuildContext context) {
    try {
      context.read<PindaiCubit>().reset();
    } catch (_) {}
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.pop();
      } catch (_) {}
    }
  }

  void _tampilkanDialogSuntingToko(BuildContext context, String namaSekarang) {
    final controller = TextEditingController(text: namaSekarang);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kartu,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
          side: const BorderSide(color: AppColors.ink, width: AppSizes.border),
        ),
        title: const Text('Sunting Nama Toko'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nama Toko',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<KonfirmasiPindaiCubit>().ubahNamaToko(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _tampilkanDialogSuntingHarga(
    BuildContext context,
    int index,
    int hargaSekarang,
  ) {
    final String initialText = hargaSekarang < 0
        ? '-${formatRupiah(hargaSekarang.abs()).replaceFirst('Rp', '')}'
        : (hargaSekarang > 0
            ? formatRupiah(hargaSekarang).replaceFirst('Rp', '')
            : '0');
    final controller = TextEditingController(text: initialText);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kartu,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
          side: const BorderSide(color: AppColors.ink, width: AppSizes.border),
        ),
        title: const Text('Sunting Harga'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(
              labelText: 'Harga (Rupiah)',
              hintText: 'Contoh: 15.000 atau -5.000',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onChanged: (val) {
              final isNegative = val.trim().startsWith('-');
              final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
              final angka = int.tryParse(cleaned);
              if (angka != null && angka > 0) {
                final formatted = formatRupiah(angka).replaceFirst('Rp', '');
                final result = isNegative ? '-$formatted' : formatted;
                controller.value = TextEditingValue(
                  text: result,
                  selection: TextSelection.collapsed(offset: result.length),
                );
              } else if (isNegative) {
                controller.value = const TextEditingValue(
                  text: '-',
                  selection: TextSelection.collapsed(offset: 1),
                );
              } else {
                controller.value = const TextEditingValue(
                  text: '',
                  selection: TextSelection.collapsed(offset: 0),
                );
              }
            },
            validator: (val) {
              if (val == null || val.trim().isEmpty || val.trim() == '-') {
                return 'Harga tidak boleh kosong';
              }
              final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
              if (int.tryParse(cleaned) == null) {
                return 'Masukkan angka bulat valid';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final isNegative = controller.text.trim().startsWith('-');
                final cleaned =
                    controller.text.replaceAll(RegExp(r'[^0-9]'), '');
                final angka = int.tryParse(cleaned) ?? 0;
                final harga = isNegative ? -angka : angka;
                context
                    .read<KonfirmasiPindaiCubit>()
                    .ubahHarga(index, harga);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _tampilkanSheetGantiKategori(
    BuildContext context,
    int itemIndex,
    int kategoriSekarang,
    String namaBarang,
    int hargaBarang,
  ) {
    final katState = context.read<KategoriCubit>().state;
    final List<KategoriEntity> kategoriList =
        katState is KategoriLoaded ? katState.kategoriList : [];
    final konfirmasiCubit = context.read<KonfirmasiPindaiCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.78,
          ),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(
              top: BorderSide(color: AppColors.ink, width: AppSizes.border),
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.garisPutus,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              Text(
                'Pindahkan ke kategori',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '$namaBarang · ${formatRupiah(hargaBarang)}',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: kategoriList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (_, idx) {
                    final k = kategoriList[idx];
                    final warna = parseWarnaKategori(k.warna);
                    final ikon = parseIkonKategori(k.ikon);
                    final terpilih = k.id == kategoriSekarang;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (k.id != null) {
                          konfirmasiCubit.ubahKategori(itemIndex, k.id!);
                        }
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: terpilih
                              ? AppColors.kuningMuda
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: terpilih ? AppColors.ink : Colors.transparent,
                            width: AppSizes.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: warna,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: AppSizes.border,
                                ),
                              ),
                              child: Icon(
                                ikon,
                                color: AppColors.ikonBadge,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                kapitalPertama(k.nama),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            if (terpilih)
                              const Icon(
                                Icons.check_rounded,
                                size: 20,
                                color: AppColors.ink,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pilihTanggal(
    BuildContext context,
    String tanggalSekarang,
  ) async {
    final awal = DateTime.tryParse(tanggalSekarang) ?? DateTime.now();
    final hasil = await showDatePicker(
      context: context,
      initialDate: awal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (hasil != null && context.mounted) {
      final tglStr = hasil.toIso8601String().substring(0, 10);
      context.read<KonfirmasiPindaiCubit>().ubahTanggal(tglStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KonfirmasiPindaiCubit, KonfirmasiPindaiState>(
      listener: (context, state) {
        if (state.status == KonfirmasiPindaiStatus.sukses) {
          try {
            context.read<BerandaCubit>().muatRingkasan();
          } catch (_) {}
          try {
            context.read<RiwayatCubit>().muatRiwayat();
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${state.jumlahTransaksiTersimpan} transaksi tersimpan',
              ),
            ),
          );

          _kembaliDanBuangDraf(context);
        } else if (state.status == KonfirmasiPindaiStatus.gagal &&
            state.pesanGalat != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.pesanGalat!)),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<KonfirmasiPindaiCubit>();
        final katState = context.watch<KategoriCubit>().state;
        final List<KategoriEntity> kategoriList =
            katState is KategoriLoaded ? katState.kategoriList : [];

        KategoriEntity? cariKategori(int id) {
          try {
            return kategoriList.firstWhere((k) => k.id == id);
          } catch (_) {
            return null;
          }
        }

        // Hitung batas 10 baris pertama
        int hitunganBarisTampil = 0;
        const int batasTampil = 10;
        final bool butuhTombolLihatSemua =
            !state.tampilkanSemua && state.daftarBarang.length > batasTampil;

        return Scaffold(
          appBar: HeaderAplikasi(
            namaLayar: 'Periksa hasil',
            modeKembali: true,
            onKembali: () => _kembaliDanBuangDraf(context),
          ),
          body: PaperBackground(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.batasLebarKonten,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.besar),
                        children: [
                          // Kepala struk + chip Dikelompokkan AI
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () => _tampilkanDialogSuntingToko(
                                        context,
                                        state.namaToko,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              state.namaToko.isEmpty
                                                  ? 'Nama Toko (ketuk)'
                                                  : state.namaToko,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.ink,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.edit_outlined,
                                            size: 15,
                                            color: AppColors.inkSoft,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    InkWell(
                                      onTap: () => _pilihTanggal(
                                        context,
                                        state.tanggal,
                                      ),
                                      child: Text(
                                        '${state.tanggal} · ${state.daftarBarang.length} barang',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 13,
                                              color: AppColors.inkSoft,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.kecil),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.hijauMuda,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusPil,
                                  ),
                                  border: Border.all(
                                    color: AppColors.daunTua,
                                    width: AppSizes.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 14,
                                      color: AppColors.daunTua,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Dikelompokkan AI',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontSize: 12,
                                            letterSpacing: 0,
                                            color: AppColors.daunTua,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ketuk kategori untuk memindah barang. Hapus centang barang yang bukan milikmu.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),

                          // Peringatan Keyakinan Rendah (< 0.5)
                          if (state.keyakinan < 0.5) ...[
                            const SizedBox(height: AppSpacing.sedang),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.kecil),
                              decoration: BoxDecoration(
                                color: AppColors.kuningMuda,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusKotakIkonAksi,
                                ),
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: AppSizes.borderTipis,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 18,
                                    color: AppColors.ink,
                                  ),
                                  SizedBox(width: AppSpacing.kecil),
                                  Expanded(
                                    child: Text(
                                      'Hasil bacaan kurang yakin, mohon periksa.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Peringatan Total Null
                          if (state.totalDihitungDariBarang) ...[
                            const SizedBox(height: AppSpacing.kecil),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.kecil),
                              decoration: BoxDecoration(
                                color: AppColors.hijauMuda,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusKotakIkonAksi,
                                ),
                                border: Border.all(
                                  color: AppColors.daunTua,
                                  width: AppSizes.borderTipis,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppColors.daunTua,
                                  ),
                                  SizedBox(width: AppSpacing.kecil),
                                  Expanded(
                                    child: Text(
                                      'Total nominal dihitung dari penjumlahan rincian barang.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.daunTua,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.besar),

                          // Daftar Kelompok Per Kategori
                          for (final kelompok in state.kelompokList) ...[
                            Builder(
                              builder: (context) {
                                final kat = cariKategori(kelompok.kategoriId);
                                final namaKat =
                                    kat != null ? kat.nama : 'Lainnya';
                                final warnaKat = kat != null
                                    ? parseWarnaKategori(kat.warna)
                                    : AppColors.inkSoft;
                                final ikonKat = kat != null
                                    ? parseIkonKategori(kat.ikon)
                                    : Icons.more_horiz;
                                final bool perluTanyaNiat = kat != null &&
                                    _kelompokTanyaNiat
                                        .contains(kat.kelompokKakeibo);

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.besar,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.kartu,
                                      border: Border.all(
                                        color: AppColors.ink,
                                        width: AppSizes.border,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusKartu,
                                      ),
                                      boxShadow: const [AppTheme.bayanganGelap],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusKartu - AppSizes.border,
                                      ),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Container(
                                              width: 6,
                                              color: warnaKat,
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Header Kelompok Kategori
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          ikonKat,
                                                          color: warnaKat,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            kapitalPertama(
                                                              namaKat,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color:
                                                                  AppColors.ink,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          formatRupiah(
                                                            kelompok.subtotal,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color:
                                                                kelompok.adaGalat
                                                                    ? AppColors
                                                                        .merahTeks
                                                                    : AppColors
                                                                        .ink,
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Indikator Galat Subtotal <= 0
                                                    if (kelompok.adaGalat) ...[
                                                      const SizedBox(
                                                        height: AppSpacing.kecil,
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal:
                                                              AppSpacing.sedang,
                                                          vertical:
                                                              AppSpacing.mini,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .salahLatar,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                            color:
                                                                AppColors.salah,
                                                          ),
                                                        ),
                                                        child: const Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .error_outline_rounded,
                                                              size: 16,
                                                              color: AppColors
                                                                  .merahTeks,
                                                            ),
                                                            SizedBox(
                                                              width: AppSpacing
                                                                  .kecil,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                'Subtotal kelompok harus lebih dari 0',
                                                                style:
                                                                    TextStyle(
                                                                  color: AppColors
                                                                      .merahTeks,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],

                                                    // Pilihan Butuh / Pengen
                                                    if (perluTanyaNiat) ...[
                                                      const SizedBox(
                                                        height:
                                                            AppSpacing.sedang,
                                                      ),
                                                      Row(
                                                        children: [
                                                          const Text(
                                                            'Kebutuhan: ',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: AppColors
                                                                  .inkSoft,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: AppSpacing
                                                                .kecil,
                                                          ),
                                                          ChoiceChip(
                                                            label: const Text(
                                                              'Butuh',
                                                            ),
                                                            selectedColor:
                                                                AppColors
                                                                    .stabilo,
                                                            backgroundColor:
                                                                AppColors.kartu,
                                                            side:
                                                                const BorderSide(
                                                              color:
                                                                  AppColors.ink,
                                                            ),
                                                            selected:
                                                                state.tipeKebutuhan[
                                                                        kelompok
                                                                            .kategoriId] ==
                                                                    'butuh',
                                                            onSelected:
                                                                (selected) {
                                                              cubit
                                                                  .ubahTipeKebutuhan(
                                                                kelompok
                                                                    .kategoriId,
                                                                selected
                                                                    ? 'butuh'
                                                                    : null,
                                                              );
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            width: AppSpacing
                                                                .kecil,
                                                          ),
                                                          ChoiceChip(
                                                            label: const Text(
                                                              'Pengen',
                                                            ),
                                                            selectedColor:
                                                                AppColors
                                                                    .stabilo,
                                                            backgroundColor:
                                                                AppColors.kartu,
                                                            side:
                                                                const BorderSide(
                                                              color:
                                                                  AppColors.ink,
                                                            ),
                                                            selected:
                                                                state.tipeKebutuhan[
                                                                        kelompok
                                                                            .kategoriId] ==
                                                                    'pengen',
                                                            onSelected:
                                                                (selected) {
                                                              cubit
                                                                  .ubahTipeKebutuhan(
                                                                kelompok
                                                                    .kategoriId,
                                                                selected
                                                                    ? 'pengen'
                                                                    : null,
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ],

                                                    const SizedBox(height: 6),

                                                    // Daftar Barang di Kelompok Ini
                                                    for (final barang
                                                        in kelompok.items) ...[
                                                      Builder(
                                                        builder: (context) {
                                                          final itemGlobalIndex =
                                                              state.daftarBarang
                                                                  .indexOf(
                                                            barang,
                                                          );

                                                          if (!state
                                                                  .tampilkanSemua &&
                                                              hitunganBarisTampil >=
                                                                  batasTampil) {
                                                            return const SizedBox();
                                                          }
                                                          hitunganBarisTampil++;

                                                          return Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const _GarisPutus(),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  vertical: 8,
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    Checkbox(
                                                                      value: barang
                                                                          .dicentang,
                                                                      activeColor:
                                                                          AppColors
                                                                              .ink,
                                                                      checkColor:
                                                                          AppColors
                                                                              .kartu,
                                                                      side: const BorderSide(
                                                                        color: AppColors
                                                                            .ink,
                                                                        width: AppSizes
                                                                            .border,
                                                                      ),
                                                                      onChanged:
                                                                          (val) {
                                                                        cubit
                                                                            .centang(
                                                                          itemGlobalIndex,
                                                                          val ??
                                                                              false,
                                                                        );
                                                                      },
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment
                                                                                .start,
                                                                        children: [
                                                                          Text(
                                                                            barang
                                                                                .nama,
                                                                            maxLines:
                                                                                2,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 15,
                                                                              fontWeight: barang.dicentang ? FontWeight.w700 : FontWeight.w500,
                                                                              color: barang.dicentang ? AppColors.ink : AppColors.inkSoft,
                                                                              fontStyle: barang.adalahSelisih ? FontStyle.italic : FontStyle.normal,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                4,
                                                                          ),
                                                                          Semantics(
                                                                            button: true,
                                                                            label: 'Ubah kategori ${kapitalPertama(namaKat)} untuk ${barang.nama}',
                                                                            child: InkWell(
                                                                              borderRadius:
                                                                                  BorderRadius.circular(AppSizes.radiusPil),
                                                                              onTap: () => _tampilkanSheetGantiKategori(
                                                                                context,
                                                                                itemGlobalIndex,
                                                                                barang.kategoriId,
                                                                                barang.nama,
                                                                                barang.harga,
                                                                              ),
                                                                              child: ConstrainedBox(
                                                                                constraints: const BoxConstraints(
                                                                                  minWidth: 48,
                                                                                  minHeight: 48,
                                                                                ),
                                                                                child: Center(
                                                                                  widthFactor: 1.0,
                                                                                  child: Container(
                                                                                    padding: const EdgeInsets.symmetric(
                                                                                      horizontal: 10,
                                                                                      vertical: 4,
                                                                                    ),
                                                                                    decoration: BoxDecoration(
                                                                                      color: AppColors.kartu,
                                                                                      borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                                                                                      border: Border.all(
                                                                                        color: warnaKat,
                                                                                        width: 1.5,
                                                                                      ),
                                                                                    ),
                                                                                    child: Row(
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: [
                                                                                        Icon(
                                                                                          ikonKat,
                                                                                          size: 15,
                                                                                          color: warnaKat,
                                                                                        ),
                                                                                        const SizedBox(width: 5),
                                                                                        Text(
                                                                                          kapitalPertama(namaKat),
                                                                                          style: const TextStyle(
                                                                                            fontSize: 13,
                                                                                            fontWeight: FontWeight.w800,
                                                                                            color: AppColors.ink,
                                                                                          ),
                                                                                        ),
                                                                                        const SizedBox(width: 2),
                                                                                        const Icon(
                                                                                          Icons.keyboard_arrow_down_rounded,
                                                                                          size: 16,
                                                                                          color: AppColors.ink,
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: AppSpacing
                                                                          .sedang,
                                                                    ),
                                                                    Semantics(
                                                                      button: true,
                                                                      label: 'Sunting harga ${barang.nama}',
                                                                      child: InkWell(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                        onTap: () =>
                                                                            _tampilkanDialogSuntingHarga(
                                                                          context,
                                                                          itemGlobalIndex,
                                                                          barang
                                                                              .harga,
                                                                        ),
                                                                        child: ConstrainedBox(
                                                                          constraints: const BoxConstraints(
                                                                            minWidth: 48,
                                                                            minHeight: 48,
                                                                          ),
                                                                          child: Center(
                                                                            widthFactor: 1.0,
                                                                            child: Container(
                                                                              constraints:
                                                                                  const BoxConstraints(
                                                                                minHeight:
                                                                                    36,
                                                                              ),
                                                                              padding:
                                                                                  const EdgeInsets
                                                                                      .symmetric(
                                                                                horizontal:
                                                                                    10,
                                                                                vertical:
                                                                                    6,
                                                                              ),
                                                                              alignment:
                                                                                  Alignment
                                                                                      .center,
                                                                              decoration:
                                                                                  BoxDecoration(
                                                                                color:
                                                                                    AppColors.kartu,
                                                                                borderRadius:
                                                                                    BorderRadius.circular(
                                                                                  12,
                                                                                ),
                                                                                border:
                                                                                    Border.all(
                                                                                  color:
                                                                                      AppColors.ink,
                                                                                  width:
                                                                                      1.5,
                                                                                ),
                                                                              ),
                                                                              child:
                                                                                  Text(
                                                                                formatRupiah(
                                                                                  barang.harga,
                                                                                ),
                                                                                style:
                                                                                    TextStyle(
                                                                                  fontSize:
                                                                                      15,
                                                                                  fontWeight:
                                                                                      FontWeight.w700,
                                                                                  color:
                                                                                      AppColors.ink,
                                                                                  decoration:
                                                                                      barang.dicentang ? null : TextDecoration.lineThrough,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],

                          // Tombol "Lihat semua (N barang lagi)"
                          if (butuhTombolLihatSemua) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.besar,
                              ),
                              child: Center(
                                child: OutlinedButton.icon(
                                  onPressed: cubit.tampilkanSemuaBarang,
                                  icon: const Icon(
                                    Icons.visibility_rounded,
                                    color: AppColors.ink,
                                  ),
                                  label: Text(
                                    'Lihat semua (${state.daftarBarang.length - batasTampil} barang lagi)',
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.kartu,
                                    side: const BorderSide(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusTombol,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Ringkasan dan Tombol Simpan Bawah
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.besar,
                        AppSpacing.sedang,
                        AppSpacing.besar,
                        AppSpacing.besar,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.paper,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.ink,
                            width: AppSizes.border,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.kartu,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusKartu,
                                ),
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: AppSizes.border,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Jadi ${state.jumlahTransaksiAktif} catatan dari 1 struk',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.kecil),
                                  Text(
                                    formatRupiah(state.totalDipilih),
                                    style: AppTheme.nominalBesar.copyWith(
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sedang),
                            TombolStabilo(
                              teks:
                                  'Simpan ${state.jumlahTransaksiAktif} catatan',
                              ikon: Icons.check_circle_outline_rounded,
                              isLoading: state.status ==
                                  KonfirmasiPindaiStatus.menyimpan,
                              onPressed:
                                  state.bolehSimpan ? cubit.simpanSemua : null,
                            ),
                            const SizedBox(height: AppSpacing.sangatKecil),
                            TextButton(
                              onPressed: () => _kembaliDanBuangDraf(context),
                              child: const Text(
                                'Batal & Buang Draf',
                                style: TextStyle(
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GarisPutus extends StatelessWidget {
  const _GarisPutus();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1.5),
      painter: _GarisPutusPainter(),
    );
  }
}

class _GarisPutusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.garisPutus
      ..strokeWidth = 1.5;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
