import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/iso_week.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../kategori/domain/entities/kategori_entity.dart';
import '../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../kategori/presentation/cubit/kategori_state.dart';
import '../../../transaksi/domain/entities/transaksi_entity.dart';
import '../../../transaksi/domain/entities/ringkasan_pekan_entity.dart';
import '../../../transaksi/presentation/widgets/kartu_transaksi.dart';
import '../cubit/beranda_cubit.dart';
import '../cubit/beranda_state.dart';

Color _parseWarna(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse(hexColor, radix: 16));
}

IconData _parseIkon(String namaIkon) {
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

String _kapitalPertama(String teks) {
  if (teks.isEmpty) return teks;
  return teks[0].toUpperCase() + teks.substring(1);
}

class HalamanBeranda extends StatelessWidget {
  const HalamanBeranda({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
            child: BlocBuilder<BerandaCubit, BerandaState>(
              builder: (context, state) {
                if (state is BerandaLoading || state is BerandaInitial) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                    ),
                  );
                } else if (state is BerandaError) {
                  return Center(
                    child: Text(
                      'Ups, ada masalah:\n${state.pesan}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                } else if (state is BerandaLoaded) {
                  return _BerandaContent(ringkasan: state.ringkasan);
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BerandaContent extends StatelessWidget {
  final RingkasanPekanEntity ringkasan;

  const _BerandaContent({required this.ringkasan});

  @override
  Widget build(BuildContext context) {
    final pekanIni = isoWeekNumber(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Halo!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Pekan $pekanIni',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        KartuBukuTulis(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.grid,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PEKAN INI',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ringkasan.totalMingguIni.toRupiah(),
                style: AppTheme.nominalBesar.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 12),
              _IndikatorSelisih(selisih: ringkasan.selisihMingguan),
            ],
          ),
        ),
        const SizedBox(height: 16),
        KartuBukuTulis(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sisa kuota pindai struk:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${ringkasan.kuotaPindai}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TombolStabilo(
                teks: 'Catat Cepat',
                onPressed: () => context.go('/catat'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TombolStabilo(
                teks: 'Pindai Struk',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Segera hadir')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 4,
              left: -4,
              right: -4,
              height: 12,
              child: Container(color: AppColors.stabilo),
            ),
            Text(
              'Terakhir',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (ringkasan.transaksiTerakhir.isEmpty)
          KartuBukuTulis(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada transaksi. Yuk catat pengeluaran pertamamu!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else
          ...ringkasan.transaksiTerakhir.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ItemTransaksi(transaksi: t),
              )),
        if (kDebugMode) ...[
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.push('/uji'),
            child: const Text('Buka halaman uji'),
          ),
        ],
      ],
    );
  }
}

class _IndikatorSelisih extends StatelessWidget {
  final int selisih;

  const _IndikatorSelisih({required this.selisih});

  @override
  Widget build(BuildContext context) {
    if (selisih == 0) {
      return Text(
        'Sama persis dengan pekan lalu',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    
    final bool hemat = selisih < 0;
    final nominalAbsolut = selisih.abs().toRupiah();
    final teksStatus = hemat ? 'lebih hemat' : 'lebih boros';
    final warnaLatar = hemat ? AppColors.benarLatar : AppColors.salahLatar;
    final warnaTeks = hemat ? AppColors.benar : AppColors.salah;
    final ikon = hemat ? Icons.arrow_downward : Icons.arrow_upward;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: warnaLatar,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(ikon, size: 14, color: warnaTeks),
              const SizedBox(width: 4),
              Text(
                nominalAbsolut,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: warnaTeks,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$teksStatus dibanding pekan lalu',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ItemTransaksi extends StatelessWidget {
  final TransaksiEntity transaksi;

  const _ItemTransaksi({required this.transaksi});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<KategoriCubit, KategoriState, KategoriEntity?>(
      selector: (state) {
        if (state is KategoriLoaded) {
          for (final k in state.kategoriList) {
            if (k.id == transaksi.kategoriId) return k;
          }
        }
        return null;
      },
      builder: (context, kategori) {
        final namaKategori = kategori != null ? _kapitalPertama(kategori.nama) : 'Tidak diketahui';
        final ikon = kategori != null ? _parseIkon(kategori.ikon) : Icons.help;
        final warna = kategori != null ? _parseWarna(kategori.warna) : AppColors.inkSoft;
        
        String waktu = '';
        try {
          final dt = DateTime.parse(transaksi.dibuatPada).toLocal();
          waktu = dt.toString().substring(11, 16);
        } catch (_) {
          waktu = '-';
        }

        return KartuTransaksi(
          nominal: transaksi.jumlah,
          namaKategori: namaKategori,
          catatan: transaksi.catatan,
          waktu: waktu,
          ikonKategori: ikon,
          warnaKategori: warna,
          onTap: () => context.push('/transaksi/${transaksi.id}'),
        );
      },
    );
  }
}
