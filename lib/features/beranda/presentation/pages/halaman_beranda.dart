import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../akun/domain/entities/pengguna_entity.dart';
import '../../../akun/domain/repositories/akun_repository.dart';
import '../../../../core/utils/iso_week.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../kategori/domain/entities/kategori_entity.dart';
import '../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../kategori/presentation/cubit/kategori_state.dart';
import '../../../transaksi/domain/entities/rincian_pengeluaran_entity.dart';
import '../../../transaksi/domain/entities/ringkasan_pekan_entity.dart';
import '../../../transaksi/domain/entities/transaksi_entity.dart';
import '../../../transaksi/presentation/widgets/kartu_transaksi.dart';
import '../cubit/beranda_cubit.dart';
import '../cubit/beranda_state.dart';
import '../widgets/kartu_rincian_pengeluaran.dart';
import '../widgets/tampilan_kategori.dart';

class HalamanBeranda extends StatelessWidget {
  final Stream<PenggunaEntity?>? streamPengguna;
  final PenggunaEntity? penggunaAwal;

  const HalamanBeranda({super.key, this.streamPengguna, this.penggunaAwal});

  static String ambilNamaDepan(String? namaTampilan) {
    if (namaTampilan == null) return 'Kawan';
    final bersih = namaTampilan.trim();
    if (bersih.isEmpty) return 'Kawan';
    final bagian = bersih.split(RegExp(r'\s+'));
    return bagian.isNotEmpty && bagian.first.isNotEmpty
        ? bagian.first
        : 'Kawan';
  }

  Stream<PenggunaEntity?>? _dapatkanStreamPengguna() {
    if (streamPengguna != null) return streamPengguna;
    if (sl.isRegistered<AkunRepository>()) {
      try {
        return sl<AkunRepository>().pantauPengguna();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PenggunaEntity?>(
      initialData: penggunaAwal,
      stream: _dapatkanStreamPengguna(),
      builder: (context, authSnapshot) {
        final pengguna = authSnapshot.hasError
            ? penggunaAwal
            : (authSnapshot.data ?? penggunaAwal);
        return Scaffold(
          body: PaperBackground(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.batasLebarKonten,
                ),
                child: BlocBuilder<BerandaCubit, BerandaState>(
                  builder: (context, state) {
                    if (state is BerandaLoading || state is BerandaInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.ink,
                          ),
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
                      return _BerandaContent(
                        ringkasan: state.ringkasan,
                        rincian: state.rincian,
                        pengguna: pengguna,
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BerandaContent extends StatelessWidget {
  final RingkasanPekanEntity ringkasan;
  final RincianPengeluaranEntity rincian;
  final PenggunaEntity? pengguna;

  const _BerandaContent({
    required this.ringkasan,
    required this.rincian,
    this.pengguna,
  });

  Widget _buildGreetingHeader(BuildContext context, String teksRentang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Halo, ${HalamanBeranda.ambilNamaDepan(pengguna?.namaTampilan)}!',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
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
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.kecil),
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
                  border: Border.all(color: AppColors.ink, width: 1.0),
                ),
              ),
              const SizedBox(width: AppSpacing.sangatKecil),
              Text(
                teksRentang,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBerandaKosong(BuildContext context, String teksRentang) {
    return ListView(
      padding: const EdgeInsets.only(
        left: AppSpacing.besar,
        top: AppSpacing.besar,
        right: AppSpacing.besar,
        bottom: AppSpacing.jarakGulirBawah,
      ),
      children: [
        _buildGreetingHeader(context, teksRentang),
        const SizedBox(height: AppSpacing.besar),

        // Kartu Mini Kas Pekan Ini (sesuai mockup layar 5)
        KartuBukuTulis(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sedang,
            vertical: AppSpacing.agakKecil,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: AppSpacing.agakKecil),
                  Text(
                    'Buku Kas Pekan Ini:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                  ),
                ],
              ),
              Text(
                'Rp0',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.besar),

        // Area Utama Empty State
        KartuBukuTulis(
          padding: const EdgeInsets.all(AppSpacing.besar),
          child: Column(
            children: [
              // Ilustrasi Notebook & Pensil tema Buku Tulis
              Container(
                width: 140,
                height: 100,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sedang),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.border,
                  ),
                  boxShadow: const [AppTheme.bayanganDefault],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 20,
                      right: 20,
                      child: Column(
                        children: [
                          Container(height: 2, color: AppColors.grid),
                          const SizedBox(height: 8),
                          Container(height: 2, color: AppColors.grid),
                          const SizedBox(height: 8),
                          Container(height: 2, color: AppColors.grid),
                          const SizedBox(height: 8),
                          Container(height: 2, color: AppColors.grid),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.stabilo,
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 42,
                          color: AppColors.ink,
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.edit,
                          size: 32,
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.agakKecil),

              Text(
                'Belum Ada Pengeluaran yang Dicatat',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
              ),
              const SizedBox(height: AppSpacing.agakKecil),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sedang),
                child: Text(
                  'Mulai langkah pertamamu menyadari alur uang dengan mencatat pengeluaran jajan hari ini.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.besar),

              TombolStabilo(
                key: const Key('tombol_catat_pertama'),
                teks: 'Catat pengeluaran pertama',
                ikon: Icons.edit_square,
                onPressed: () => context.go('/catat'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.besar),

        // Banner Tips Cepat
        KartuBukuTulis(
          padding: const EdgeInsets.all(AppSpacing.sedang),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.stabilo,
                  borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonAksi),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.borderTipis,
                  ),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.agakKecil),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips Cepat',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cukup catat nominal dan tentukan apakah butuh atau pengen. Nggak sampai 10 detik!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkSoft,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rentangPekan = rentangMingguIso(DateTime.now());
    final teksRentang = formatRentangMinggu(rentangPekan);

    final bool tabelTransaksiKosong = ringkasan.transaksiTerakhir.isEmpty &&
        ringkasan.totalMingguIni == 0 &&
        ringkasan.totalMingguLalu == 0 &&
        rincian.totalBulanIni == 0;

    if (tabelTransaksiKosong) {
      return _buildBerandaKosong(context, teksRentang);
    }

    return ListView(
      padding: const EdgeInsets.only(
        left: AppSpacing.besar,
        top: AppSpacing.besar,
        right: AppSpacing.besar,
        bottom: AppSpacing.jarakGulirBawah,
      ),
      children: [
        _buildGreetingHeader(context, teksRentang),
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
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: AppSizes.ikonKalender,
                          color: AppColors.ink,
                        ),
                        const SizedBox(width: AppSpacing.agakKecil),
                        Flexible(
                          child: Text(
                            'PENGELUARAN PEKAN INI',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
              _IndikatorSelisih(
                selisih: ringkasan.selisihMingguan,
                totalMingguLalu: ringkasan.totalMingguLalu,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.besar),
        // Tombol Aksi Cepat (Catat Cepat & Pindai Struk)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusKotakIkonAksi,
                          ),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusKotakIkonAksi,
                              ),
                              boxShadow: const [AppTheme.bayanganKecilGelap],
                            ),
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              size: AppSizes.ikonAksi,
                              color: AppColors.ink,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.agakKecil,
                              vertical: AppSpacing.mini,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.stabilo,
                              border: Border.all(
                                color: AppColors.ink,
                                width: AppSizes.borderTipis,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLabel,
                              ),
                            ),
                            child: Text(
                              'AI',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sedang),
                      Text(
                        'Pindai Struk',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                      const SizedBox(height: AppSpacing.kecil),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: AppSizes.tinggiBarKuotaPindai,
                              decoration: BoxDecoration(
                                color: AppColors.grid,
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: AppSizes.borderTipis,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusBarKuotaPindai,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusBarKuotaPindai,
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: ringkasan.kuotaPindai <= 0
                                      ? 0.0
                                      : (ringkasan.kuotaPindai / 10).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                  child: Container(color: AppColors.stabilo),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.agakKecil),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                ringkasan.kuotaPindai <= 0
                                    ? 'Habis, reset Senin'
                                    : '${ringkasan.kuotaPindai}/10',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontSize: ringkasan.kuotaPindai <= 0
                                          ? AppSizes.ukuranTeksStatusKuota
                                          : null,
                                      color: ringkasan.kuotaPindai <= 0
                                          ? AppColors.inkSoft
                                          : AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.besar),
        // Kartu Rincian Pengeluaran
        KartuRincianPengeluaran(
          totalPekanIni: ringkasan.totalMingguIni,
          rincian: rincian,
        ),
        const SizedBox(height: AppSpacing.lebihBesar),
        // Recent Transactions Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Catatan Terakhir',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
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
            ),
            const SizedBox(width: AppSpacing.kecil),
            GestureDetector(
              onTap: () => context.go('/riwayat'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sangatKecil),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: AppSizes.ikonKecil,
                    color: AppColors.ink,
                  ),
                ],
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
          ...ringkasan.transaksiTerakhir.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sedang),
              child: _ItemTransaksi(transaksi: t),
            ),
          ),
      ],
    );
  }
}

class _IndikatorSelisih extends StatelessWidget {
  final int selisih;
  final int totalMingguLalu;

  const _IndikatorSelisih({
    required this.selisih,
    required this.totalMingguLalu,
  });

  @override
  Widget build(BuildContext context) {
    if (totalMingguLalu == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: AppSizes.tinggiGarisPemisah,
            color: AppColors.garis,
          ),
          const SizedBox(height: AppSpacing.sedang),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sedang,
                vertical: AppSpacing.sangatKecil,
              ),
              decoration: BoxDecoration(
                color: AppColors.grid,
                border: Border.all(color: AppColors.ink, width: 1.0),
                borderRadius: BorderRadius.circular(AppSizes.radiusPil),
              ),
              child: Text(
                'Belum ada data pekan lalu',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
        Container(height: AppSizes.tinggiGarisPemisah, color: AppColors.garis),
        const SizedBox(height: AppSpacing.sedang),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ikon,
                        size: AppSizes.ikonSelisih,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: AppSpacing.sangatKecil),
                      Flexible(
                        child: Text(
                          selisih == 0
                              ? 'Sama persis dengan pekan lalu'
                              : '$nominalAbsolut $teksStatus dibanding pekan lalu',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sedang),
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
            ? kapitalPertama(kategori.nama)
            : 'Tidak diketahui';
        final ikon = kategori != null
            ? parseIkonKategori(kategori.ikon)
            : Icons.help;
        final warna = kategori != null
            ? parseWarnaKategori(kategori.warna)
            : AppColors.inkSoft;

        String waktu = '';
        try {
          final dt = DateTime.parse(transaksi.dibuatPada).toLocal();
          final jam = dt.hour.toString().padLeft(2, '0');
          final menit = dt.minute.toString().padLeft(2, '0');
          // jam saja, samain sama riwayat_helper (ISSUE-16)
          waktu = '$jam:$menit';
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
