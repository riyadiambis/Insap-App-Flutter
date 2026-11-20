import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../di/injection_container.dart';
import '../theme.dart';
import '../tur/tur_cubit.dart';

/// Data satu orang yang tampil di kartu Tentang Aplikasi.
class AnggotaTim {
  final String peran;
  final String nama;

  const AnggotaTim({required this.peran, required this.nama});

  /// Dua huruf depan untuk lingkaran inisial, misal "Rahmat Riyadi" jadi "RR".
  String get inisial {
    final kata = nama.split(' ').where((k) => k.isNotEmpty).toList();
    if (kata.isEmpty) return '?';
    if (kata.length == 1) return kata.first[0].toUpperCase();
    return (kata[0][0] + kata[1][0]).toUpperCase();
  }
}

/// Anggota tim pengembang Insap, urut sesuai pembagian tim di PRD.md.
const List<AnggotaTim> daftarTimPengembang = [
  AnggotaTim(nama: 'Rahmat Riyadi', peran: 'Ketua Tim · Fondasi & Akun'),
  AnggotaTim(nama: 'Muh Ghazy Daffa Sampe', peran: 'Riwayat & Pindai Struk'),
  AnggotaTim(nama: 'Luthfi Farros Athailah', peran: 'Kategori & Refleksi'),
];

/// Dosen pembimbing tugas akhir Pemrograman Piranti Bergerak.
const List<AnggotaTim> daftarDosenPembimbing = [
  AnggotaTim(nama: 'Anton Prafanto, S.Kom., MT', peran: 'Dosen Pembimbing I'),
  AnggotaTim(
    nama: 'Gubtha Mahendra Putra, S.Kom., M.Eng.',
    peran: 'Dosen Pembimbing II',
  ),
];

const String namaProdi = 'Program Studi Informatika';
const String namaFakultas = 'Fakultas Teknik';
const String namaKampus = 'Universitas Mulawarman';

/// Konten identitas aplikasi, tim, dosen, dan kampus sesuai `Tentang.dc.html`.
class KartuTentangAplikasi extends StatelessWidget {
  const KartuTentangAplikasi({super.key});

  void _tampilkanInfo(BuildContext context, String judul, String isi) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kartu,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
          side: const BorderSide(color: AppColors.ink, width: AppSizes.border),
        ),
        title: Text(
          judul,
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          isi,
          style: Theme.of(
            ctx,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.ink, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/images/logo_insap.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 6),
              Text(
                'Insap: Catat Keuangan',
                textAlign: TextAlign.center,
                style: teks.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.kartu,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.border,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                ),
                child: Text(
                  'Versi 2.1.0',
                  style: teks.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppTheme.kartuDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIM PENGEMBANG',
                style: teks.labelSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                daftarTimPengembang.map((e) => e.nama).join('\n'),
                style: teks.bodyMedium?.copyWith(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppTheme.kartuDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DOSEN PENGAMPU',
                style: teks.labelSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                daftarDosenPembimbing.map((e) => e.nama).join('\n'),
                style: teks.bodyMedium?.copyWith(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '$namaProdi, $namaFakultas\n$namaKampus',
          textAlign: TextAlign.center,
          style: teks.bodyMedium?.copyWith(
            fontSize: 14,
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            TextButton(
              onPressed: () => _tampilkanInfo(
                context,
                'Kebijakan privasi',
                'Catatan keuangan disimpan secara lokal di perangkatmu. Foto struk yang dipindai hanya dikirim ke Google Gemini untuk dibaca dan tidak disimpan oleh Insap.',
              ),
              child: const Text(
                'Kebijakan privasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _tampilkanInfo(
                context,
                'Lisensi',
                'Insap menggunakan font Baloo 2 dan Nunito di bawah SIL Open Font License, serta paket sumber terbuka Flutter.',
              ),
              child: const Text(
                'Lisensi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        if (sl.isRegistered<TurCubit>()) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              key: const Key('tombol_lihat_petunjuk'),
              onPressed: () {
                sl<TurCubit>().mulaiUlang();
                context.go('/');
              },
              icon: const Icon(Icons.help_outline, color: AppColors.ink),
              label: Text(
                'Lihat petunjuk lagi',
                style: teks.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tombol ke halaman Tentang Aplikasi (/tentang). Dipakai di halaman Akun
/// dan halaman Masuk sebagai pengganti kartu panjang (ISSUE-38).
class TombolTentangAplikasi extends StatelessWidget {
  const TombolTentangAplikasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tentang Aplikasi',
      child: GestureDetector(
        key: const Key('tombol_tentang'),
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/tentang'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.kartu,
              border: Border.all(color: AppColors.ink, width: AppSizes.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
              boxShadow: const [AppTheme.bayanganKecilGelap],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.kecil),
                Text(
                  'Tentang Aplikasi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
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
