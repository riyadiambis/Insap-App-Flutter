import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/kuota_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/tur/langkah_tur.dart';
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

  ({String judul, String isi}) _teksBannerRefleksi(DateTime waktu) {
    final akhirPekan =
        waktu.weekday == DateTime.saturday || waktu.weekday == DateTime.sunday;
    if (refleksiPekanIniTersimpan) {
      return (
        judul: 'Refleksi pekan ini tersimpan',
        isi: 'Struki sudah mencatat evaluasi pekanmu. Ketuk untuk lihat.',
      );
    }
    if (akhirPekan) {
      return (
        judul: 'Refleksi pekan ini siap',
        isi: 'Struki sudah menyelidiki ke mana uangmu pergi.',
      );
    }
    return (
      judul: 'Pantau pekan ini bersama Struki',
      isi: 'Ketuk untuk lihat ke mana uangmu pergi pekan ini.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final waktu = waktuSekarang != null ? waktuSekarang!() : DateTime.now();
    final banner = _teksBannerRefleksi(waktu);
    final teks = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(
        left: AppSpacing.besar,
        top: AppSpacing.besar,
        right: AppSpacing.besar,
        bottom: AppSpacing.jarakGulirBawah,
      ),
      children: [
        // 1. Kartu Ringkasan Pekan (Beranda.dc.html)
        _KartuRingkasanPekan(
          ringkasan: ringkasan,
          perbandinganTarget: perbandinganTarget,
        ),
        const SizedBox(height: 14),

        // 2. Banner Refleksi Hijau Muda dengan MaskotStruki detektif (SELALU tampil)
        KartuBukuTulis(
          key: const Key('banner_refleksi_beranda'),
          onTap: () => context.go('/refleksi'),
          backgroundColor: AppColors.hijauMuda,
          shadow: AppTheme.bayanganGelap,
          pressedShadow: AppTheme.bayanganGelapTertekan,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          radius: AppSizes.radiusKartu,
          child: Row(
            children: [
              const MaskotStruki(
                key: Key('maskot_detektif_beranda'),
                pose: PoseMaskot.detektif,
                ukuran: AppSizes.ukuranMaskotBeranda,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.judul,
                      style: teks.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      banner.isi,
                      style: teks.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppColors.ink,
                        height: 1.4,
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
        const SizedBox(height: 14),

        // 3. Dua Kartu Berdampingan: Catat cepat & Pindai struk
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 112),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            Icons.edit_outlined,
                            size: AppSizes.ikonAksi,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catat cepat',
                              style: teks.titleMedium?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                height: 1.15,
                              ),
                            ),
                            Text(
                              'Ketik manual',
                              style: teks.bodySmall?.copyWith(
                                fontSize: 13,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 112),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.stabilo,
                                border: Border.all(
                                  color: AppColors.stabilo,
                                  width: AppSizes.border,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'AI',
                                style: teks.labelSmall?.copyWith(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pindai struk',
                              style: teks.titleMedium?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.kartu,
                                height: 1.15,
                              ),
                            ),
                            Text(
                              ringkasan.kuotaPindai <= 0
                                  ? 'Habis, reset Senin'
                                  : 'Sisa ${ringkasan.kuotaPindai} dari $kuotaPindaiPekanan pekan ini',
                              style: teks.bodySmall?.copyWith(
                                fontSize: 13,
                                color: AppColors.biruPudar,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Terakhir dicatat
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Terakhir dicatat',
                style: teks.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              button: true,
              label: 'Lihat semua',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.go('/riwayat'),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Center(
                    child: Text(
                      'Lihat semua',
                      style: teks.labelSmall?.copyWith(
                        fontSize: 14,
                        letterSpacing: 0,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (ringkasan.transaksiTerakhir.isEmpty)
          KartuBukuTulis(
            shadow: AppTheme.bayanganGelap,
            pressedShadow: AppTheme.bayanganGelapTertekan,
            padding: const EdgeInsets.all(AppSpacing.besar),
            child: Column(
              children: [
                const MaskotStruki(pose: PoseMaskot.catat, ukuran: 100),
                const SizedBox(height: AppSpacing.kecil),
                Text(
                  'Belum ada catatan',
                  textAlign: TextAlign.center,
                  style: teks.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Catat belanja pertamamu, atau pindai struk biar Struki yang mengetik.',
                  textAlign: TextAlign.center,
                  style: teks.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: AppSpacing.sedang),
                TombolStabilo(
                  key: const Key('tombol_catat_pertama'),
                  teks: 'Catat pengeluaran pertama',
                  onPressed: () => context.go('/catat'),
                ),
              ],
            ),
          )
        else
          ...ringkasan.transaksiTerakhir.map(
            (t) => _ItemTransaksi(transaksi: t),
          ),
        const SizedBox(height: AppSpacing.besar),

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
      warnaTeksSisa = boros
          ? AppColors.merahTeks
          : (hemat ? AppColors.daunTua : AppColors.inkSoft);
    } else {
      porsiBar = ringkasan.totalMingguIni > 0 ? 1.0 : 0.0;
      warnaBar = AppColors.stabilo;
      teksSisa = ringkasan.totalMingguIni > 0
          ? 'Belum ada data pekan lalu'
          : 'Belum ada pengeluaran pekan ini';
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
                    fontSize: 14,
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
              border: Border.all(color: AppColors.ink, width: AppSizes.border),
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
          waktu = transaksi.sumber == 'pindai'
              ? '$jam:$menit · struk'
              : '$jam:$menit';
        } catch (_) {
          waktu = transaksi.sumber == 'pindai' ? 'struk' : '-';
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
