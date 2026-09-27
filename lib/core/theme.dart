import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color paper = Color(0xFFFFFDF4);
  static const Color grid = Color(0xFFD9E6F2);
  static const Color ink = Color(0xFF1B3A5C);
  static const Color inkSoft = Color(0xFF5B7793);
  static const Color kartu = Color(0xFFFFFFFF);
  static const Color garis = Color(0xFFC8D8E8);
  static const Color stabilo = Color(0xFFFFD84D);
  static const Color benarLatar = Color(0xFFE4F6EA);
  static const Color benar = Color(0xFF1F9254);
  static const Color salahLatar = Color(0xFFFCEAE6);
  static const Color salah = Color(0xFFD9482F);

  /// Palet badge kategori, dipakai sebagai cadangan dan acuan warna saat
  /// pengguna membuat kategori sendiri. Warna kategori yang sesungguhnya
  /// dibaca dari kolom `warna` di basis data.
  static const List<Color> paletBadgeKategori = [
    Color(0xFFE8734A),
    Color(0xFF4A9BE8),
    Color(0xFF8B5FBF),
    Color(0xFF2FA88B),
    Color(0xFFFFB020),
    Color(0xFFD9482F),
    Color(0xFF5B7793),
    Color(0xFF1F9254),
  ];

  // ikon putih di atas badge kategori (UI-GUIDE), sama dengan warna kartu
  static const Color ikonBadge = kartu;
}

class AppSizes {
  static const double badgeKategori = 46.0;
  static const double radiusBadge = 12.0;
  static const double radiusTombol = 14.0;
  static const double tinggiTombol = 56.0;
  static const double radiusKartu = 16.0;
  static const double border = 2.0;
  static const double batasLebarKonten = 460.0;

  // jarak geser kartu/tombol pas ditekan, = selisih offset bayangan
  // normal (4) dan tertekan (2)
  static const double geserTekan = 2.0;

  static const double indikatorMuat = 24.0;
  static const double tebalIndikatorMuat = 3.0;
}

class AppSpacing {
  static const double kecil = 8.0;
  static const double sedang = 12.0;
  static const double besar = 16.0;
}

class AppDurations {
  static const Duration animasiTekan = Duration(milliseconds: 80);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ink,
        surface: AppColors.kartu,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.baloo2(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.baloo2(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: GoogleFonts.baloo2(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.baloo2(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.baloo2(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.baloo2(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.baloo2(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.baloo2(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.baloo2(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.nunito(
          color: AppColors.inkSoft,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
        labelMedium: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
        labelSmall: GoogleFonts.nunito(
          color: AppColors.inkSoft,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Gaya untuk nominal Rupiah besar (F-06), Baloo 2 bobot 800 sesuai
  /// `UI-GUIDE.md`.
  static TextStyle get nominalBesar => GoogleFonts.baloo2(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      );

  /// Bayangan offset solid bawaan, dipakai pada kartu dan komponen netral.
  static const BoxShadow bayanganDefault = BoxShadow(
    color: AppColors.garis,
    offset: Offset(4, 4),
    blurRadius: 0,
  );

  /// Versi "tertekan" dari [bayanganDefault], kartu bergeser ke arah
  /// bayangan saat ditekan.
  static const BoxShadow bayanganDefaultTertekan = BoxShadow(
    color: AppColors.garis,
    offset: Offset(2, 2),
    blurRadius: 0,
  );

  /// Bayangan gelap, dipakai untuk tombol utama bergaya stabilo.
  static const BoxShadow bayanganGelap = BoxShadow(
    color: AppColors.ink,
    offset: Offset(4, 4),
    blurRadius: 0,
  );

  /// Versi "tertekan" dari [bayanganGelap].
  static const BoxShadow bayanganGelapTertekan = BoxShadow(
    color: AppColors.ink,
    offset: Offset(2, 2),
    blurRadius: 0,
  );

  /// Bayangan ke atas, dipakai untuk batas atas navigasi bawah.
  static const BoxShadow bayanganAtas = BoxShadow(
    color: AppColors.garis,
    offset: Offset(0, -4),
    blurRadius: 0,
  );

  /// Versi "tertekan" dari [bayanganAtas], bayangan mengecil ke arah yang
  /// sama (ke atas).
  static const BoxShadow bayanganAtasTertekan = BoxShadow(
    color: AppColors.garis,
    offset: Offset(0, -2),
    blurRadius: 0,
  );

  static BoxDecoration kartuDecoration({double radius = 16.0}) {
    return BoxDecoration(
      color: AppColors.kartu,
      border: Border.all(color: AppColors.ink, width: 2.0),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: AppColors.garis,
          offset: Offset(4, 4),
          blurRadius: 0,
        ),
      ],
    );
  }
}
