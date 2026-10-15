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
                    judulSebelum: 'Sadar Sebelum',
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
                    warnaLatarIkon: AppColors.stabilo,
                    label: 'CATAT',
                    judulSebelum: 'Catat Cepat',
                    judulStabilo: 'Dua Langkah',
                    isi: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        KotakLangkah(
                          nomor: 1,
                          teksUtama: 'Isi nominal',
                          keterangan: 'Contoh Rp15.000',
                        ),
                        SizedBox(height: 10),
                        KotakLangkah(
                          nomor: 2,
                          teksUtama: 'Pilih kategori',
                          keterangan:
                              'Makan, transport, nongkrong, dan lainnya',
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
                    judulSebelum: 'Refleksi',
                    judulStabilo: 'Mingguan',
                    isi: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const KotakLangkah(
                          nomor: 1,
                          teksUtama: 'Lihat ulang',
                          keterangan: 'Pengeluaran sepekan terakhir',
                        ),
                        const SizedBox(height: 10),
                        const KotakLangkah(
                          nomor: 2,
                          teksUtama: 'Butuh atau pengen?',
                          keterangan:
                              'Tandai belanja yang sebenarnya bisa ditahan',
                        ),
                        const SizedBox(height: 10),
                        const KotakLangkah(
                          nomor: 3,
                          teksUtama: 'Tetapkan target',
                          keterangan: 'Batas pengeluaran untuk pekan depan',
                        ),
                        const SizedBox(height: AppSpacing.kecil),
                        Text(
                          'Santai, tanpa menghakimi.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.inkSoft,
                                    fontSize: 12,
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
                vertical: AppSpacing.sedang,
              ),
              child: LayoutBuilder(
                builder: (context, cardConstraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: cardConstraints.maxHeight,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                size: 56,
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
                            const SizedBox(height: AppSpacing.sedang),

                            // 3. Isi (teks Layar 1 atau kotak langkah Layar 2 & 3)
                            isi,
                          ],
                        ),
                      ),
                    ),
                  );
                },
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

/// Kotak langkah untuk layar perkenalan (F-16, P02-Widget).
/// Menampilkan kotak selebar penuh kartu dengan latar krem kertas (AppColors.paper),
/// garis tipis tinta tema, sudut membulat, lingkaran nomor di kiri, teks utama tebal,
/// dan keterangan kecil abu-abu di baris bawah.
class KotakLangkah extends StatelessWidget {
  final int nomor;
  final String teksUtama;
  final String keterangan;

  const KotakLangkah({
    super.key,
    required this.nomor,
    required this.teksUtama,
    required this.keterangan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sedang,
        vertical: AppSpacing.kecil,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonAksi),
        border: Border.all(
          color: AppColors.ink,
          width: AppSizes.borderTipis,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Lingkaran nomor di kiri
          Container(
            width: 24,
            height: 24,
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
                fontSize: 13,
                color: AppColors.ink,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sedang),

          // Di kanannya: baris atas teks utama (tebal), baris bawah keterangan kecil abu-abu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  teksUtama,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  keterangan,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
