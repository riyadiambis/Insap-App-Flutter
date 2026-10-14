import 'package:flutter/material.dart';

import '../theme.dart';

/// Avatar profil pengguna sesuai gaya Buku Tulis.
///
/// Menampilkan foto profil dari [fotoUrl] jika tersedia via [Image.network].
/// Jika [fotoUrl] bernilai null, kosong, atau gagal dimuat (misal karena luring),
/// widget otomatis jatuh (fallback) ke ikon [Icons.person] bawaan.
class AvatarProfil extends StatelessWidget {
  final String? fotoUrl;
  final double ukuran;
  final double ukuranIkon;
  final Color warnaLatar;
  final Color warnaIkon;
  final List<BoxShadow>? bayangan;

  const AvatarProfil({
    super.key,
    this.fotoUrl,
    required this.ukuran,
    required this.ukuranIkon,
    required this.warnaLatar,
    required this.warnaIkon,
    this.bayangan,
  });

  @override
  Widget build(BuildContext context) {
    final adaFoto = fotoUrl != null && fotoUrl!.trim().isNotEmpty;
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: warnaLatar,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: AppSizes.border),
        boxShadow: bayangan,
      ),
      child: adaFoto
          ? ClipOval(
              child: Image.network(
                fotoUrl!,
                width: ukuran,
                height: ukuran,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, size: ukuranIkon, color: warnaIkon),
              ),
            )
          : Icon(Icons.person, size: ukuranIkon, color: warnaIkon),
    );
  }
}
