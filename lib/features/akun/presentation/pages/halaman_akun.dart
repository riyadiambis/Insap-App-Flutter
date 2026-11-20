import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/iklan/layanan_iklan.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/tur/tur_cubit.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/avatar_profil.dart';
import '../../../../core/widgets/dialog_sukses.dart';
import '../../../../core/widgets/header_aplikasi.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/lencana_paket.dart';
import '../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../beranda/presentation/widgets/bottom_sheet_target_bulanan.dart';
import '../../../pengaturan/domain/usecases/ambil_target_bulanan.dart';
import '../../../pengaturan/domain/usecases/simpan_target_bulanan.dart';
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
  int? _targetBulanan;

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

  @override
  void initState() {
    super.initState();
    _muatTargetBulanan();
  }

  Future<void> _muatTargetBulanan() async {
    if (!sl.isRegistered<AmbilTargetBulanan>()) return;
    try {
      final target = await sl<AmbilTargetBulanan>().call();
      if (mounted) {
        setState(() => _targetBulanan = target);
      }
    } catch (_) {}
  }

  Future<void> _bukaTargetBulanan(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BottomSheetTargetBulanan(
        targetSaatIni: _targetBulanan,
        onSimpan: (nominalBaru) async {
          if (sl.isRegistered<SimpanTargetBulanan>()) {
            await sl<SimpanTargetBulanan>().call(nominalBaru);
          }
          if (mounted) {
            setState(() => _targetBulanan = nominalBaru);
          }
          if (context.mounted) {
            try {
              await context.read<BerandaCubit>().muatRingkasan();
            } catch (_) {}
          }
        },
      ),
    );
  }

  void _tampilkanFiturDikembangkanSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Fitur sedang dikembangkan')),
      );
  }

  Future<void> _bukaOpsiPrivasiIklan() async {
    if (!sl.isRegistered<LayananIklan>()) return;
    await sl<LayananIklan>().tampilkanOpsiPrivasi();
    if (mounted) {
      setState(() {});
    }
  }

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

  void _konfirmasiHapusAkun(BuildContext context) {
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
            'Hapus Akun Permanen?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Akun dan seluruh cadangan di awan (transaksi, kategori, refleksi) akan dihapus permanen dan tidak bisa dikembalikan. Data di perangkat ini tetap ada.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              key: const Key('tombol_konfirmasi_hapus_akun'),
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AkunCubit>().hapusAkun();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salah,
                foregroundColor: AppColors.kartu,
                elevation: 0,
              ),
              child: const Text(
                'Hapus Permanen',
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
    if (!mounted || !context.mounted || rencana == null) return;

    if (rencana.ditolak) {
      _tampilkanPerangkatKosong(context, rencana, info);
    } else if (rencana.perluKonfirmasi) {
      _konfirmasiCadangkan(context, rencana);
    } else {
      if (!mounted || !context.mounted) return;
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

  Widget _buildKartuProfil(BuildContext context) {
    final punyaNama =
        pengguna.namaTampilan != null &&
        pengguna.namaTampilan!.trim().isNotEmpty;

    return KartuBukuTulis(
      shadow: AppTheme.bayanganGelap,
      pressedShadow: AppTheme.bayanganGelapTertekan,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AvatarProfil(
            fotoUrl: pengguna.fotoUrl,
            ukuran: 56,
            ukuranIkon: 28,
            warnaLatar: AppColors.daun,
            warnaIkon: AppColors.kartu,
          ),
          const SizedBox(width: AppSpacing.sedang),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  punyaNama
                      ? pengguna.namaTampilan!.trim()
                      : (pengguna.email ?? 'Pengguna Anonim'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.15,
                  ),
                ),
                if (punyaNama && pengguna.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    pengguna.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Akun tersambung',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.kecil),
          const LencanaPaket(paket: PaketInsap.gratis),
        ],
      ),
    );
  }

  Widget _buildKartuLangganan(BuildContext context) {
    return KartuBukuTulis(
      key: const Key('kartu_langganan_akun'),
      onTap: () => context.push('/langganan'),
      backgroundColor: AppColors.stabilo,
      shadow: AppTheme.bayanganGelap,
      pressedShadow: AppTheme.bayanganGelapTertekan,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.kartu,
              border: Border.all(
                color: AppColors.ink,
                width: AppSizes.border,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              size: 20,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: AppSpacing.sedang),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Langganan Insap',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'Plus Rp15 rb · Pro Rp29 rb per bulan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.ink,
          ),
        ],
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: const HeaderAplikasi(namaLayar: 'Akun', modeKembali: true),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CadanganCubit, CadanganState>(
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
          ),
          BlocListener<AkunCubit, AkunState>(
            listener: (context, state) {
              if (state is AkunGalat) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.pesan),
                    backgroundColor: AppColors.salah,
                  ),
                );
              }
            },
          ),
        ],
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
                    _buildKartuProfil(context),
                    const SizedBox(height: 14),
                    _buildKartuLangganan(context),
                    const SizedBox(height: 14),

                    // Menu utama
                    KartuBukuTulis(
                      shadow: AppTheme.bayanganGelap,
                      pressedShadow: AppTheme.bayanganGelapTertekan,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
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
                                  ? 'Terakhir: ${_formatWaktu(info!.waktuCadanganTerakhir!)}'
                                  : 'Belum pernah dicadangkan';

                              return BlocBuilder<CadanganCubit, CadanganState>(
                                builder: (context, cadanganState) {
                                  final sedangMemuat =
                                      cadanganState is CadanganMemuat;
                                  final targetStr =
                                      _targetBulanan != null &&
                                          _targetBulanan! > 0
                                      ? _targetBulanan!.toRupiah()
                                      : 'Belum diatur';

                                  return Column(
                                    children: [
                                      _BarisMenuAkun(
                                        key: const Key('tombol_cadangkan'),
                                        ikon: Icons.cloud_outlined,
                                        judul: 'Cadangkan sekarang',
                                        keterangan: sedangMemuat
                                            ? cadanganState.pesan
                                            : waktuStr,
                                        sedangMemuat: sedangMemuat,
                                        onTap: sedangMemuat
                                            ? null
                                            : () => _mulaiCadangkan(
                                                context,
                                                info,
                                              ),
                                      ),
                                      const _GarisPutus(),
                                      _BarisMenuAkun(
                                        key: const Key('tombol_pulihkan'),
                                        ikon: Icons.cloud_download_outlined,
                                        judul: 'Pulihkan data',
                                        keterangan:
                                            info != null &&
                                                info.waktuCadanganTerakhir !=
                                                    null
                                            ? '${info.jumlahTransaksi} transaksi, ${info.jumlahKategori} kategori, ${info.jumlahRefleksi} refleksi'
                                            : 'Timpa data lokal dari awan',
                                        onTap: sedangMemuat
                                            ? null
                                            : () => _konfirmasiPulihkan(
                                                context,
                                                info,
                                              ),
                                      ),
                                      const _GarisPutus(),
                                      _BarisMenuAkun(
                                        key: const Key('tombol_target_bulanan'),
                                        ikon: Icons.track_changes_outlined,
                                        judul: 'Target bulanan',
                                        keterangan: targetStr,
                                        onTap: () =>
                                            _bukaTargetBulanan(context),
                                      ),
                                      const _GarisPutus(),
                                      _BarisMenuAkun(
                                        key: const Key('tombol_ulangi_tur'),
                                        ikon: Icons.explore_outlined,
                                        judul: 'Ulangi tur aplikasi',
                                        onTap: () {
                                          if (sl.isRegistered<TurCubit>()) {
                                            sl<TurCubit>().mulaiUlang();
                                          }
                                          context.go('/');
                                        },
                                      ),
                                      const _GarisPutus(),
                                      _BarisMenuAkun(
                                        key: const Key('tombol_tentang'),
                                        ikon: Icons.info_outline_rounded,
                                        judul: 'Tentang Insap',
                                        tampilkanGaris: false,
                                        onTap: () => context.push('/tentang'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Seksi PRIVASI
                    KartuBukuTulis(
                      shadow: AppTheme.bayanganGelap,
                      pressedShadow: AppTheme.bayanganGelapTertekan,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 2),
                            child: Text(
                              'PRIVASI',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: AppColors.inkSoft,
                                  ),
                            ),
                          ),
                          _BarisMenuAkun(
                            key: const Key('tombol_salinan_data'),
                            ikon: Icons.verified_user_outlined,
                            judul: 'Minta salinan data',
                            keterangan: 'Hak UU PDP, berkas ZIP',
                            onTap: () =>
                                _tampilkanFiturDikembangkanSnack(context),
                          ),
                          const _GarisPutus(),
                          _BarisMenuAkun(
                            key: const Key('tombol_foto_struk'),
                            ikon: Icons.image_outlined,
                            judul: 'Foto struk',
                            keterangan: 'Bersihkan foto struk lama',
                            tampilkanGaris:
                                sl.isRegistered<LayananIklan>() &&
                                sl<LayananIklan>().perluTombolPrivasi,
                            onTap: () =>
                                _tampilkanFiturDikembangkanSnack(context),
                          ),
                          if (sl.isRegistered<LayananIklan>() &&
                              sl<LayananIklan>().perluTombolPrivasi) ...[
                            const _GarisPutus(),
                            _BarisMenuAkun(
                              key: const Key('tombol_privasi_iklan'),
                              ikon: Icons.privacy_tip_outlined,
                              judul: 'Pengaturan privasi iklan',
                              tampilkanGaris: false,
                              onTap: _bukaOpsiPrivasiIklan,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Seksi Keluar & Hapus Akun
                    KartuBukuTulis(
                      shadow: AppTheme.bayanganGelap,
                      pressedShadow: AppTheme.bayanganGelapTertekan,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: BlocBuilder<AkunCubit, AkunState>(
                        builder: (context, state) {
                          final sedangMemuat = state is AkunMemuat;
                          return Column(
                            children: [
                              _BarisMenuAkun(
                                key: const Key('tombol_keluar'),
                                ikon: Icons.logout_rounded,
                                judul: sedangMemuat ? 'Memproses...' : 'Keluar',
                                sedangMemuat: sedangMemuat,
                                onTap: sedangMemuat
                                    ? null
                                    : () => _konfirmasiKeluar(context),
                              ),
                              const _GarisPutus(),
                              _BarisMenuAkun(
                                key: const Key('tombol_hapus_akun'),
                                ikon: Icons.delete_outline_rounded,
                                warnaIkon: AppColors.merahTeks,
                                warnaJudul: AppColors.merahTeks,
                                judul: 'Hapus akun dan data awan',
                                keterangan: 'Tidak bisa dibatalkan',
                                tampilkanGaris: false,
                                onTap: sedangMemuat
                                    ? null
                                    : () => _konfirmasiHapusAkun(context),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      context.read<CadanganCubit>();
      return _buildScaffold(context);
    } catch (_) {
      return BlocProvider<CadanganCubit>(
        create: (_) => sl<CadanganCubit>(),
        child: Builder(
          builder: (childContext) => _buildScaffold(childContext),
        ),
      );
    }
  }
}

class _BarisMenuAkun extends StatelessWidget {
  final IconData ikon;
  final Color warnaIkon;
  final String judul;
  final Color warnaJudul;
  final String? keterangan;
  final VoidCallback? onTap;
  final bool sedangMemuat;
  final bool tampilkanGaris;

  const _BarisMenuAkun({
    super.key,
    required this.ikon,
    this.warnaIkon = AppColors.ink,
    required this.judul,
    this.warnaJudul = AppColors.ink,
    this.keterangan,
    this.onTap,
    this.sedangMemuat = false,
    this.tampilkanGaris = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.border,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
                ),
                child: sedangMemuat
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.ink,
                        ),
                      )
                    : Icon(ikon, size: 18, color: warnaIkon),
              ),
              const SizedBox(width: AppSpacing.sedang),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      judul,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: warnaJudul,
                      ),
                    ),
                    if (keterangan != null)
                      Text(
                        keterangan!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.kecil),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GarisPutus extends StatelessWidget {
  const _GarisPutus();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1.5),
      painter: _GarisPutusPainter(),
    );
  }
}

class _GarisPutusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.garisPutus
      ..strokeWidth = 1.5;
    const double dash = 5;
    const double gap = 4;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
