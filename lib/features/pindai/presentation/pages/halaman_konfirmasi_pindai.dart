import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
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

/// Layar konfirmasi multi-barang pemindaian struk belanja bergaya Buku Tulis (F-10, Tahap 2C).
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

  void _tampilkanDialogSuntingToko(BuildContext context, String namaSekarang) {
    final controller = TextEditingController(text: namaSekarang);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
    final controller = TextEditingController(text: hargaSekarang.toString());
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sunting Harga'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(
              labelText: 'Harga (Rupiah)',
              hintText: 'Contoh: 15000 atau -5000',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Harga tidak boleh kosong';
              }
              if (int.tryParse(val.trim()) == null) {
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
                final harga = int.parse(controller.text.trim());
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
  ) {
    final katState = context.read<KategoriCubit>().state;
    final List<KategoriEntity> kategoriList =
        katState is KategoriLoaded ? katState.kategoriList : [];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sedang),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.besar,
                vertical: AppSpacing.kecil,
              ),
              child: Text(
                'Pilih Kategori',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
              ),
            ),
            const Divider(),
            ...kategoriList.map((k) {
              final warna = parseWarnaKategori(k.warna);
              final ikon = parseIkonKategori(k.ikon);
              final terpilih = k.id == kategoriSekarang;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: warna,
                  child: Icon(ikon, color: Colors.white, size: 20),
                ),
                title: Text(
                  kapitalPertama(k.nama),
                  style: TextStyle(
                    fontWeight: terpilih ? FontWeight.w800 : FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                trailing: terpilih
                    ? const Icon(Icons.check, color: AppColors.ink)
                    : null,
                onTap: () {
                  if (k.id != null) {
                    context
                        .read<KonfirmasiPindaiCubit>()
                        .ubahKategori(itemIndex, k.id!);
                  }
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
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

          context.read<PindaiCubit>().reset();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            try {
              context.pop();
            } catch (_) {}
          }
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
                        padding: const EdgeInsets.only(
                          left: AppSpacing.besar,
                          top: AppSpacing.besar,
                          right: AppSpacing.besar,
                          bottom: AppSpacing.sedang,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                context.read<PindaiCubit>().reset();
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  try {
                                    context.pop();
                                  } catch (_) {}
                                }
                              },
                              child: Container(
                                width: AppSizes.kotakIkonAksi,
                                height: AppSizes.kotakIkonAksi,
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  border: Border.all(
                                    color: AppColors.ink,
                                    width: AppSizes.border,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusKotakIkonAksi,
                                  ),
                                  boxShadow: const [
                                    AppTheme.bayanganKecilGelap
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.ink,
                                  size: AppSizes.ikonAksi,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sedang),
                            Expanded(
                              child: Text(
                                'Konfirmasi Hasil Pindai',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Konten Gulir
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.besar),
                          children: [
                            // Kartu Ringkasan Atas
                            KartuBukuTulis(
                              backgroundColor: AppColors.paper,
                              padding: const EdgeInsets.all(AppSpacing.sedang),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Baris Toko & Tanggal
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () =>
                                              _tampilkanDialogSuntingToko(
                                            context,
                                            state.namaToko,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.store_rounded,
                                                size: 20,
                                                color: AppColors.ink,
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.kecil),
                                              Expanded(
                                                child: Text(
                                                  state.namaToko.isEmpty
                                                      ? 'Nama Toko (ketuk)'
                                                      : state.namaToko,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.ink,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.edit,
                                                size: 14,
                                                color: AppColors.inkSoft,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sedang),
                                      InkWell(
                                        onTap: () => _pilihTanggal(
                                          context,
                                          state.tanggal,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              size: 18,
                                              color: AppColors.ink,
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.kecil),
                                            Text(
                                              state.tanggal,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.mini),
                                            const Icon(
                                              Icons.edit,
                                              size: 14,
                                              color: AppColors.inkSoft,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: AppSpacing.besar),

                                  // Baris Total Struk vs Dipilih
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total struk',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColors.inkSoft,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            Text(
                                              formatRupiah(state.totalStruk),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.inkSoft,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Dipilih',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColors.ink,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            Text(
                                              formatRupiah(state.totalDipilih),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.ink,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Peringatan Keyakinan Rendah (< 0.5)
                                  if (state.keyakinan < 0.5) ...[
                                    const SizedBox(height: AppSpacing.sedang),
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.kecil,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusKotakIkonAksi,
                                        ),
                                        border: Border.all(
                                          color: Colors.amber.shade800,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 18,
                                            color: Colors.amber.shade900,
                                          ),
                                          const SizedBox(
                                              width: AppSpacing.kecil),
                                          Expanded(
                                            child: Text(
                                              'Hasil bacaan kurang yakin, mohon periksa.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.amber.shade900,
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
                                      padding: const EdgeInsets.all(
                                        AppSpacing.kecil,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusKotakIkonAksi,
                                        ),
                                        border: Border.all(
                                          color: Colors.blue.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 18,
                                            color: Colors.blue.shade800,
                                          ),
                                          const SizedBox(
                                              width: AppSpacing.kecil),
                                          Expanded(
                                            child: Text(
                                              'Total nominal dihitung dari penjumlahan rincian barang.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

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
                                    child: KartuBukuTulis(
                                      backgroundColor: AppColors.paper,
                                      padding:
                                          const EdgeInsets.all(AppSpacing.sedang),
                                      child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header Kelompok Kategori
                                        Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: warnaKat,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                ikonKat,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.sedang),
                                            Expanded(
                                              child: Text(
                                                kapitalPertama(namaKat),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors.ink,
                                                    ),
                                              ),
                                            ),
                                            Text(
                                              formatRupiah(kelompok.subtotal),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: kelompok.adaGalat
                                                    ? Colors.red
                                                    : AppColors.ink,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Indikator Galat Subtotal <= 0
                                        if (kelompok.adaGalat) ...[
                                          const SizedBox(
                                              height: AppSpacing.kecil),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sedang,
                                              vertical: AppSpacing.mini,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.red.shade300,
                                              ),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(
                                                    width: AppSpacing.kecil),
                                                Expanded(
                                                  child: Text(
                                                    'Subtotal kelompok harus lebih dari 0',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        // Pilihan Butuh / Pengen untuk kelompok Opsional & Hiburan
                                        if (perluTanyaNiat) ...[
                                          const SizedBox(
                                              height: AppSpacing.sedang),
                                          Row(
                                            children: [
                                              const Text(
                                                'Kebutuhan: ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.inkSoft,
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.kecil),
                                              ChoiceChip(
                                                label: const Text('Butuh'),
                                                selected: state.tipeKebutuhan[
                                                        kelompok.kategoriId] ==
                                                    'butuh',
                                                onSelected: (selected) {
                                                  cubit.ubahTipeKebutuhan(
                                                    kelompok.kategoriId,
                                                    selected ? 'butuh' : null,
                                                  );
                                                },
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.kecil),
                                              ChoiceChip(
                                                label: const Text('Pengen'),
                                                selected: state.tipeKebutuhan[
                                                        kelompok.kategoriId] ==
                                                    'pengen',
                                                onSelected: (selected) {
                                                  cubit.ubahTipeKebutuhan(
                                                    kelompok.kategoriId,
                                                    selected ? 'pengen' : null,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],

                                        const Divider(height: AppSpacing.besar),

                                        // Daftar Barang di Kelompok Ini
                                        for (final barang in kelompok.items) ...[
                                          Builder(
                                            builder: (context) {
                                              final itemGlobalIndex = state
                                                  .daftarBarang
                                                  .indexOf(barang);

                                              // Periksa batas 10 baris
                                              if (!state.tampilkanSemua &&
                                                  hitunganBarisTampil >=
                                                      batasTampil) {
                                                return const SizedBox();
                                              }
                                              hitunganBarisTampil++;

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: AppSpacing.mini,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Checkbox(
                                                      value: barang.dicentang,
                                                      activeColor:
                                                          AppColors.ink,
                                                      onChanged: (val) {
                                                        cubit.centang(
                                                          itemGlobalIndex,
                                                          val ?? false,
                                                        );
                                                      },
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            barang.nama,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  barang.dicentang
                                                                      ? FontWeight
                                                                          .w700
                                                                      : FontWeight
                                                                          .w500,
                                                              color: barang
                                                                      .dicentang
                                                                  ? AppColors
                                                                      .ink
                                                                  : AppColors
                                                                      .inkSoft,
                                                              fontStyle: barang
                                                                      .adalahSelisih
                                                                  ? FontStyle
                                                                      .italic
                                                                  : FontStyle
                                                                      .normal,
                                                            ),
                                                          ),
                                                          InkWell(
                                                            onTap: () =>
                                                                _tampilkanSheetGantiKategori(
                                                              context,
                                                              itemGlobalIndex,
                                                              barang
                                                                  .kategoriId,
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  namaKat,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: AppColors
                                                                        .inkSoft,
                                                                    decoration:
                                                                        TextDecoration
                                                                            .underline,
                                                                  ),
                                                                ),
                                                                const Icon(
                                                                  Icons
                                                                      .arrow_drop_down,
                                                                  size: 16,
                                                                  color: AppColors
                                                                      .inkSoft,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            AppSpacing.sedang),
                                                    InkWell(
                                                      onTap: () =>
                                                          _tampilkanDialogSuntingHarga(
                                                        context,
                                                        itemGlobalIndex,
                                                        barang.harga,
                                                      ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal:
                                                              AppSpacing.kecil,
                                                          vertical:
                                                              AppSpacing.mini,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              AppColors.grid,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          border: Border.all(
                                                            color: AppColors
                                                                .inkSoft,
                                                            width: 0.5,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          formatRupiah(
                                                              barang.harga),
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800,
                                                            color:
                                                                AppColors.ink,
                                                            decoration:
                                                                barang.dicentang
                                                                    ? null
                                                                    : TextDecoration
                                                                        .lineThrough,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ],
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

                      // Tombol Bawah Tetap Terlihat
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.besar),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          border: const Border(
                            top: BorderSide(
                              color: AppColors.ink,
                              width: AppSizes.border,
                            ),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.garis,
                              offset: Offset(0, -2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TombolStabilo(
                              teks:
                                  'Simpan semua (${state.jumlahTransaksiAktif} transaksi)',
                              ikon: Icons.check_circle_outline_rounded,
                              isLoading: state.status ==
                                  KonfirmasiPindaiStatus.menyimpan,
                              onPressed:
                                  state.bolehSimpan ? cubit.simpanSemua : null,
                            ),
                            const SizedBox(height: AppSpacing.sedang),
                            TextButton(
                              onPressed: () {
                                context.read<PindaiCubit>().reset();
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  try {
                                    context.pop();
                                  } catch (_) {}
                                }
                              },
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
