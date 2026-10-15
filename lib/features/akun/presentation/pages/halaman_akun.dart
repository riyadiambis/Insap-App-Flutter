import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/avatar_profil.dart';
import '../../../../core/widgets/dialog_sukses.dart';
import '../../../../core/widgets/kartu_tentang_aplikasi.dart';
import '../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';
import '../../domain/entities/cadangan_info.dart';
import '../../domain/entities/pengguna_entity.dart';
import '../../domain/entities/rencana_cadangan.dart';
import '../cubit/akun_cubit.dart';
import '../cubit/akun_state.dart';
import '../cubit/cadangan_cubit.dart';
import '../cubit/cadangan_state.dart';

class HalamanAkun extends StatefulWidget {
  final PenggunaEntity pengguna;

  const HalamanAkun({super.key, required this.pengguna});

  @override
  State<HalamanAkun> createState() => _HalamanAkunState();
}

class _HalamanAkunState extends State<HalamanAkun> {
  CadanganInfo? _infoTerakhir;

  PenggunaEntity get pengguna => widget.pengguna;

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

  Future<void> _mulaiCadangkan(BuildContext context, CadanganInfo? info) async {
    final cubit = context.read<CadanganCubit>();
    final rencana = await cubit.siapkanCadangan(pengguna.uid);
    if (rencana == null || !context.mounted) return;

    if (rencana.ditolak) {
      _tampilkanPerangkatKosong(context, rencana, info);
    } else if (rencana.perluKonfirmasi) {
      _konfirmasiCadangkan(context, rencana);
    } else {
      cubit.cadangkanData(pengguna.uid);
    }
  }

  static List<String> _ringkasSelisih(RencanaCadangan rencana) {
    final koleksi = {
      'Transaksi': rencana.transaksi,
      'Kategori': rencana.kategori,
      'Refleksi': rencana.refleksi,
    };
    final baris = <String>[];
    koleksi.forEach((nama, selisih) {
      final perubahan = [
        if (selisih.akanDihapus > 0) '${selisih.akanDihapus} dihapus',
        if (selisih.akanDitimpa > 0) '${selisih.akanDitimpa} ditimpa',
      ];
      if (perubahan.isNotEmpty) baris.add('$nama: ${perubahan.join(', ')}');
    });
    return baris;
  }

  void _konfirmasiCadangkan(BuildContext context, RencanaCadangan rencana) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('dialog_konfirmasi_cadangkan'),
          backgroundColor: AppColors.kartu,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
            side: const BorderSide(
              color: AppColors.ink,
              width: AppSizes.border,
            ),
          ),
          title: Text(
            'Timpa Cadangan di Awan?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cadangan awan akan disamakan dengan data di perangkat ini. Dokumen awan berikut akan berubah:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sedang),
              for (final baris in _ringkasSelisih(rencana))
                Text(
                  baris,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.salah,
                  ),
                ),
              const SizedBox(height: AppSpacing.sedang),
              const Text(
                'Baru memasang ulang aplikasi? Pulihkan data dulu supaya cadangan lama tidak hilang.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.inkSoft,
                ),
              ),
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
                context.read<CadanganCubit>().cadangkanData(pengguna.uid);
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
                'Tetap Cadangkan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _tampilkanPerangkatKosong(
    BuildContext context,
    RencanaCadangan rencana,
    CadanganInfo? info,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('dialog_perangkat_kosong'),
          backgroundColor: AppColors.kartu,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
            side: const BorderSide(
              color: AppColors.ink,
              width: AppSizes.border,
            ),
          ),
          title: Text(
            'Perangkat Ini Masih Kosong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Belum ada transaksi maupun refleksi di perangkat ini. Mencadangkan sekarang akan menghapus cadangan di awan, jadi pencadangan dibatalkan.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sedang),
              Text(
                'Awan menyimpan ${rencana.transaksi.jumlahAwan} transaksi dan ${rencana.refleksi.jumlahAwan} refleksi.',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
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
                _konfirmasiPulihkan(context, info);
              },
              child: const Text(
                'Pulihkan Data',
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
              final info = state.info ?? _infoTerakhir;
              final ringkasan = info != null
                  ? '${info.jumlahTransaksi} transaksi, ${info.jumlahKategori} kategori, ${info.jumlahRefleksi} refleksi'
                  : state.pesan;
              tampilkanDialogSukses(
                context,
                'Cadangan berhasil',
                ringkasan,
              );
            } else if (state is CadanganPulihSukses) {
              final ringkasan =
                  '${state.info.jumlahTransaksi} transaksi, ${state.info.jumlahKategori} kategori, ${state.info.jumlahRefleksi} refleksi';
              tampilkanDialogSukses(
                context,
                'Data berhasil dipulihkan',
                ringkasan,
              );
              // Muat ulang KEDUANYA sesuai aturan ISSUE-16 dan ISSUE-14
              try {
                context.read<BerandaCubit>().muatRingkasan();
              } catch (_) {}
              try {
                context.read<RiwayatCubit>().muatRiwayat();
              } catch (_) {}
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
                                AvatarProfil(
                                  fotoUrl: pengguna.fotoUrl,
                                  ukuran: 52,
                                  ukuranIkon: 28,
                                  warnaLatar: AppColors.stabilo,
                                  warnaIkon: AppColors.ink,
                                ),
                                const SizedBox(width: AppSpacing.sedang),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (pengguna.namaTampilan != null &&
                                          pengguna.namaTampilan!
                                              .trim()
                                              .isNotEmpty) ...[
                                        Text(
                                          pengguna.namaTampilan!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (pengguna.email != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            pengguna.email!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.inkSoft,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ] else ...[
                                        Text(
                                          pengguna.email ?? 'Pengguna Anonim',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
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
                                if (info != null) {
                                  _infoTerakhir = info;
                                }
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
                                                    : () => _mulaiCadangkan(
                                                        context,
                                                        info,
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

                      // Kartu Informasi Aplikasi & Tim Pengembang (ISSUE-20)
                      const KartuTentangAplikasi(),
                      const SizedBox(height: AppSpacing.besar),

                      // Tombol Keluar (Paling Bawah)
                      BlocBuilder<AkunCubit, AkunState>(
                        builder: (context, state) {
                          final sedangMemuat = state is AkunMemuat;
                          return OutlinedButton.icon(
                            key: const Key('tombol_keluar'),
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
