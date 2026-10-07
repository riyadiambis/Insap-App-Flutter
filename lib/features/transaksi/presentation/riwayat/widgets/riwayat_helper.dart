import 'package:flutter/material.dart';

import '../../../../../core/theme.dart';
import '../../../../kategori/domain/entities/kategori_entity.dart';

/// Helper pemformatan dan konversi data untuk fitur Riwayat Transaksi (F-02).
/// Mengikuti Keputusan H: Nama hari dan bulan memakai daftar lokal
/// tanpa initializeDateFormatting agar tidak mengubah main.dart.
class RiwayatHelper {
  const RiwayatHelper._();

  static const List<String> namaHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> namaBulanSingkat = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ags',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Format judul kelompok tanggal pada daftar riwayat (Hari ini / Kemarin / Tanggal Lengkap)
  static String formatTanggalGrup(String tanggalStr) {
    final dt = DateTime.tryParse(tanggalStr);
    if (dt == null) return tanggalStr;

    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final kemarin = hariIni.subtract(const Duration(days: 1));
    final target = DateTime(dt.year, dt.month, dt.day);

    if (target == hariIni) {
      return 'Hari ini';
    } else if (target == kemarin) {
      return 'Kemarin';
    } else {
      final hari = namaHari[dt.weekday - 1];
      final bulan = namaBulan[dt.month - 1];
      return '$hari, ${dt.day} $bulan ${dt.year}';
    }
  }

  /// Format tanggal lengkap untuk detail transaksi (contoh: "Senin, 28 September 2026")
  static String formatTanggalLengkap(String tanggalStr) {
    final dt = DateTime.tryParse(tanggalStr);
    if (dt == null) return tanggalStr;

    final hari = namaHari[dt.weekday - 1];
    final bulan = namaBulan[dt.month - 1];
    return '$hari, ${dt.day} $bulan ${dt.year}';
  }

  /// Format waktu (HH:mm) dari kolom dibuatPada
  static String formatJam(String? dibuatPada) {
    if (dibuatPada == null || dibuatPada.trim().isEmpty) return '-';

    final dt = DateTime.tryParse(dibuatPada);
    if (dt != null) {
      final jam = dt.hour.toString().padLeft(2, '0');
      final menit = dt.minute.toString().padLeft(2, '0');
      return '$jam:$menit';
    }

    // Fallback jika berupa string manual
    if (dibuatPada.contains('T')) {
      final parts = dibuatPada.split('T');
      if (parts.length > 1 && parts[1].length >= 5) {
        return parts[1].substring(0, 5);
      }
    } else if (dibuatPada.contains(' ')) {
      final parts = dibuatPada.split(' ');
      if (parts.length > 1 && parts[1].length >= 5) {
        return parts[1].substring(0, 5);
      }
    }

    return dibuatPada;
  }

  /// Format rentang tanggal untuk filter (contoh: "01 Sep 2026 sampai 28 Sep 2026")
  static String formatRentangTanggal(DateTimeRange rentang) {
    final tglMulai = rentang.start.day.toString().padLeft(2, '0');
    final blnMulai = namaBulanSingkat[rentang.start.month - 1];
    final thnMulai = rentang.start.year;

    final tglAkhir = rentang.end.day.toString().padLeft(2, '0');
    final blnAkhir = namaBulanSingkat[rentang.end.month - 1];
    final thnAkhir = rentang.end.year;

    return '$tglMulai $blnMulai $thnMulai sampai $tglAkhir $blnAkhir $thnAkhir';
  }

  /// Format objek DateTime ke format database "yyyy-MM-dd"
  static String toIsoDate(DateTime dt) {
    final tahun = dt.year.toString().padLeft(4, '0');
    final bulan = dt.month.toString().padLeft(2, '0');
    final tanggal = dt.day.toString().padLeft(2, '0');
    return '$tahun-$bulan-$tanggal';
  }

  /// Parse warna hex string (#RRGGBB) ke [Color] Flutter
  static Color parseWarna(String? hexColor) {
    if (hexColor == null || hexColor.trim().isEmpty) {
      return AppColors.ink;
    }
    var hex = hexColor.replaceAll('#', '').trim();
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.ink;
    }
  }

  /// Konversi nama ikon teks basis data ke [IconData]
  static IconData parseIkon(String? namaIkon) {
    switch (namaIkon) {
      case 'restaurant':
        return Icons.restaurant;
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'medical_services':
        return Icons.medical_services;
      case 'more_horiz':
      default:
        return Icons.more_horiz;
    }
  }

  /// Mengubah huruf pertama teks menjadi huruf kapital
  static String kapitalPertama(String teks) {
    if (teks.isEmpty) return teks;
    return teks[0].toUpperCase() + teks.substring(1);
  }

  /// Mencari kategori berdasarkan ID dari daftar kategori aktif
  static KategoriEntity? cariKategori(
    List<KategoriEntity> kategoriList,
    int? kategoriId,
  ) {
    if (kategoriId == null) return null;
    try {
      return kategoriList.firstWhere((k) => k.id == kategoriId);
    } catch (_) {
      return null;
    }
  }
}
