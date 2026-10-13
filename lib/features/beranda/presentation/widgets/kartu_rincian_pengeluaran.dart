import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/badge_kategori.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../kategori/domain/entities/kategori_entity.dart';
import '../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../kategori/presentation/cubit/kategori_state.dart';
import '../../../transaksi/domain/entities/rincian_pengeluaran_entity.dart';
import '../../../transaksi/domain/entities/total_kategori_entity.dart';
import 'tampilan_kategori.dart';

enum _PeriodeRincian { pekan, bulan }

class KartuRincianPengeluaran extends StatefulWidget {
  final int totalPekanIni;
  final RincianPengeluaranEntity rincian;

  const KartuRincianPengeluaran({
    super.key,
    required this.totalPekanIni,
    required this.rincian,
  });

  @override
  State<KartuRincianPengeluaran> createState() =>
      _KartuRincianPengeluaranState();
}

class _KartuRincianPengeluaranState extends State<KartuRincianPengeluaran> {
  _PeriodeRincian _periode = _PeriodeRincian.pekan;

  @override
  Widget build(BuildContext context) {
    final bool isPekan = _periode == _PeriodeRincian.pekan;
    final int totalPeriode = isPekan
        ? widget.totalPekanIni
        : widget.rincian.totalBulanIni;
    final List<TotalKategoriEntity> daftarKategori = isPekan
        ? widget.rincian.kategoriPekanIni
        : widget.rincian.kategoriBulanIni;

    return KartuBukuTulis(
      radius: AppSizes.radiusTombol,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // baris 1: label seksi mandiri
          Text(
            'RINCIAN PENGELUARAN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sedang),

          // baris 2: dua tombol pil rata kiri
          Row(
            children: [
              _TombolPilPeriode(
                key: const Key('pilih_periode_pekan'),
                label: 'Pekan ini',
                aktif: isPekan,
                onPressed: isPekan
                    ? null
                    : () {
                        setState(() {
                          _periode = _PeriodeRincian.pekan;
                        });
                      },
              ),
              const SizedBox(width: AppSpacing.kecil),
              _TombolPilPeriode(
                key: const Key('pilih_periode_bulan'),
                label: 'Bulan ini',
                aktif: !isPekan,
                onPressed: !isPekan
                    ? null
                    : () {
                        setState(() {
                          _periode = _PeriodeRincian.bulan;
                        });
                      },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sedang),

          // baris 3: satu baris kecil teks keterangan dan nominal
          Row(
            children: [
              Text(
                isPekan ? 'Total pekan ini' : 'Total bulan ini',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(width: AppSpacing.agakKecil),
              Text(
                totalPeriode.toRupiah(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sedang),
          Container(
            height: AppSizes.tinggiGarisPemisah,
            color: AppColors.garis,
          ),
          const SizedBox(height: AppSpacing.sedang),

          // konten rincian atau tampilan kosong
          if (totalPeriode == 0 || daftarKategori.isEmpty)
            Container(
              key: const Key('rincian_kosong'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPekan
                        ? 'Belum ada pengeluaran pekan ini.'
                        : 'Belum ada pengeluaran bulan ini.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sangatKecil),
                  Text(
                    'Catat pengeluaran pertamamu, rinciannya muncul di sini.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            )
          else
            ...daftarKategori.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < daftarKategori.length - 1
                      ? AppSpacing.sedang
                      : 0,
                ),
                child: _BarisKategori(item: item, totalPeriode: totalPeriode),
              );
            }),
        ],
      ),
    );
  }
}

class _BarisKategori extends StatelessWidget {
  final TotalKategoriEntity item;
  final int totalPeriode;

  const _BarisKategori({required this.item, required this.totalPeriode});

  @override
  Widget build(BuildContext context) {
    // membaca state KategoriCubit secara reaktif dengan context.watch (Modul 5 Provider)
    final kategoriState = context.watch<KategoriCubit>().state;
    KategoriEntity? kategori;
    if (kategoriState is KategoriLoaded) {
      for (final k in kategoriState.kategoriList) {
        if (k.id == item.kategoriId) {
          kategori = k;
          break;
        }
      }
    }

    final namaKategori = kategori != null
        ? kapitalPertama(kategori.nama)
        : 'Tidak diketahui';
    final ikon = kategori != null
        ? parseIkonKategori(kategori.ikon)
        : Icons.more_horiz;
    final warna = kategori != null
        ? parseWarnaKategori(kategori.warna)
        : AppColors.inkSoft;

    final double porsi = totalPeriode > 0 ? item.total / totalPeriode : 0.0;
    final int persen = (porsi * 100).round();

    return Row(
      children: [
        BadgeKategori(
          ikon: ikon,
          warna: warna,
          ukuran: AppSizes.badgeKategoriKecil,
        ),
        const SizedBox(width: AppSpacing.sedang),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      namaKategori,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.kecil),
                  Text(
                    item.total.toRupiah(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.agakKecil),
                  Text(
                    '$persen%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.agakKecil),
              Container(
                height: AppSizes.tinggiBatangPorsi,
                decoration: BoxDecoration(
                  color: AppColors.grid,
                  borderRadius: BorderRadius.circular(
                    AppSizes.radiusBatangPorsi,
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: porsi.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: warna,
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusBatangPorsi,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// tombol pil periode dengan dukungan onPressed null saat aktif (Modul 4)
class _TombolPilPeriode extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback? onPressed;

  const _TombolPilPeriode({
    super.key,
    required this.label,
    required this.aktif,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sedang,
          vertical: AppSpacing.agakKecil,
        ),
        decoration: BoxDecoration(
          color: aktif ? AppColors.stabilo : AppColors.kartu,
          border: Border.all(color: AppColors.ink, width: AppSizes.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusPil),
          boxShadow: [
            aktif ? AppTheme.bayanganKecilGelap : AppTheme.bayanganKecil,
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.ink,
            fontWeight: aktif ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
