import 'package:flutter/material.dart';

/// Mengubah string heksadesimal warna (misal '#FF5722') menjadi objek [Color].
Color parseWarnaKategori(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse(hexColor, radix: 16));
}

/// Memetakan nama ikon kategori dari basis data ke [IconData].
IconData parseIkonKategori(String namaIkon) {
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

/// Mengubah huruf pertama teks menjadi huruf kapital.
String kapitalPertama(String teks) {
  if (teks.isEmpty) return teks;
  return teks[0].toUpperCase() + teks.substring(1);
}
