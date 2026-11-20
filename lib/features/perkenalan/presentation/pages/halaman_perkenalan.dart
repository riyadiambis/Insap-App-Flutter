import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/header_aplikasi.dart';
import '../../../../core/widgets/maskot_struki.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../transaksi/presentation/catat/widgets/kolom_input_nominal.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

class HalamanPerkenalan extends StatefulWidget {
  const HalamanPerkenalan({super.key});

  @override
  State<HalamanPerkenalan> createState() => _HalamanPerkenalanState();
}

class _HalamanPerkenalanState extends State<HalamanPerkenalan> {
  final PageController _pageController = PageController();
  int _targetNominal = 2000000;
  int _halamanAktif = 0;
  bool _modeTarget = false;
  String? _pesanGalat;

  static const List<({String label, int nilai})> _pilihanPresetTarget = [
    (label: 'Rp 1 jt', nilai: 1000000),
    (label: 'Rp 1,5 jt', nilai: 1500000),
    (label: 'Rp 2 jt', nilai: 2000000),
    (label: 'Rp 3 jt', nilai: 3000000),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _bukaLayarTarget() {
    setState(() {
      _modeTarget = true;
    });
  }

  void _kembaliKeSambutan() {
    setState(() {
      _modeTarget = false;
      _pesanGalat = null;
    });
  }

  Future<void> _simpanTarget(BuildContext context) async {
    if (_targetNominal <= 0) {
      setState(() {
        _pesanGalat =
            'Masukkan target pengeluaran yang valid atau ketuk Nanti saja';
      });
      return;
    }

    setState(() => _pesanGalat = null);
    final cubit = context.read<OnboardingCubit>();
    await cubit.simpanTargetDanSelesai(_targetNominal);
    if (!mounted || !context.mounted) return;
    try {
      context.go('/');
    } catch (_) {}
  }

  Future<void> _lewatiTarget(BuildContext context, {String tujuan = '/'}) async {
    final cubit = context.read<OnboardingCubit>();
    await cubit.lewatiTargetDanSelesai();
    if (!mounted || !context.mounted) return;
    try {
      context.go(tujuan);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    try {
      context.read<OnboardingCubit>();
      return _buildContent(context);
    } catch (_) {
      return BlocProvider<OnboardingCubit>(
        create: (_) => sl<OnboardingCubit>(),
        child: Builder(
          builder: (childContext) => _buildContent(childContext),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: _modeTarget
          ? HeaderAplikasi(
              namaLayar: 'Target bulanan',
              modeKembali: true,
              onKembali: _kembaliKeSambutan,
            )
          : null,
      body: PaperBackground(
        child: SafeArea(
          top: !_modeTarget,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.batasLebarKonten,
              ),
              child: _modeTarget
                  ? _buildLayarTarget(context)
                  : _buildLayarSambutan(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayarSambutan(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _halamanAktif = index);
            },
            children: _layarSambutan
                .map(
                  (layar) => _buildKontenSambutan(
                    context,
                    layar: layar,
                    halamanAktif: _halamanAktif,
                    jumlahHalaman: _layarSambutan.length,
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.besar,
            0,
            AppSpacing.besar,
            AppSpacing.besar,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TombolStabilo(
                key: const Key('tombol_mulai_sambutan'),
                teks: 'Mulai',
                onPressed: _bukaLayarTarget,
              ),
              const SizedBox(height: 6),
              TextButton(
                key: const Key('tombol_sudah_punya_akun'),
                onPressed: () => _lewatiTarget(context, tujuan: '/akun'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                child: const Text(
                  'Sudah punya akun? Masuk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKontenSambutan(
    BuildContext context, {
    required _DataLayarSambutan layar,
    required int halamanAktif,
    required int jumlahHalaman,
  }) {
    final teks = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MaskotStruki(
                  key: const Key('maskot_sambutan'),
                  pose: layar.pose,
                  ukuran: AppSizes.ukuranMaskotSambutan,
                ),
                const SizedBox(height: 12),
                Text(
                  layar.judul,
                  textAlign: TextAlign.center,
                  style: teks.headlineMedium?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    layar.isi,
                    textAlign: TextAlign.center,
                    style: teks.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: AppColors.ink,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(jumlahHalaman, (index) {
                    final aktif = index == halamanAktif;
                    return AnimatedContainer(
                      duration: AppDurations.animasiMunculKartu,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: aktif ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: aktif ? AppColors.ink : AppColors.garisPutus,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayarTarget(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final int perPekan = (_targetNominal / 4).round();

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final bool memuat = state is OnboardingLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.besar),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const MaskotStruki(
                          key: Key('maskot_target_sambutan'),
                          pose: PoseMaskot.nabung,
                          ukuran: AppSizes.ukuranMaskotTarget,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LANGKAH 2 DARI 3',
                                style: teks.labelSmall?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Berapa batas belanja sebulan?',
                                style: teks.headlineSmall?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Angka ini jadi patokan refleksi. Bisa diubah kapan saja di Akun.',
                      style: teks.bodyMedium?.copyWith(
                        fontSize: 15,
                        color: AppColors.ink,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'TARGET BULANAN',
                      style: teks.labelSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kartu,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppSizes.border,
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: KolomInputNominal(
                        key: const Key('kolom_target_bulanan'),
                        nominal: _targetNominal,
                        onChanged: (val) {
                          setState(() {
                            _targetNominal = val;
                            _pesanGalat = null;
                          });
                        },
                      ),
                    ),
                    if (_pesanGalat != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _pesanGalat!,
                        style: const TextStyle(
                          color: AppColors.merahTeks,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _pilihanPresetTarget.map((preset) {
                        final terpilih = _targetNominal == preset.nilai;
                        return Semantics(
                          button: true,
                          selected: terpilih,
                          label: preset.label,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _targetNominal = preset.nilai;
                                _pesanGalat = null;
                              });
                            },
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              child: Center(
                                widthFactor: 1.0,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 36,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: terpilih
                                        ? AppColors.ink
                                        : AppColors.kartu,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusPil,
                                    ),
                                    border: Border.all(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                  ),
                                  child: Text(
                                    preset.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: terpilih
                                          ? AppColors.kartu
                                          : AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.hijauMuda,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusKartu,
                        ),
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppSizes.border,
                        ),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: teks.bodyMedium?.copyWith(
                            fontSize: 15,
                            color: AppColors.ink,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: 'Sekitar '),
                            TextSpan(
                              text: '${perPekan.toRupiah()} per pekan',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  '. Struki akan kabari kalau pekan ini mendekati batas.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.besar,
                AppSpacing.kecil,
                AppSpacing.besar,
                AppSpacing.besar,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: TextButton(
                      key: const Key('tombol_nanti_saja'),
                      onPressed: memuat ? null : () => _lewatiTarget(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text(
                        'Nanti saja',
                        style: TextStyle(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  TombolStabilo(
                    key: const Key('tombol_simpan_target'),
                    teks: 'Lanjut',
                    isLoading: memuat,
                    onPressed: (_targetNominal > 0 && !memuat)
                        ? () => _simpanTarget(context)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DataLayarSambutan {
  final String judul;
  final String isi;
  final PoseMaskot pose;

  const _DataLayarSambutan({
    required this.judul,
    required this.isi,
    required this.pose,
  });
}

const List<_DataLayarSambutan> _layarSambutan = [
  _DataLayarSambutan(
    judul: 'Halo, aku Struki!',
    isi:
        'Kirim struk belanjamu ke aku. Aku catat, kamu tinggal insaf sebelum boncos.',
    pose: PoseMaskot.mulai,
  ),
  _DataLayarSambutan(
    judul: 'Biar AI yang baca struknya',
    isi:
        'Foto struk belanjamu. AI membaca tiap barang, kamu cukup periksa lalu simpan.',
    pose: PoseMaskot.scan,
  ),
  _DataLayarSambutan(
    judul: 'Tutup pekan dengan refleksi',
    isi:
        'Tiap akhir pekan, lihat ke mana uangmu pergi dan tulis satu hal yang mau diperbaiki.',
    pose: PoseMaskot.detektif,
  ),
];
