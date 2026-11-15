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

/// Kartu identitas aplikasi, tim, dosen, dan kampus.
/// Ditaruh di bagian bawah HalamanAkun dan HalamanMasuk sesuai keputusan ISSUE-20.
class KartuTentangAplikasi extends StatelessWidget {
  const KartuTentangAplikasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.kartu,
        border: Border.all(color: AppColors.ink, width: AppSizes.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
        boxShadow: const [AppTheme.bayanganDefault],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _KepalaKartu(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.besar),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aplikasi pencatat pengeluaran harian mahasiswa dengan prinsip Kakeibo agar sadar dan kendalikan boncos.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.besar),
                const _JudulBagian(teks: 'TIM PENGEMBANG'),
                const SizedBox(height: AppSpacing.kecil),
                for (var i = 0; i < daftarTimPengembang.length; i++)
                  _BarisOrang(
                    orang: daftarTimPengembang[i],
                    warna: AppColors.paletBadgeKategori[i],
                  ),
                const SizedBox(height: AppSpacing.sedang),
                const _JudulBagian(teks: 'DOSEN PEMBIMBING'),
                const SizedBox(height: AppSpacing.kecil),
                for (final dosen in daftarDosenPembimbing)
                  _BarisOrang(orang: dosen, warna: AppColors.ink),
                const SizedBox(height: AppSpacing.sedang),
                const _KotakKampus(),
                // putar ulang petunjuk sorotan layar utama (ISSUE-37)
                if (sl.isRegistered<TurCubit>()) ...[
                  const SizedBox(height: AppSpacing.kecil),
                  TextButton.icon(
                    key: const Key('tombol_lihat_petunjuk'),
                    onPressed: () {
                      sl<TurCubit>().mulaiUlang();
                      context.go('/');
                    },
                    icon: const Icon(Icons.help_outline, color: AppColors.ink),
                    label: Text(
                      'Lihat petunjuk lagi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pita biru di atas kartu: logo, nama aplikasi, tagline, dan versi.
class _KepalaKartu extends StatelessWidget {
  const _KepalaKartu();

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.all(AppSpacing.besar),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Image.asset(
              'assets/images/logo_insap.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: AppSpacing.sedang),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insap: Yuk Sadar Boncos',
                  style: teks.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.kartu,
                  ),
                ),
                const SizedBox(height: AppSpacing.sangatKecil),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.kecil,
                    vertical: AppSpacing.mini,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.stabilo,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                  ),
                  child: Text(
                    'Versi 1.0.1',
                    style: teks.labelSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
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

class _JudulBagian extends StatelessWidget {
  final String teks;

  const _JudulBagian({required this.teks});

  @override
  Widget build(BuildContext context) {
    return Text(
      teks,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.inkSoft,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        fontSize: 11,
      ),
    );
  }
}

/// Satu baris orang: lingkaran inisial berwarna, nama, dan peran.
class _BarisOrang extends StatelessWidget {
  final AnggotaTim orang;
  final Color warna;

  const _BarisOrang({required this.orang, required this.warna});

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sangatKecil),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: warna,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: AppSizes.border),
            ),
            child: Text(
              orang.inisial,
              style: teks.labelMedium?.copyWith(
                color: AppColors.kartu,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sedang),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orang.nama,
                  style: teks.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  orang.peran,
                  style: teks.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
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

/// Kotak kuning berisi prodi, fakultas, dan kampus.
class _KotakKampus extends StatelessWidget {
  const _KotakKampus();

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sedang),
      decoration: BoxDecoration(
        color: AppColors.stabilo,
        border: Border.all(color: AppColors.ink, width: AppSizes.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
        boxShadow: const [AppTheme.bayanganKecilGelap],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            namaProdi,
            style: teks.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '$namaFakultas · $namaKampus',
            style: teks.bodySmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol ke halaman Tentang Aplikasi (/tentang). Dipakai di halaman Akun
/// dan halaman Masuk sebagai pengganti kartu panjang (ISSUE-38).
class TombolTentangAplikasi extends StatelessWidget {
  const TombolTentangAplikasi({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('tombol_tentang'),
      onPressed: () => context.push('/tentang'),
      icon: const Icon(Icons.info_outline, color: AppColors.ink, size: 20),
      label: Text(
        'Tentang Aplikasi',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.kartu,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sedang),
        side: const BorderSide(color: AppColors.ink, width: AppSizes.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
        ),
      ),
    );
  }
}
