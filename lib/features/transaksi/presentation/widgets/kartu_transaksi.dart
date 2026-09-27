import 'package:flutter/material.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/badge_kategori.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';

class KartuTransaksi extends StatelessWidget {
  final int nominal;
  final String namaKategori;
  final String? catatan;
  final String waktu;
  final IconData ikonKategori;
  final Color warnaKategori;
  final VoidCallback? onTap;

  const KartuTransaksi({
    super.key,
    required this.nominal,
    required this.namaKategori,
    this.catatan,
    required this.waktu,
    required this.ikonKategori,
    required this.warnaKategori,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KartuBukuTulis(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          BadgeKategori(
            ikon: ikonKategori,
            warna: warnaKategori,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaKategori,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (catatan != null && catatan!.isNotEmpty)
                  Text(
                    catatan!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                nominal.toRupiah(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                waktu,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
