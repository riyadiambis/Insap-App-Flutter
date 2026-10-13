import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';
import '../../domain/entities/cadangan_info.dart';
import '../../domain/entities/pengguna_entity.dart';
import '../cubit/akun_cubit.dart';
import '../cubit/akun_state.dart';
import '../cubit/cadangan_cubit.dart';
import '../cubit/cadangan_state.dart';

class HalamanAkun extends StatelessWidget {
  final PenggunaEntity pengguna;

  const HalamanAkun({super.key, required this.pengguna});

  static const List<String> _namaBulanSingkat = [
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

  static String _formatWaktu(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = _namaBulanSingkat[dt.month - 1];
    final y = dt.year;
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '$d $m $y, $jam:$menit';
  }

  void _konfirmasiKeluar(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.kartu,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
            side: const BorderSide(
              color: AppColors.ink,
              width: AppSizes.border,
            ),
          ),
          title: Text(
            'Keluar dari Akun?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Data transaksi lokal di perangkat ini tidak akan dihapus. Anda dapat masuk kembali kapan saja.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AkunCubit>().keluar();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salahLatar,
                foregroundColor: AppColors.salah,
                elevation: 0,
                side: const BorderSide(
                  color: AppColors.salah,
                  width: AppSizes.borderTipis,
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _konfirmasiPulihkan(BuildContext context, CadanganInfo? info) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.kartu,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
            side: const BorderSide(
              color: AppColors.ink,
              width: AppSizes.border,
            ),
          ),
          title: Text(
            'Pulihkan Data dari Awan?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data transaksi lokal saat ini akan ditimpa dengan data cadangan awan terakhir.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sedang),
              if (info != null && info.waktuCadanganTerakhir != null) ...[
                Text(
                  'Waktu cadangan: ${_formatWaktu(info.waktuCadanganTerakhir!)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'Jumlah data: ${info.jumlahTransaksi} transaksi',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ] else ...[
                const Text(
                  'Catatan: Belum ada data cadangan di akun ini.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.salah,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<CadanganCubit>().pulihkanData(pengguna.uid);
              },
              child: const Text(
                'Pulihkan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CadanganCubit>(
      create: (_) => sl<CadanganCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Akun & Cadangan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          backgroundColor: AppColors.paper,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.ink),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(AppSizes.borderTipis),
            child: Container(
              color: AppColors.ink,
              height: AppSizes.borderTipis,
            ),
          ),
        ),
        body: BlocListener<CadanganCubit, CadanganState>(
          listener: (context, state) {
            if (state is CadanganSukses) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.pesan),
                  backgroundColor: AppColors.benar,
                ),
              );
            } else if (state is CadanganPulihSukses) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Data berhasil dipulihkan dari awan (${state.info.jumlahTransaksi} transaksi)!',
                  ),
                  backgroundColor: AppColors.benar,
                ),
              );
              // Muat ulang KEDUANYA sesuai aturan ISSUE-16 dan ISSUE-14
              context.read<BerandaCubit>().muatRingkasan();
              context.read<RiwayatCubit>().muatRiwayat();
            } else if (state is CadanganGalat) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.pesan),
                  backgroundColor: AppColors.salah,
                ),
              );
            }
          },
          child: PaperBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.besar),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.batasLebarKonten,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kartu Info Pengguna
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.besar),
                        decoration: BoxDecoration(
                          color: AppColors.kartu,
                          border: Border.all(
                            color: AppColors.ink,
                            width: AppSizes.border,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusKartu,
                          ),
                          boxShadow: const [AppTheme.bayanganDefault],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.stabilo,
                                    border: Border.all(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusBadge,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.ink,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sedang),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pengguna.email ?? 'Pengguna Anonim',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.agakKecil,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.benarLatar,
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusLabel,
                                          ),
                                          border: Border.all(
                                            color: AppColors.benar,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          'Akun Terhubung',
                                          style: TextStyle(
                                            color: AppColors.benar,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.besar),
                            const Divider(color: AppColors.garis, thickness: 1),
                            const SizedBox(height: AppSpacing.agakKecil),
                            const Text(
                              'ID Pengguna:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              pengguna.uid,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.besar),

                      // Kartu Cadangan Awan (Cloud Firestore)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.besar),
                        decoration: BoxDecoration(
                          color: AppColors.kartu,
                          border: Border.all(
                            color: AppColors.ink,
                            width: AppSizes.border,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusKartu,
                          ),
                          boxShadow: const [AppTheme.bayanganDefault],
                        ),
                        child: Builder(
                          builder: (cardContext) {
                            return StreamBuilder<CadanganInfo?>(
                              stream: cardContext
                                  .read<CadanganCubit>()
                                  .pantauCadanganTerakhir(pengguna.uid),
                              builder: (context, snapshot) {
                                final info = snapshot.data;
                                final waktuStr =
                                    info?.waktuCadanganTerakhir != null
                                    ? _formatWaktu(info!.waktuCadanganTerakhir!)
                                    : 'Belum pernah dicadangkan';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.cloud_outlined,
                                          color: AppColors.ink,
                                          size: 24,
                                        ),
                                        const SizedBox(
                                          width: AppSpacing.sedang,
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Cadangan Awan (Firestore)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sedang),
                                    Text(
                                      'Simpan data transaksi, kategori, dan refleksi ke awan secara aman. Anda dapat memulihkannya kembali kapan saja.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.inkSoft,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.sedang),
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.sedang,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.paper,
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusKotakIkonKuota,
                                        ),
                                        border: Border.all(
                                          color: AppColors.garis,
                                          width: AppSizes.borderTipis,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Cadangan Terakhir:',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppColors.inkSoft,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.kecil,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  waktuStr,
                                                  textAlign: TextAlign.end,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppColors.ink,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (info != null &&
                                              info.waktuCadanganTerakhir !=
                                                  null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tersimpan: ${info.jumlahTransaksi} transaksi, ${info.jumlahKategori} kategori, ${info.jumlahRefleksi} refleksi',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColors.inkSoft,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.besar),
                                    BlocBuilder<CadanganCubit, CadanganState>(
                                      builder: (context, cadanganState) {
                                        final sedangMemuat =
                                            cadanganState is CadanganMemuat;
                                        return Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                key: const Key(
                                                  'tombol_cadangkan',
                                                ),
                                                onPressed: sedangMemuat
                                                    ? null
                                                    : () => context
                                                          .read<CadanganCubit>()
                                                          .cadangkanData(
                                                            pengguna.uid,
                                                          ),
                                                icon: sedangMemuat
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  AppColors.ink,
                                                            ),
                                                      )
                                                    : const Icon(
                                                        Icons
                                                            .cloud_upload_outlined,
                                                        size: 20,
                                                      ),
                                                label: Text(
                                                  sedangMemuat
                                                      ? cadanganState.pesan
                                                      : 'Cadangkan Sekarang',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.sedang,
                                            ),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                key: const Key(
                                                  'tombol_pulihkan',
                                                ),
                                                onPressed: sedangMemuat
                                                    ? null
                                                    : () => _konfirmasiPulihkan(
                                                        context,
                                                        info,
                                                      ),
                                                icon: const Icon(
                                                  Icons.cloud_download_outlined,
                                                  size: 20,
                                                ),
                                                label: const Text(
                                                  'Pulihkan Data',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.besar),

                      // Tombol Keluar
                      BlocBuilder<AkunCubit, AkunState>(
                        builder: (context, state) {
                          final sedangMemuat = state is AkunMemuat;
                          return OutlinedButton.icon(
                            onPressed: sedangMemuat
                                ? null
                                : () => _konfirmasiKeluar(context),
                            icon: const Icon(
                              Icons.logout,
                              color: AppColors.salah,
                              size: 20,
                            ),
                            label: Text(
                              sedangMemuat
                                  ? 'Memproses...'
                                  : 'Keluar dari Akun',
                              style: const TextStyle(
                                color: AppColors.salah,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sedang,
                              ),
                              side: const BorderSide(
                                color: AppColors.salah,
                                width: AppSizes.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusTombol,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
