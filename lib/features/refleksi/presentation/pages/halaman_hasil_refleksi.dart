import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/header_aplikasi.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/maskot_struki.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../beranda/presentation/widgets/tampilan_kategori.dart';
import '../../domain/entities/refleksi_ai_entity.dart';
import '../cubit/hasil_refleksi_cubit.dart';
import '../cubit/hasil_refleksi_state.dart';

class HalamanHasilRefleksi extends StatelessWidget {
  const HalamanHasilRefleksi({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<HasilRefleksiCubit>();
      return const _HasilRefleksiView();
    } catch (_) {
      return BlocProvider<HasilRefleksiCubit>(
        create: (_) => sl<HasilRefleksiCubit>()..muat(),
        child: const _HasilRefleksiView(),
      );
    }
  }
}

class _HasilRefleksiView extends StatelessWidget {
  const _HasilRefleksiView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderAplikasi(
        namaLayar: 'Refleksi pekan ini',
        modeKembali: true,
      ),
      body: PaperBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.batasLebarKonten,
              ),
              child: BlocBuilder<HasilRefleksiCubit, HasilRefleksiState>(
                builder: (context, state) {
                  if (state is HasilRefleksiInitial ||
                      state is HasilRefleksiLoading) {
                    return const _TampilanMemuat();
                  }

                  if (state is HasilRefleksiError) {
                    return _TampilanGalat(
                      pesan: state.pesan,
                      onCobaLagi: () =>
                          context.read<HasilRefleksiCubit>().muat(),
                    );
                  }

                  if (state is HasilRefleksiLoaded) {
                    return _TampilanHasil(hasil: state.hasil);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TampilanMemuat extends StatelessWidget {
  const _TampilanMemuat();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.besar),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MaskotStruki(
              key: Key('maskot_memuat_refleksi'),
              pose: PoseMaskot.detektif,
              ukuran: AppSizes.ukuranMaskotRefleksi,
            ),
            const SizedBox(height: AppSpacing.sedang),
            Text(
              'Struki sedang merangkum pekanmu...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TampilanGalat extends StatelessWidget {
  final String pesan;
  final VoidCallback onCobaLagi;

  const _TampilanGalat({
    required this.pesan,
    required this.onCobaLagi,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.besar),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sedang,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MaskotStruki(
                      key: Key('maskot_galat_refleksi'),
                      pose: PoseMaskot.puyeng,
                      ukuran: AppSizes.ukuranMaskotRefleksi,
                    ),
                    const SizedBox(height: AppSpacing.sedang),
                    Text(
                      pesan,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.besar),
          TombolStabilo(
            key: const Key('tombol_coba_lagi_refleksi'),
            teks: 'Coba lagi',
            onPressed: onCobaLagi,
          ),
        ],
      ),
    );
  }
}

class _TampilanHasil extends StatelessWidget {
  final HasilRefleksiAi hasil;

  const _TampilanHasil({required this.hasil});

  List<InlineSpan> _bangunKeterangan(EvaluasiHematBoncos eval) {
    if (eval.pakaiTarget) {
      if (eval.selisih == 0) {
        return const [
          TextSpan(text: 'Pekan ini kamu tepat sesuai target.'),
        ];
      }
      if (eval.hemat) {
        return [
          const TextSpan(text: 'Pekan ini kamu '),
          TextSpan(
            text: '${eval.selisih.abs().toRupiah()} di bawah target',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.daunTua,
            ),
          ),
          const TextSpan(text: '.'),
        ];
      }
      return [
        const TextSpan(text: 'Pekan ini '),
        TextSpan(
          text: '${eval.selisih.toRupiah()} di atas target',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.merahTeks,
          ),
        ),
        const TextSpan(text: '. Tidak apa-apa, pekan depan bisa diatur.'),
      ];
    }

    if (eval.pembanding == null) {
      return const [
        TextSpan(
          text: 'Belum ada target maupun pengeluaran dibanding pekan lalu.',
        ),
      ];
    }

    if (eval.selisih == 0) {
      return const [
        TextSpan(text: 'Pekan ini pengeluaranmu sama dibanding pekan lalu.'),
      ];
    }
    if (eval.hemat) {
      return [
        const TextSpan(text: 'Pekan ini kamu '),
        TextSpan(
          text: '${eval.selisih.abs().toRupiah()} lebih hemat',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.daunTua,
          ),
        ),
        const TextSpan(text: ' dibanding pekan lalu.'),
      ];
    }
    return [
      const TextSpan(text: 'Pekan ini '),
      TextSpan(
        text: '${eval.selisih.toRupiah()} lebih banyak',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.merahTeks,
        ),
      ),
      const TextSpan(
        text: ' dibanding pekan lalu. Tidak apa-apa, pekan depan bisa diatur.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final eval = hasil.evaluasi;
    final bool hemat = eval.hemat;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.besar,
        AppSpacing.besar,
        AppSpacing.besar,
        AppSpacing.lebihBesar,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KartuBukuTulis(
            key: const Key('kartu_status_hasil_refleksi'),
            radius: AppSizes.radiusKartu,
            backgroundColor: hemat
                ? AppColors.hijauMuda
                : AppColors.boncosLatar,
            shadow: AppTheme.bayanganGelap,
            pressedShadow: AppTheme.bayanganGelapTertekan,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                MaskotStruki(
                  key: const Key('maskot_hasil_refleksi'),
                  pose: hemat ? PoseMaskot.hemat : PoseMaskot.boncos,
                  ukuran: AppSizes.ukuranMaskotRefleksi,
                ),
                const SizedBox(height: 6),
                Text(
                  hemat ? 'Hemat dan happy!' : 'Astaga, lewat sedikit',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: AppColors.ink,
                      height: 1.5,
                    ),
                    children: _bangunKeterangan(eval),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Kata Struki',
            style: textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          KartuBukuTulis(
            key: const Key('kartu_kata_struki'),
            radius: AppSizes.radiusKartu,
            backgroundColor: AppColors.kartu,
            shadow: AppTheme.bayanganGelap,
            pressedShadow: AppTheme.bayanganGelapTertekan,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < hasil.saran.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _BarisSaranStruki(item: hasil.saran[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisSaranStruki extends StatelessWidget {
  final SaranRefleksiItem item;

  const _BarisSaranStruki({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool dikenal = item.ikon != null && item.warna != null;
    final IconData ikonData = dikenal
        ? parseIkonKategori(item.ikon!)
        : Icons.lightbulb_outline_rounded;
    final Color warnaIkon = dikenal
        ? parseWarnaKategori(item.warna!)
        : AppColors.daunTua;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(ikonData, size: 18, color: warnaIkon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.teks,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.5,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
