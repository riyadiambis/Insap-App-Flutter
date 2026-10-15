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

        // PageView 3 Layar Perkenalan
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _halamanAktif = index);
            },
            children: [
              _buildSlideItem(
                context,
                ikon: Icons.auto_stories_rounded,
                warnaLatarIkon: AppColors.stabilo,
                judul: 'Sadar Sebelum Boncos',
                kalimat:
                    'Insap bantu kamu sadar uangmu habis ke mana, sebelum dompet menipis.',
              ),
              _buildSlideItem(
                context,
                ikon: Icons.edit_note_rounded,
                warnaLatarIkon: AppColors.paper,
                judul: 'Catat Cepat Dua Langkah',
                kalimat:
                    'Cukup isi nominal pengeluaran lalu pilih kategori, catatan keuanganmu langsung rapi seketika.',
              ),
              _buildSlideItem(
                context,
                ikon: Icons.psychology_alt_outlined,
                warnaLatarIkon: AppColors.stabilo,
                judul: 'Refleksi Mingguan Tanpa Beban',
                kalimat:
                    'Tiap akhir pekan, luangkan sejenak untuk melihat ulang pengeluaran, tandai butuh atau pengen, lalu tetapkan target hemat untuk pekan depan.',
              ),
            ],
          ),
        ),

        // Bagian Bawah: Indikator Titik & Tombol Navigasi
        Padding(
          padding: const EdgeInsets.all(AppSpacing.besar),
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
              const SizedBox(height: AppSpacing.besar),

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
    required IconData ikon,
    required Color warnaLatarIkon,
    required String judul,
    required String kalimat,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.besar),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
          child: KartuBukuTulis(
            padding: const EdgeInsets.all(AppSpacing.lebihBesar),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ilustrasi Lingkaran Ikon tema Buku Tulis
                Container(
                  width: 96,
                  height: 96,
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
                    size: 48,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.lebihBesar),

                // Judul Slide
                Text(
                  judul,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: AppSpacing.sedang),

                // Kalimat Slide
                Text(
                  kalimat,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSoft,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
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
