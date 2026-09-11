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
        titleLarge: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.nunito(
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
          letterSpacing: 1.2,
        ),
        labelMedium: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        labelSmall: GoogleFonts.nunito(
          color: AppColors.inkSoft,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

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
