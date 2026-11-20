import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/kuota_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/tur/langkah_tur.dart';
import '../../../../core/utils/iso_week.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/maskot_struki.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../akun/domain/entities/pengguna_entity.dart';
import '../../../akun/domain/repositories/akun_repository.dart';
import '../../../kategori/domain/entities/kategori_entity.dart';
import '../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../kategori/presentation/cubit/kategori_state.dart';
import '../../../pengaturan/domain/entities/perbandingan_target_entity.dart';
import '../../../pengaturan/domain/usecases/baca_status_panduan_pindai.dart';
import '../../../pindai/presentation/widgets/dialog_panduan_pindai.dart';
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
  final DateTime Function()? waktuSekarang;

  const HalamanBeranda({
    super.key,
    this.streamPengguna,
    this.penggunaAwal,
    this.waktuSekarang,
  });

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
                        perbandinganTarget: state.perbandinganTarget,
                        refleksiPekanIniTersimpan:
                            state.refleksiPekanIniTersimpan,
                        waktuSekarang: waktuSekarang,
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
  final PerbandinganTargetEntity? perbandinganTarget;
  final bool refleksiPekanIniTersimpan;
  final DateTime Function()? waktuSekarang;

  static const BoxShadow _bayanganStabilo = BoxShadow(
    color: AppColors.stabilo,
    offset: Offset(4, 4),
    blurRadius: 0,
  );

  static const BoxShadow _bayanganStabiloTertekan = BoxShadow(
    color: AppColors.stabilo,
    offset: Offset(2, 2),
    blurRadius: 0,
  );

  const _BerandaContent({
    required this.ringkasan,
    required this.rincian,
    this.pengguna,
    this.perbandinganTarget,
    this.refleksiPekanIniTersimpan = false,
    this.waktuSekarang,
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
                  const Icon(
                    Icons.waving_hand_rounded,
                    size: AppSizes.ikonAksi,
                    color: AppColors.ink,
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
            color: AppColors.kartu,
            border: Border.all(
              color: AppColors.ink,
              width: AppSizes.border,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusPil),
            boxShadow: const [AppTheme.bayanganKecilGelap],
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

        KartuBukuTulis(
          shadow: AppTheme.bayanganGelap,
          pressedShadow: AppTheme.bayanganGelapTertekan,
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

        KartuBukuTulis(
          shadow: AppTheme.bayanganGelap,
          pressedShadow: AppTheme.bayanganGelapTertekan,
          padding: const EdgeInsets.all(AppSpacing.besar),
          child: Column(
            children: [
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
                  boxShadow: const [AppTheme.bayanganGelap],
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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

        KartuBukuTulis(
          shadow: AppTheme.bayanganGelap,
          pressedShadow: AppTheme.bayanganGelapTertekan,
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

  Future<void> _bukaPindai(BuildContext context) async {
    final sembunyikan = await sl<BacaStatusPanduanPindai>().call();
    if (!context.mounted) return;
    if (!sembunyikan) {
      await tampilkanDialogPanduanPindai(
        context,
        onLanjut: () {
          if (context.mounted) {
            context.push('/pindai?mulai=1');
          }
        },
      );
    } else {
      context.push('/pindai?mulai=1');
    }
  }

  @override
  Widget build(BuildContext context) {
    final waktu = (waktuSekarang != null ? waktuSekarang!() : DateTime.now());
    final rentangPekan = rentangMingguIso(waktu);
    final teksRentang = formatRentangMinggu(rentangPekan);
    final bool akhirPekan =
        waktu.weekday == DateTime.saturday || waktu.weekday == DateTime.sunday;
    final bool tampilkanBannerRefleksi =
        akhirPekan && !refleksiPekanIniTersimpan;

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

        // 1. Kartu Ringkasan Pekan (Insap 2.0)
        _KartuRingkasanPekan(
          ringkasan: ringkasan,
          perbandinganTarget: perbandinganTarget,
        ),

        // 2. Banner Refleksi Hijau Muda dengan MaskotStruki detektif
        if (tampilkanBannerRefleksi) ...[
          const SizedBox(height: AppSpacing.sedang),
          KartuBukuTulis(
            key: const Key('banner_refleksi_beranda'),
            onTap: () => context.go('/refleksi'),
            backgroundColor: AppColors.hijauMuda,
            shadow: AppTheme.bayanganGelap,
            pressedShadow: AppTheme.bayanganGelapTertekan,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sedang,
              vertical: 10,
            ),
            radius: AppSizes.radiusKartu,
            child: Row(
              children: [
                const MaskotStruki(pose: PoseMaskot.detektif, ukuran: 76),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refleksi pekan ini siap',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pekan ini belum direfleksikan. Luangkan 2 menit, yuk.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13.5,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.kecil),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.ink,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sedang),

        // 3. Dua Kartu Berdampingan: Catat Cepat & Pindai Struk
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: KartuBukuTulis(
                  key: KunciTur.catatCepat,
                  onTap: () => context.go('/catat'),
                  backgroundColor: AppColors.stabilo,
                  shadow: AppTheme.bayanganGelap,
                  pressedShadow: AppTheme.bayanganGelapTertekan,
                  radius: AppSizes.radiusKartu,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
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
                        child: const Icon(
                          Icons.edit,
                          size: AppSizes.ikonAksi,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Catat Cepat',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.15,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.mini),
                      Text(
                        'Ketik manual',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.2,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sedang),
              Expanded(
                child: KartuBukuTulis(
                  key: KunciTur.pindaiStruk,
                  onTap: () => _bukaPindai(context),
                  backgroundColor: AppColors.ink,
                  shadow: _bayanganStabilo,
                  pressedShadow: _bayanganStabiloTertekan,
                  radius: AppSizes.radiusKartu,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.stabilo,
                              border: Border.all(
                                color: AppColors.ink,
                                width: AppSizes.border,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusBadge,
                              ),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: AppSizes.ikonAksi,
                              color: AppColors.ink,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.kecil,
                              vertical: AppSpacing.mini,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.stabilo,
                              border: Border.all(
                                color: AppColors.stabilo,
                                width: AppSizes.border,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusKotakIkonAksi,
                              ),
                            ),
                            child: Text(
                              'AI',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    letterSpacing: 0.6,
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pindai Struk',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.kartu,
                              height: 1.15,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.mini),
                      Text(
                        'Foto struk, AI yang isi',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.2,
                          color: AppColors.putihRedup,
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
                                color: AppColors.inkSoft,
                                border: Border.all(
                                  color: AppColors.kartu,
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
                                      : (ringkasan.kuotaPindai /
                                              kuotaPindaiPekanan)
                                          .clamp(0.0, 1.0),
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
                                    : '${ringkasan.kuotaPindai}/$kuotaPindaiPekanan',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontSize: ringkasan.kuotaPindai <= 0
                                          ? AppSizes.ukuranTeksStatusKuota
                                          : null,
                                      color: ringkasan.kuotaPindai <= 0
                                          ? AppColors.putihRedup
                                          : AppColors.kartu,
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
        const SizedBox(height: AppSpacing.lebihBesar),

        // 4. Catatan Terakhir
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
                      color: AppColors.kuningMuda,
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
                    'Lihat semua',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.2,
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
            shadow: AppTheme.bayanganGelap,
            pressedShadow: AppTheme.bayanganGelapTertekan,
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
        const SizedBox(height: AppSpacing.sedang),

        // 5. Kartu Rincian Pengeluaran (memuat rincian kategori & atur target bulanan)
        KartuRincianPengeluaran(
          totalPekanIni: ringkasan.totalMingguIni,
          rincian: rincian,
          perbandinganTarget: perbandinganTarget,
        ),
      ],
    );
  }
}

class _KartuRingkasanPekan extends StatelessWidget {
  final RingkasanPekanEntity ringkasan;
  final PerbandinganTargetEntity? perbandinganTarget;

  const _KartuRingkasanPekan({
    required this.ringkasan,
    this.perbandinganTarget,
  });

  @override
  Widget build(BuildContext context) {
    final target = perbandinganTarget;
    final bool adaTarget = target != null && target.adaTarget;
    final double porsiBar;
    final Color warnaBar;
    final String teksSisa;
    final Color warnaTeksSisa;

    if (adaTarget) {
      porsiBar = target.persen.clamp(0.0, 1.0);
      warnaBar = target.isLewat ? AppColors.salah : AppColors.stabilo;
      teksSisa = target.isLewat
          ? 'Lewat ${target.lewat.toRupiah()} dari target bulanan'
          : 'Sisa ${target.sisa.toRupiah()} dari target bulanan';
      warnaTeksSisa =
          target.isLewat ? AppColors.merahTeks : AppColors.daunTua;
    } else if (ringkasan.totalMingguLalu > 0) {
      porsiBar = (ringkasan.totalMingguIni / ringkasan.totalMingguLalu)
          .clamp(0.0, 1.0);
      final bool boros = ringkasan.selisihMingguan > 0;
      final bool hemat = ringkasan.selisihMingguan < 0;
      warnaBar = boros ? AppColors.salah : AppColors.stabilo;
      teksSisa = ringkasan.selisihMingguan == 0
          ? 'Sama persis dengan pekan lalu'
          : '${ringkasan.selisihMingguan.abs().toRupiah()} ${hemat ? 'lebih hemat' : 'lebih boros'} dibanding pekan lalu';
      warnaTeksSisa =
          boros ? AppColors.merahTeks : (hemat ? AppColors.daunTua : AppColors.inkSoft);
    } else {
      porsiBar = ringkasan.totalMingguIni > 0 ? 1.0 : 0.0;
      warnaBar = AppColors.stabilo;
      teksSisa = 'Belum ada data pekan lalu';
      warnaTeksSisa = AppColors.inkSoft;
    }

    return KartuBukuTulis(
      radius: AppSizes.radiusKartu,
      shadow: AppTheme.bayanganGelap,
      pressedShadow: AppTheme.bayanganGelapTertekan,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PENGELUARAN PEKAN INI',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ringkasan.totalMingguIni.toRupiah(),
                    style: AppTheme.nominalBesar.copyWith(fontSize: 34),
                  ),
                ),
              ),
              if (adaTarget) ...[
                const SizedBox(width: AppSpacing.kecil),
                Text(
                  'dari ${(target.targetBulanan ?? 0).toRupiah()}/bln',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.kartu,
              border: Border.all(
                color: AppColors.ink,
                width: AppSizes.border,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusPil),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusPil),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: porsiBar,
                child: Container(color: warnaBar),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            teksSisa,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: warnaTeksSisa,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
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
            : Icons.help_outline_rounded;
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
