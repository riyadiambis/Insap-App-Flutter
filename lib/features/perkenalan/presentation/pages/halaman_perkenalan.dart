import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
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
  int _targetNominal = 0;
  int _halamanAktif = 0;
  bool _modeTarget = false;
  String? _pesanGalat;

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

  Future<void> _lewatiTarget(BuildContext context) async {
    final cubit = context.read<OnboardingCubit>();
    await cubit.lewatiTargetDanSelesai();
    if (!mounted || !context.mounted) return;
    try {
      context.go('/');
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
      body: PaperBackground(
        child: SafeArea(
          child: _modeTarget ? _buildLayarTarget(context) : _buildLayarSlide(context),
        ),
      ),
    );
  }

  Widget _buildLayarSlide(BuildContext context) {
    final bool dilayarPertama = _halamanAktif == 0;
    return Column(
      children: [
        // Header: logo di kiri, Lewati di kanan atas
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

        // PageView lima layar sambutan
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _halamanAktif = index);
            },
            children: _layarSambutan
                .map((layar) => _buildLayarIlustrasi(context, layar))
                .toList(),
          ),
        ),

        // Bagian bawah: indikator titik dan dua tombol sama lebar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.besar,
            vertical: AppSpacing.sedang,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.batasLebarKonten,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_layarSambutan.length, (index) {
                      final bool aktif = index == _halamanAktif;
                      return AnimatedContainer(
                        duration: AppDurations.animasiMunculKartu,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sangatKecil,
                        ),
                        width: aktif
                            ? AppSizes.lebarTitikAktifSambutan
                            : AppSizes.tinggiTitikSambutan,
                        height: AppSizes.tinggiTitikSambutan,
                        decoration: BoxDecoration(
                          color: aktif ? AppColors.ink : AppColors.paper,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPil),
                          border: Border.all(
                            color: AppColors.ink,
                            width: AppSizes.border,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sedang),
                  Row(
                    children: [
                      Expanded(
                        child: _TombolKembaliSambutan(
                          key: const Key('tombol_kembali'),
                          onTap: dilayarPertama
                              ? null
                              : () => _pageController.previousPage(
                                    duration: AppDurations.animasiMunculKartu,
                                    curve: Curves.easeInOut,
                                  ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sedang),
                      Expanded(
                        child: TombolStabilo(
                          key: const Key('tombol_lanjut'),
                          teks: 'Lanjut',
                          ikon: Icons.arrow_forward_rounded,
                          onPressed: () {
                            if (_halamanAktif < _layarSambutan.length - 1) {
                              _pageController.nextPage(
                                duration: AppDurations.animasiMunculKartu,
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _bukaLayarTarget();
                            }
                          },
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
    );
  }

  /// Satu layar sambutan bergaya ikon besar: kotak ilustrasi berwarna,
  /// judul Baloo 2, dan satu paragraf pendek, semuanya rata tengah.
  Widget _buildLayarIlustrasi(BuildContext context, _DataLayarSambutan layar) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.besar),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.batasLebarKonten,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      key: const Key('kotak_ilustrasi_sambutan'),
                      width: AppSizes.kotakIlustrasiSambutan,
                      height: AppSizes.kotakIlustrasiSambutan,
                      decoration: BoxDecoration(
                        color: layar.warnaKotak,
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppSizes.borderIlustrasiSambutan,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusIlustrasiSambutan,
                        ),
                        boxShadow: const [AppTheme.bayanganIlustrasi],
                      ),
                      child: Icon(
                        layar.ikon,
                        size: AppSizes.ikonIlustrasiSambutan,
                        color: layar.warnaIkon,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.antarBagian),
                    Text(
                      layar.judul,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.15,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sedang),
                    Text(
                      layar.isi,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontFamily: 'Nunito',
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
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

  /// Judul besar Baloo 2 diperbesar sekitar 1,3x (~28px) dengan SATU frasa diberi
  /// efek stabilo kuning pita sejajar sekitar 40% bagian bawah tinggi huruf.
  Widget _buildJudulBerstabilo(
    BuildContext context, {
    required String teksSebelum,
    required String teksStabilo,
    String? teksSetelah,
  }) {
    const double ukuranJudul = 28.0;
    const double tinggiPita = ukuranJudul * 0.40;

    final TextStyle gayaJudul =
        (Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontFamily: 'Baloo2')).copyWith(
          fontSize: ukuranJudul,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          height: 1.15,
        );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (teksSebelum.isNotEmpty) ...[
            Text(
              teksSebelum,
              style: gayaJudul,
            ),
            const SizedBox(width: 6),
          ],
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 2.0,
                left: 0.0,
                right: 0.0,
                height: tinggiPita,
                child: Container(color: AppColors.stabilo),
              ),
              Text(
                teksStabilo,
                style: gayaJudul,
              ),
            ],
          ),
          if (teksSetelah != null && teksSetelah.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              teksSetelah,
              style: gayaJudul,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLayarTarget(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final bool memuat = state is OnboardingLoading;

        return Column(
          children: [
            // Isi layar di atas: scrollable saat keyboard muncul
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.besar,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxWidth: AppSizes.batasLebarKonten,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: AppSpacing.besar),
                            // Lingkaran ikon kuning seperti slide
                            Container(
                              width: 96,
                              height: 96,
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
                                size: 56,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sedang),

                            // Label kecil kapital "LANGKAH TERAKHIR" (gaya badge yang sama dengan slide)
                            _buildLabelBadge(context, 'LANGKAH TERAKHIR'),
                            const SizedBox(height: AppSpacing.agakKecil),

                            // Judul "Tentukan Target Bulanan" dengan stabilo pada "Bulanan" (pakai _buildJudulBerstabilo yang sama)
                            _buildJudulBerstabilo(
                              context,
                              teksSebelum: 'Tentukan Target',
                              teksStabilo: 'Bulanan',
                            ),
                            const SizedBox(height: AppSpacing.sedang),

                            // Kalimat kecil
                            Text(
                              'Berapa batas maksimal pengeluaranmu dalam sebulan? Tidak harus pas, cukup perkiraan kasar dulu.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.lebihBesar),

                            // Kolom nominal memakai ulang KolomInputNominal dari Catat
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sedang,
                                vertical: AppSpacing.kecil,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusTombol,
                                ),
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: AppSizes.border,
                                ),
                                boxShadow: const [AppTheme.bayanganKecilGelap],
                              ),
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
                              const SizedBox(height: AppSpacing.agakKecil),
                              Text(
                                _pesanGalat!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.salah,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.besar),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Tombol bawah: "Nanti saja" tepat di atas "Simpan Target"
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.besar,
                vertical: AppSpacing.sedang,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.batasLebarKonten,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: TextButton(
                          key: const Key('tombol_nanti_saja'),
                          onPressed:
                              memuat ? null : () => _lewatiTarget(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.inkSoft,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sedang,
                              vertical: AppSpacing.kecil,
                            ),
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
                      const SizedBox(height: AppSpacing.sangatKecil),
                      TombolStabilo(
                        key: const Key('tombol_simpan_target'),
                        teks: 'Simpan Target',
                        isLoading: memuat,
                        ikon: Icons.check_rounded,
                        onPressed: (_targetNominal > 0 && !memuat)
                            ? () => _simpanTarget(context)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Data satu layar sambutan (F-16, ISSUE-33 K3).
class _DataLayarSambutan {
  final String judul;
  final String isi;
  final IconData ikon;
  final Color warnaKotak;
  final Color warnaIkon;

  const _DataLayarSambutan({
    required this.judul,
    required this.isi,
    required this.ikon,
    required this.warnaKotak,
    required this.warnaIkon,
  });
}

const List<_DataLayarSambutan> _layarSambutan = [
  _DataLayarSambutan(
    judul: 'Kenalan dengan Insap',
    isi:
        'Insap mengajakmu sadar ke mana uangmu pergi, ala Kakeibo dari Jepang: catat, lihat, lalu renungkan tiap pekan.',
    ikon: Icons.menu_book,
    warnaKotak: AppColors.ilustrasiJingga,
    warnaIkon: AppColors.kartu,
  ),
  _DataLayarSambutan(
    judul: 'Catat dalam hitungan detik',
    isi: 'Ketuk Catat Cepat, isi nominal, pilih kategori, lalu simpan.',
    ikon: Icons.edit,
    warnaKotak: AppColors.stabilo,
    warnaIkon: AppColors.ink,
  ),
  _DataLayarSambutan(
    judul: 'Biar AI yang baca struknya',
    isi:
        'Foto struk belanjamu. AI membaca tiap barang, kamu cukup periksa lalu simpan.',
    ikon: Icons.photo_camera,
    warnaKotak: AppColors.aiBiru,
    warnaIkon: AppColors.kartu,
  ),
  _DataLayarSambutan(
    judul: 'Tutup pekan dengan refleksi',
    isi:
        'Tiap akhir pekan, lihat ke mana uangmu pergi dan tulis satu hal yang mau diperbaiki.',
    ikon: Icons.lightbulb,
    warnaKotak: AppColors.ilustrasiUngu,
    warnaIkon: AppColors.kartu,
  ),
  _DataLayarSambutan(
    judul: 'Semua catatan ada di Riwayat',
    isi:
        'Cari dan saring catatanmu kapan saja. Masuk akun kalau mau mencadangkan data.',
    ikon: Icons.receipt_long,
    warnaKotak: AppColors.ilustrasiHijau,
    warnaIkon: AppColors.kartu,
  ),
];

/// Tombol "Kembali" putih bergaris ink. Nonaktif (latar garis) saat [onTap]
/// kosong, yaitu di layar pertama.
class _TombolKembaliSambutan extends StatelessWidget {
  final VoidCallback? onTap;

  const _TombolKembaliSambutan({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool aktif = onTap != null;
    return KartuBukuTulis(
      onTap: onTap,
      backgroundColor: aktif ? AppColors.kartu : AppColors.garis,
      shadow: AppTheme.bayanganGelap,
      pressedShadow: AppTheme.bayanganGelapTertekan,
      radius: AppSizes.radiusTombol,
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSizes.tinggiTombol - AppSizes.border * 2,
        ),
        child: Center(
          child: Text(
            'Kembali',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: aktif ? AppColors.ink : AppColors.inkSoft,
                ),
          ),
        ),
      ),
    );
  }
}
