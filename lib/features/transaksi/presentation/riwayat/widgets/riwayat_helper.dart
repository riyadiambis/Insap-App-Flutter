import 'package:flutter/material.dart';

import '../../../../kategori/domain/entities/kategori_entity.dart';

// Helper pembantu tampilan riwayat dan detail (format tanggal Indonesia & ikon)
class RiwayatHelper {
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
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static Color parseWarna(String hexColor) {
    var hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF1B3A5C);
    }
  }

  static IconData parseIkon(String namaIkon) {
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

  // Mengubah DateTime ke yyyy-MM-dd
  static String formatYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Format header kelompok tanggal: "Hari ini", "Kemarin", atau "Senin, 28 September 2026"
  static String formatHeaderTanggal(String tanggalYmd) {
    try {
      final parts = tanggalYmd.split('-');
      if (parts.length != 3) return tanggalYmd;
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      final sekarang = DateTime.now();
      final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
      final kemarin = hariIni.subtract(const Duration(days: 1));

      if (dt == hariIni) {
        return 'Hari ini';
      }
      if (dt == kemarin) {
        return 'Kemarin';
      }

      final namaHariIni = namaHari[dt.weekday - 1];
      final bulan = namaBulan[dt.month - 1];
      return '$namaHariIni, ${dt.day} $bulan ${dt.year}';
    } catch (_) {
      return tanggalYmd;
    }
  }

  // Format tanggal lengkap: "28 September 2026"
  static String formatTanggalLengkap(String tanggalYmd) {
    try {
      final parts = tanggalYmd.split('-');
      if (parts.length != 3) return tanggalYmd;
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final bulan = namaBulan[dt.month - 1];
      return '${dt.day} $bulan ${dt.year}';
    } catch (_) {
      return tanggalYmd;
    }
  }

  // Format tanggal singkat: "28 Sep 2026"
  static String formatTanggalSingkat(String tanggalYmd) {
    try {
      final parts = tanggalYmd.split('-');
      if (parts.length != 3) return tanggalYmd;
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final bulan = namaBulanSingkat[dt.month - 1];
      return '${dt.day.toString().padLeft(2, '0')} $bulan ${dt.year}';
    } catch (_) {
      return tanggalYmd;
    }
  }

  // Format rentang tanggal: "01 Sep 2026 sampai 28 Sep 2026"
  static String formatRentangTanggal(String mulaiYmd, String akhirYmd) {
    return '${formatTanggalSingkat(mulaiYmd)} sampai ${formatTanggalSingkat(akhirYmd)}';
  }

  // Format waktu jam dari string ISO dibuatPada: "14:30 WIB"
  static String formatWaktuJam(String dibuatPada) {
    try {
      final dt = DateTime.parse(dibuatPada).toLocal();
      final jam = dt.hour.toString().padLeft(2, '0');
      final menit = dt.minute.toString().padLeft(2, '0');
      return '$jam:$menit WIB';
    } catch (_) {
      return '-';
    }
  }

  // Cari entitas kategori berdasarkan id dari list kategori yang tersedia
  static KategoriEntity? cariKategori(List<KategoriEntity> list, int? id) {
    if (id == null) return null;
    for (final kat in list) {
      if (kat.id == id) return kat;
    }
    return null;
  }
}
