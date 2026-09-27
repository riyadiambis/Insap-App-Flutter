import 'package:flutter/material.dart';
import '../theme.dart';

class BadgeKategori extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final double ukuran;

  const BadgeKategori({
    super.key,
    required this.ikon,
    required this.warna,
    this.ukuran = AppSizes.badgeKategori,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
      ),
      child: Center(
        child: Icon(
          ikon,
          color: AppColors.ikonBadge,
          size: ukuran * 0.6,
        ),
      ),
    );
  }
}
