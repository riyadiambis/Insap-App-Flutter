import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

class HalamanPerkenalan extends StatefulWidget {
  const HalamanPerkenalan({super.key});

  @override
  State<HalamanPerkenalan> createState() => _HalamanPerkenalanState();
}

class _HalamanPerkenalanState extends State<HalamanPerkenalan> {
  final PageController _pageController = PageController();
  final TextEditingController _targetController = TextEditingController();
  int _halamanAktif = 0;
  bool _modeTarget = false;
  String? _pesanGalat;

  @override
  void dispose() {
    _pageController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _bukaLayarTarget() {
    setState(() {
      _modeTarget = true;
    });
  }

  Future<void> _simpanTarget(BuildContext context) async {
    final raw = _targetController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final target = int.tryParse(raw);
    if (target == null || target <= 0) {
      setState(() {
        _pesanGalat = 'Masukkan target pengeluaran yang valid atau ketuk Nanti saja';
      });
      return;
    }

    setState(() => _pesanGalat = null);
    final cubit = context.read<OnboardingCubit>();
    await cubit.simpanTargetDanSelesai(target);
    if (!mounted || !context.mounted) return;
    context.go('/');
  }

  Future<void> _lewatiTarget(BuildContext context) async {
    final cubit = context.read<OnboardingCubit>();
    await cubit.lewatiTargetDanSelesai();
    if (!mounted || !context.mounted) return;
    context.go('/');
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
      body: PaperBackground(
        child: SafeArea(
          child: _modeTarget ? _buildLayarTarget(context) : _buildLayarSlide(context),
        ),
      ),
    );
  }

  Widget _buildLayarSlide(BuildContext context) {
    return Column(
      children: [
        // Header: Logo & Tombol Lewati
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.besar,
            vertical: AppSpacing.sedang,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.stabilo,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppSizes.border,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonAksi),
                      boxShadow: const [AppTheme.bayanganKecilGelap],
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 20,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.agakKecil),
                  Text(
                    'Insap',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              // Tombol Lewati tampil di semua layar perkenalan (Layar 1, 2, 3)
              TextButton(
                key: const Key('tombol_lewati'),
                onPressed: _bukaLayarTarget,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.inkSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sedang,
                    vertical: AppSpacing.agakKecil,
                  ),
                ),
                child: const Text(
                  'Lewati',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // PageView 3 Layar Perkenalan dengan LayoutBuilder (tinggi kartu dihitung dari ruang vertikal tersedia)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Sekitar 60% dari ruang vertikal di antara header dan indikator titik
              final double tinggiKartu = constraints.maxHeight * 0.60;

              return PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _halamanAktif = index);
                },
                children: [
                  _buildSlideItem(
                    context,
                    tinggiKartu: tinggiKartu,
                    ikon: Icons.auto_stories_rounded,
                    warnaLatarIkon: AppColors.stabilo,
                    label: 'KENALAN DULU',
                    judulSebelum: 'Sadar Sebelum ',
                    judulStabilo: 'Boncos',
                    isi: Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.inkSoft,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                        children: const [
                          TextSpan(
                            text: 'Insap bantu kamu sadar uangmu habis ',
                          ),
                          TextSpan(
                            text: 'ke mana',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          TextSpan(
                            text: ', sebelum dompet menipis.',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildSlideItem(
                    context,
                    tinggiKartu: tinggiKartu,
                    ikon: Icons.edit_note_rounded,
                    warnaLatarIkon: AppColors.paper,
                    label: 'CATAT',
                    judulSebelum: 'Catat Cepat ',
                    judulStabilo: 'Dua Langkah',
                    isi: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBarisLangkah(
                          context,
                          nomor: 1,
                          konten: Text.rich(
                            TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                              children: const [
                                TextSpan(
                                  text: 'Isi nominal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                TextSpan(text: ' — '),
                                TextSpan(
                                  text: 'contoh Rp15.000',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.agakKecil),
                        _buildBarisLangkah(
                          context,
                          nomor: 2,
                          konten: Text.rich(
                            TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                              children: const [
                                TextSpan(
                                  text: 'Pilih kategori',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                TextSpan(text: ' — '),
                                TextSpan(
                                  text: 'makan, transport, nongkrong...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSlideItem(
                    context,
                    tinggiKartu: tinggiKartu,
                    ikon: Icons.psychology_alt_outlined,
                    warnaLatarIkon: AppColors.stabilo,
                    label: 'TIAP AKHIR PEKAN',
                    judulSebelum: 'Refleksi ',
                    judulStabilo: 'Mingguan',
                    isi: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBarisLangkah(
                          context,
                          nomor: 1,
                          konten: Text.rich(
                            TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                              children: const [
                                TextSpan(
                                  text: 'Lihat ulang',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                TextSpan(text: ' pengeluaran sepekan'),
                              ],
                            ),
                          ),
                        ),
                        _buildBarisLangkah(
                          context,
                          nomor: 2,
                          konten: Text.rich(
                            TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                              children: const [
                                TextSpan(text: 'Tandai: '),
                                TextSpan(
                                  text: 'butuh atau pengen?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildBarisLangkah(
                          context,
                          nomor: 3,
                          konten: Text.rich(
                            TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                              children: const [
                                TextSpan(text: 'Tetapkan '),
                                TextSpan(
                                  text: 'target',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                TextSpan(text: ' pekan depan'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sangatKecil),
                        Text(
                          'Santai, tanpa menghakimi.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Bagian Bawah: Indikator Titik & Tombol Navigasi
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.besar,
            vertical: AppSpacing.sedang,
          ),
          child: Column(
            children: [
              // Indikator Titik Halaman
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final bool aktif = index == _halamanAktif;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: aktif ? 24 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: aktif ? AppColors.stabilo : AppColors.paper,
                      borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppSizes.borderTipis,
                      ),
                      boxShadow: aktif ? const [AppTheme.bayanganKecilGelap] : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.sedang),

              // Tombol Aksi Bawah
              TombolStabilo(
                key: const Key('tombol_lanjut'),
                teks: _halamanAktif == 2 ? 'Atur Target' : 'Lanjut',
                ikon: _halamanAktif == 2
                    ? Icons.track_changes_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (_halamanAktif < 2) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _bukaLayarTarget();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlideItem(
    BuildContext context, {
    required double tinggiKartu,
    required IconData ikon,
    required Color warnaLatarIkon,
    required String label,
    required String judulSebelum,
    required String judulStabilo,
    String? judulSetelah,
    required Widget isi,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.besar),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
          child: SizedBox(
            height: tinggiKartu,
            child: KartuBukuTulis(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.besar,
                vertical: AppSpacing.kecil,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ilustrasi Lingkaran Ikon tema Buku Tulis diperbesar sekitar 1,5x (diameter 120, ikon 72)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: warnaLatarIkon,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppSizes.border,
                      ),
                      boxShadow: const [AppTheme.bayanganDefault],
                    ),
                    child: Icon(
                      ikon,
                      size: 72,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.kecil),

                  // 1. Label kecil di atas judul: huruf kapital, kecil, tebal, berwarna aksen tema (seperti badge)
                  _buildLabelBadge(context, label),
                  const SizedBox(height: AppSpacing.sangatKecil),

                  // 2. Judul besar Baloo 2 dengan SATU frasa diberi efek stabilo kuning
                  _buildJudulBerstabilo(
                    context,
                    teksSebelum: judulSebelum,
                    teksStabilo: judulStabilo,
                    teksSetelah: judulSetelah,
                  ),
                  const SizedBox(height: AppSpacing.kecil),

                  // 3. Isi Nunito (Expanded + SingleChildScrollView agar posisi awal seragam dan bebas overflow)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: double.infinity,
                        child: isi,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Label kecil di atas judul: huruf kapital, kecil, tebal, berwarna aksen tema (seperti badge).
  Widget _buildLabelBadge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sedang,
        vertical: AppSpacing.mini,
      ),
      decoration: BoxDecoration(
        color: AppColors.grid,
        borderRadius: BorderRadius.circular(AppSizes.radiusPil),
        border: Border.all(
          color: AppColors.ink,
          width: AppSizes.borderTipis,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
      ),
    );
  }

  /// Judul besar Baloo 2 dengan SATU frasa diberi efek stabilo kuning (gaya stabilo seperti di judul Riwayat Transaksi).
  Widget _buildJudulBerstabilo(
    BuildContext context, {
    required String teksSebelum,
    required String teksStabilo,
    String? teksSetelah,
  }) {
    final TextStyle gayaJudul =
        Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ) ??
            const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontSize: 22,
            );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (teksSebelum.isNotEmpty)
            Text(
              teksSebelum,
              style: gayaJudul,
            ),
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
                teksStabilo,
                style: gayaJudul,
              ),
            ],
          ),
          if (teksSetelah != null && teksSetelah.isNotEmpty)
            Text(
              teksSetelah,
              style: gayaJudul,
            ),
        ],
      ),
    );
  }

  /// Butir langkah bernomor untuk Layar 2 dan 3 (lingkaran nomor kecil + teks).
  Widget _buildBarisLangkah(
    BuildContext context, {
    required int nomor,
    required Widget konten,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.grid,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.ink,
                width: AppSizes.borderTipis,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$nomor',
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.ink,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sedang),
          Expanded(child: konten),
        ],
      ),
    );
  }

  Widget _buildLayarTarget(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.besar),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
          child: KartuBukuTulis(
            padding: const EdgeInsets.all(AppSpacing.lebihBesar),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.stabilo,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppSizes.border,
                      ),
                      boxShadow: const [AppTheme.bayanganDefault],
                    ),
                    child: const Icon(
                      Icons.track_changes_rounded,
                      size: 36,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.besar),

                Text(
                  'Tentukan Target Bulanan',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: AppSpacing.agakKecil),

                Text(
                  'Berapa batas maksimal pengeluaranmu dalam sebulan? Kamu bisa mengubahnya nanti kapan saja.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.lebihBesar),

                // Kolom Input Target Bulanan
                TextField(
                  key: const Key('kolom_target_bulanan'),
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontSize: 16,
                    ),
                    hintText: 'Contoh: 2000000',
                    hintStyle: const TextStyle(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: AppColors.paper,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sedang,
                      vertical: AppSpacing.sedang,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                      borderSide: const BorderSide(
                        color: AppColors.ink,
                        width: AppSizes.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                      borderSide: const BorderSide(
                        color: AppColors.ink,
                        width: AppSizes.border,
                      ),
                    ),
                  ),
                ),

                if (_pesanGalat != null) ...[
                  const SizedBox(height: AppSpacing.agakKecil),
                  Text(
                    _pesanGalat!,
                    style: const TextStyle(
                      color: AppColors.salah,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lebihBesar),

                // Tombol Simpan
                BlocBuilder<OnboardingCubit, OnboardingState>(
                  builder: (context, state) {
                    final bool memuat = state is OnboardingLoading;
                    return TombolStabilo(
                      key: const Key('tombol_simpan_target'),
                      teks: 'Simpan Target',
                      isLoading: memuat,
                      ikon: Icons.check_circle_outline,
                      onPressed: memuat ? null : () => _simpanTarget(context),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sedang),

                // Tombol Nanti Saja
                BlocBuilder<OnboardingCubit, OnboardingState>(
                  builder: (context, state) {
                    final bool memuat = state is OnboardingLoading;
                    return OutlinedButton(
                      key: const Key('tombol_nanti_saja'),
                      onPressed: memuat ? null : () => _lewatiTarget(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sedang,
                        ),
                        side: const BorderSide(
                          color: AppColors.ink,
                          width: AppSizes.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                        ),
                      ),
                      child: const Text(
                        'Nanti saja',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
