import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/header_aplikasi.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../cubit/akun_cubit.dart';
import '../cubit/akun_state.dart';

class HalamanMasuk extends StatelessWidget {
  final bool modeOnboarding;
  final VoidCallback? onKembali;
  final VoidCallback? onLanjutTanpaAkun;
  final VoidCallback? onLoginSukses;

  const HalamanMasuk({
    super.key,
    this.modeOnboarding = false,
    this.onKembali,
    this.onLanjutTanpaAkun,
    this.onLoginSukses,
  });

  void _tutupLayar(BuildContext context) {
    if (onLanjutTanpaAkun != null) {
      onLanjutTanpaAkun!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    AkunCubit? akunCubit;
    try {
      akunCubit = context.read<AkunCubit>();
    } catch (_) {
      akunCubit = null;
    }

    return Scaffold(
      appBar: HeaderAplikasi(
        namaLayar: 'Masuk',
        modeKembali: true,
        onKembali: onKembali,
      ),
      body: PaperBackground(
        child: akunCubit == null
            ? _bangunKonten(context, sedangMemuat: false, cubit: null)
            : BlocConsumer<AkunCubit, AkunState>(
                listener: (context, state) {
                  if (state is AkunMasuk) {
                    onLoginSukses?.call();
                  } else if (state is AkunGalat) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.pesan),
                        backgroundColor: AppColors.salah,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (state is AkunPesanSukses) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.pesan),
                        backgroundColor: AppColors.benar,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return _bangunKonten(
                    context,
                    sedangMemuat: state is AkunMemuat,
                    cubit: context.read<AkunCubit>(),
                  );
                },
              ),
      ),
    );
  }

  Widget _bangunKonten(
    BuildContext context, {
    required bool sedangMemuat,
    required AkunCubit? cubit,
  }) {
    final teks = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.batasLebarKonten,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.besar),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          ExcludeSemantics(
                            child: Image.asset(
                              'assets/images/logo_insap.png',
                              width: 56,
                              height: 56,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            modeOnboarding ? 'LANGKAH 3 DARI 3' : 'CADANGAN AWAN',
                            style: teks.labelSmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Simpan catatan di awan',
                        style: teks.headlineMedium?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Masuk supaya catatanmu aman saat ganti HP. Tanpa akun pun Insap tetap jalan, data tersimpan di HP ini.',
                        style: teks.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      KartuBukuTulis(
                        shadow: AppTheme.bayanganGelap,
                        pressedShadow: AppTheme.bayanganGelapTertekan,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BarisManfaatMasuk(
                              ikon: Icons.cloud_outlined,
                              teks: 'Cadangan transaksi ke awan',
                            ),
                            SizedBox(height: 10),
                            _BarisManfaatMasuk(
                              ikon: Icons.image_outlined,
                              teks: 'Kategori dan refleksi ikut tersimpan',
                            ),
                            SizedBox(height: 10),
                            _BarisManfaatMasuk(
                              ikon: Icons.delete_outline_rounded,
                              teks: 'Bisa dihapus kapan saja',
                            ),
                          ],
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TombolGoogleMasuk(
                      key: const Key('tombol_masuk_google'),
                      sedangMemuat: sedangMemuat,
                      onPressed: (sedangMemuat || cubit == null)
                          ? null
                          : () => cubit.masukDenganGoogle(),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      key: const Key('tombol_lanjut_tanpa_akun'),
                      onPressed: sedangMemuat
                          ? null
                          : () => _tutupLayar(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text(
                        'Lanjut tanpa akun',
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
          ),
        ),
      ),
    );
  }
}

class _BarisManfaatMasuk extends StatelessWidget {
  final IconData ikon;
  final String teks;

  const _BarisManfaatMasuk({required this.ikon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.hijauMuda,
            border: Border.all(color: AppColors.ink, width: AppSizes.border),
            borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
          ),
          child: Icon(ikon, size: 18, color: AppColors.ink),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            teks,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.4,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _TombolGoogleMasuk extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool sedangMemuat;

  const _TombolGoogleMasuk({
    super.key,
    this.onPressed,
    this.sedangMemuat = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Masuk dengan Google',
      enabled: onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.kartu,
              border: Border.all(color: AppColors.ink, width: AppSizes.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
              boxShadow: const [AppTheme.bayanganTombolGelap],
            ),
            child: sedangMemuat
                ? const Center(
                    child: SizedBox(
                      width: AppSizes.indikatorMuat,
                      height: AppSizes.indikatorMuat,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.tebalIndikatorMuat,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.ink,
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ExcludeSemantics(
                        child: CustomPaint(
                          size: Size(20, 20),
                          painter: _GoogleLogoPainter(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.kecil),
                      Text(
                        'Masuk dengan Google',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Menggambar logo "G" Google 4 warna sesuai acuan `Masuk.dc.html`.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48.0;
    canvas.scale(s, s);

    final merah = Paint()..color = const Color(0xFFEA4335);
    final biru = Paint()..color = const Color(0xFF4285F4);
    final kuning = Paint()..color = const Color(0xFFFBBC05);
    final hijau = Paint()..color = const Color(0xFF34A853);

    // Merah (lengkung atas)
    final pMerah = Path()
      ..moveTo(24, 9.5)
      ..cubicTo(27.5, 9.5, 30.6, 10.7, 33, 13)
      ..lineTo(39.7, 6.3)
      ..cubicTo(35.6, 2.4, 30.2, 0, 24, 0)
      ..cubicTo(14.6, 0, 6.6, 5.4, 2.7, 13.2)
      ..lineTo(10.5, 19.2)
      ..cubicTo(12.4, 13.5, 17.7, 9.5, 24, 9.5)
      ..close();
    canvas.drawPath(pMerah, merah);

    // Biru (palang kanan)
    final pBiru = Path()
      ..moveTo(46.1, 24.5)
      ..cubicTo(46.1, 22.9, 46, 21.4, 45.7, 20)
      ..lineTo(24, 20)
      ..lineTo(24, 29)
      ..lineTo(36.4, 29)
      ..cubicTo(35.9, 31.9, 34.2, 34.3, 31.8, 36)
      ..lineTo(39.2, 41.7)
      ..cubicTo(43.5, 37.7, 46.1, 31.8, 46.1, 24.5)
      ..close();
    canvas.drawPath(pBiru, biru);

    // Kuning (lengkung kiri)
    final pKuning = Path()
      ..moveTo(10.5, 28.8)
      ..cubicTo(9.8, 27.3, 9.5, 25.7, 9.5, 24)
      ..cubicTo(9.5, 22.3, 9.8, 20.7, 10.4, 19.2)
      ..lineTo(2.6, 13.2)
      ..cubicTo(0.9, 16.5, 0, 20.1, 0, 24)
      ..cubicTo(0, 27.9, 0.9, 31.5, 2.6, 34.8)
      ..lineTo(10.5, 28.8)
      ..close();
    canvas.drawPath(pKuning, kuning);

    // Hijau (lengkung bawah)
    final pHijau = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.5, 48, 35.9, 45.9, 39.9, 42.2)
      ..lineTo(32.5, 36.5)
      ..cubicTo(30.4, 37.9, 27.7, 38.8, 24, 38.8)
      ..cubicTo(17.7, 38.8, 12.4, 34.8, 10.5, 29.2)
      ..lineTo(2.6, 35.2)
      ..cubicTo(6.6, 42.6, 14.6, 48, 24, 48)
      ..close();
    canvas.drawPath(pHijau, hijau);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
