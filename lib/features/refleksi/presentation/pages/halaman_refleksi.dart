import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/iso_week.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../beranda/presentation/cubit/beranda_state.dart';
import '../../../beranda/presentation/widgets/tampilan_kategori.dart';
import '../../domain/usecases/ambil_refleksi_pekan.dart';
import '../cubit/refleksi_cubit.dart';
import '../cubit/refleksi_state.dart';

enum _PeriodeRefleksi { pekan, bulan }

class HalamanRefleksi extends StatelessWidget {
  final VoidCallback? onMintaRefleksiAi;

  const HalamanRefleksi({super.key, this.onMintaRefleksiAi});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<RefleksiCubit>();
      return _RefleksiView(onMintaRefleksiAi: onMintaRefleksiAi);
    } catch (_) {
      return BlocProvider<RefleksiCubit>(
        create: (_) => sl<RefleksiCubit>()..muatRefleksi(),
        child: _RefleksiView(onMintaRefleksiAi: onMintaRefleksiAi),
      );
    }
  }
}

class _RefleksiView extends StatelessWidget {
  final VoidCallback? onMintaRefleksiAi;

  const _RefleksiView({this.onMintaRefleksiAi});

  bool _adaBerandaCubit(BuildContext context) {
    try {
      context.read<BerandaCubit>();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kontenScaffold = Scaffold(
      body: PaperBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.batasLebarKonten,
            ),
            child: BlocBuilder<RefleksiCubit, RefleksiState>(
              builder: (context, state) {
                if (state.status == RefleksiStatus.initial ||
                    (state.status == RefleksiStatus.loading &&
                        state.data == null)) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                    ),
                  );
                }

                if (state.status == RefleksiStatus.error &&
                    state.data == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.besar),
                      child: Text(
                        'Ups, gagal memuat refleksi:\n${state.pesanGalat ?? ''}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                final data = state.data;
                if (data == null) {
                  return const SizedBox.shrink();
                }

                return _KontenRefleksi(
                  data: data,
                  onMintaRefleksiAi: onMintaRefleksiAi,
                );
              },
            ),
          ),
        ),
      ),
    );

    if (_adaBerandaCubit(context)) {
      return BlocListener<BerandaCubit, BerandaState>(
        listenWhen: (prev, curr) => curr is BerandaLoaded,
        listener: (context, _) {
          context.read<RefleksiCubit>().muatRefleksi();
        },
        child: kontenScaffold,
      );
    }

    return kontenScaffold;
  }
}

class _KontenRefleksi extends StatefulWidget {
  final DataRefleksiPekan data;
  final VoidCallback? onMintaRefleksiAi;

  const _KontenRefleksi({
    required this.data,
    this.onMintaRefleksiAi,
  });

  @override
  State<_KontenRefleksi> createState() => _KontenRefleksiState();
}

class _KontenRefleksiState extends State<_KontenRefleksi> {
  _PeriodeRefleksi _periode = _PeriodeRefleksi.pekan;

  static const List<String> _namaBulan = [
    '',
    'JANUARI',
    'FEBRUARI',
    'MARET',
    'APRIL',
    'MEI',
    'JUNI',
    'JULI',
    'AGUSTUS',
    'SEPTEMBER',
    'OKTOBER',
    'NOVEMBER',
    'DESEMBER',
  ];

  String _labelPeriode(bool isPekan) {
    if (isPekan) {
      return formatRentangTanggal(
        widget.data.awalPekan,
        widget.data.akhirPekan,
      ).toUpperCase();
    }
    final acuan = widget.data.tanggalAcuan ?? widget.data.akhirPekan;
    return '${_namaBulan[acuan.month]} ${acuan.year}';
  }

  ({String teks, Color warna}) _infoPerbandingan({
    required int totalIni,
    required int totalLalu,
    required String labelLalu,
  }) {
    if (totalLalu <= 0) {
      return (
        teks: 'Belum ada data $labelLalu',
        warna: AppColors.inkSoft,
      );
    }
    final selisih = totalIni - totalLalu;
    final persen = ((selisih.abs() * 100) / totalLalu).round();
    if (selisih < 0) {
      return (
        teks: '-$persen% dari $labelLalu',
        warna: AppColors.daunTua,
      );
    }
    if (selisih > 0) {
      return (
        teks: '+$persen% dari $labelLalu',
        warna: AppColors.merahTeks,
      );
    }
    return (
      teks: '0% dari $labelLalu',
      warna: AppColors.inkSoft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isPekan = _periode == _PeriodeRefleksi.pekan;

    final int totalIni = isPekan
        ? widget.data.agregat.totalPekanIni
        : widget.data.totalBulanIni;
    final int totalLalu = isPekan
        ? widget.data.agregat.totalPekanLalu
        : widget.data.totalBulanLalu;
    final String labelLalu = isPekan ? 'pekan lalu' : 'bulan lalu';

    final List<RincianKategoriRefleksi> daftarKategori = isPekan
        ? widget.data.kategoriPekanIni
        : widget.data.kategoriBulanIni;

    final infoBanding = _infoPerbandingan(
      totalIni: totalIni,
      totalLalu: totalLalu,
      labelLalu: labelLalu,
    );

    final bool adaTransaksiPekanIni = widget.data.agregat.adaTransaksi;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.besar,
        AppSpacing.sedang,
        AppSpacing.besar,
        AppSpacing.jarakGulirBawah,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Chip pilihan periode
          Row(
            children: [
              _ChipPeriodeRefleksi(
                key: const Key('chip_refleksi_pekan_ini'),
                label: 'Pekan ini',
                aktif: isPekan,
                onTap: () => setState(() => _periode = _PeriodeRefleksi.pekan),
              ),
              const SizedBox(width: AppSpacing.kecil),
              _ChipPeriodeRefleksi(
                key: const Key('chip_refleksi_bulan_ini'),
                label: 'Bulan ini',
                aktif: !isPekan,
                onTap: () => setState(() => _periode = _PeriodeRefleksi.bulan),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Kartu periode + total + persen dibanding periode lalu
          KartuBukuTulis(
            key: const Key('kartu_periode_refleksi'),
            radius: AppSizes.radiusKartu,
            backgroundColor: AppColors.kartu,
            shadow: AppTheme.bayanganGelap,
            pressedShadow: AppTheme.bayanganGelapTertekan,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelPeriode(isPekan),
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppColors.inkSoft,
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
                          totalIni.toRupiah(),
                          key: const Key('total_pengeluaran_refleksi'),
                          style: AppTheme.nominalUtama,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.kecil),
                    Flexible(
                      child: Text(
                        infoBanding.teks,
                        key: const Key('persen_banding_refleksi'),
                        textAlign: TextAlign.right,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: infoBanding.warna,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Kartu "Ke mana uangmu pergi"
          KartuBukuTulis(
            key: const Key('kartu_kategori_refleksi'),
            radius: AppSizes.radiusKartu,
            backgroundColor: AppColors.kartu,
            shadow: AppTheme.bayanganGelap,
            pressedShadow: AppTheme.bayanganGelapTertekan,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ke mana uangmu pergi',
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                if (daftarKategori.isEmpty || totalIni <= 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      isPekan
                          ? 'Belum ada pengeluaran pekan ini.'
                          : 'Belum ada pengeluaran bulan ini.',
                      key: const Key('teks_kategori_kosong_refleksi'),
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < daftarKategori.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _BarisKategoriRefleksi(
                      item: daftarKategori[i],
                      totalPeriode: totalIni,
                    ),
                  ],
              ],
            ),
          ),

          // 4. Tombol "Minta refleksi AI" (hanya tampil pada tab Pekan ini)
          if (isPekan) ...[
            const SizedBox(height: 14),
            TombolStabilo(
              key: const Key('tombol_minta_refleksi_ai'),
              teks: 'Minta refleksi AI',
              ikon: Icons.auto_awesome_outlined,
              onPressed: adaTransaksiPekanIni
                  ? (widget.onMintaRefleksiAi ??
                        () => context.push('/refleksi/hasil'))
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              adaTransaksiPekanIni
                  ? 'Struki merangkum pola belanjamu dan memberi 3 saran.'
                  : 'Catat dulu belanjamu pekan ini.',
              key: const Key('keterangan_tombol_refleksi_ai'),
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipPeriodeRefleksi extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  const _ChipPeriodeRefleksi({
    super.key,
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
                border: Border.all(
                  color: AppColors.ink,
                  width: AppSizes.border,
                ),
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

class _BarisKategoriRefleksi extends StatelessWidget {
  final RincianKategoriRefleksi item;
  final int totalPeriode;

  const _BarisKategoriRefleksi({
    required this.item,
    required this.totalPeriode,
  });

  @override
  Widget build(BuildContext context) {
    final warna = parseWarnaKategori(item.warna);
    final ikon = parseIkonKategori(item.ikon);
    final double porsi = totalPeriode > 0 ? item.total / totalPeriode : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(ikon, size: 16, color: warna),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      kapitalPertama(item.nama),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.kecil),
            Text(
              item.total.toRupiah(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
              widthFactor: porsi.clamp(0.0, 1.0),
              child: Container(color: warna),
            ),
          ),
        ),
      ],
    );
  }
}
