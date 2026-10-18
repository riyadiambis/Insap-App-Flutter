import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/iso_week.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../beranda/presentation/cubit/beranda_state.dart';
import '../../domain/usecases/ambil_refleksi_pekan.dart';
import '../cubit/refleksi_cubit.dart';
import '../cubit/refleksi_state.dart';
import '../widgets/form_isian_refleksi.dart';
import '../widgets/kartu_agregat_kakeibo.dart';
import '../widgets/kartu_pekan_lalu.dart';
import '../widgets/kartu_renungan_pengen.dart';
import '../widgets/kartu_ringkasan_refleksi.dart';

class HalamanRefleksi extends StatelessWidget {
  const HalamanRefleksi({super.key});

  @override
  Widget build(BuildContext context) {
    // gunakan RefleksiCubit dari context bila sudah disediakan (misal pada pengujian),
    // atau buat dari service locator sl dan langsung muat data pekan berjalan
    try {
      context.read<RefleksiCubit>();
      return const _RefleksiView();
    } catch (_) {
      return BlocProvider<RefleksiCubit>(
        create: (_) => sl<RefleksiCubit>()..muatRefleksi(),
        child: const _RefleksiView(),
      );
    }
  }
}

class _RefleksiView extends StatelessWidget {
  const _RefleksiView();

  bool _adaBerandaCubit(BuildContext context) {
    try {
      context.read<BerandaCubit>();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kontenScaffold = Scaffold(
      body: PaperBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.batasLebarKonten,
            ),
            child: BlocConsumer<RefleksiCubit, RefleksiState>(
              listenWhen: (prev, curr) =>
                  prev.status != curr.status &&
                  (curr.status == RefleksiStatus.saved ||
                      curr.status == RefleksiStatus.error),
              listener: (context, state) {
                if (state.status == RefleksiStatus.saved &&
                    state.pesanSukses != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(state.pesanSukses!)));
                } else if (state.status == RefleksiStatus.error &&
                    state.pesanGalat != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(state.pesanGalat!)));
                }
              },
              builder: (context, state) {
                if (state.status == RefleksiStatus.initial ||
                    (state.status == RefleksiStatus.loading &&
                        state.data == null)) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                    ),
                  );
                }

                if (state.status == RefleksiStatus.error &&
                    state.data == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.besar),
                      child: Text(
                        'Ups, gagal memuat refleksi:\n${state.pesanGalat ?? ''}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                final data = state.data;
                if (data == null) {
                  return const SizedBox.shrink();
                }

                return _KontenRefleksi(
                  data: data,
                  sedangMenyimpan: state.status == RefleksiStatus.saving,
                );
              },
            ),
          ),
        ),
      ),
    );

    // ikuti perubahan transaksi dari BerandaCubit supaya angka pengeluaran sepekan
    // otomatis segar kembali meskipun tab refleksi ditahan oleh IndexedStack
    if (_adaBerandaCubit(context)) {
      return BlocListener<BerandaCubit, BerandaState>(
        listenWhen: (prev, curr) => curr is BerandaLoaded,
        listener: (context, _) {
          context.read<RefleksiCubit>().muatRefleksi();
        },
        child: kontenScaffold,
      );
    }

    return kontenScaffold;
  }
}

class _KontenRefleksi extends StatefulWidget {
  final DataRefleksiPekan data;
  final bool sedangMenyimpan;

  const _KontenRefleksi({
    required this.data,
    required this.sedangMenyimpan,
  });

  @override
  State<_KontenRefleksi> createState() => _KontenRefleksiState();
}

class _KontenRefleksiState extends State<_KontenRefleksi> {
  bool _sedangMengubah = false;

  @override
  void didUpdateWidget(covariant _KontenRefleksi oldWidget) {
    super.didUpdateWidget(oldWidget);
    // jika sebelumnya sedang menyimpan dan sekarang sudah selesai tersimpan,
    // kembalikan form ke kartu ringkasan
    if (oldWidget.sedangMenyimpan && !widget.sedangMenyimpan) {
      if (widget.data.refleksiTersimpan != null) {
        setState(() {
          _sedangMengubah = false;
        });
      }
    }
  }

  Widget _buildHeaderKonten(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final teksRentang = formatRentangTanggal(
      widget.data.awalPekan,
      widget.data.akhirPekan,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.agakKecil,
                children: [
                  Text(
                    'Refleksi',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -AppSizes.geserStabiloJudul,
                        right: -AppSizes.geserStabiloJudul,
                        bottom: AppSpacing.mini,
                        child: Container(
                          height: AppSizes.tinggiStabiloJudul,
                          decoration: BoxDecoration(
                            color: AppColors.stabilo,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLabel,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Mingguan',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.mini),
              Text(
                'Pekan ke-${widget.data.mingguKe} • Ritual Kakeibo',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.kecil),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sedang,
            vertical: AppSpacing.agakKecil,
          ),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.ink, width: AppSizes.border),
            borderRadius: BorderRadius.circular(AppSizes.radiusPil),
            boxShadow: const [AppTheme.bayanganKecilGelap],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: AppSizes.ikonSelisih,
                color: AppColors.ink,
              ),
              const SizedBox(width: AppSpacing.sangatKecil),
              Text(
                teksRentang,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buatTeksPerbandinganPekanLalu() {
    final selisih = widget.data.agregat.selisihPekanLalu;
    final pekanLaluRp = widget.data.agregat.totalPekanLalu.toRupiah();
    if (selisih == 0) {
      return 'Pekan lalu: $pekanLaluRp (sama dengan pekan ini)';
    } else if (selisih > 0) {
      return 'Pekan lalu: $pekanLaluRp (+${selisih.toRupiah()} pekan ini)';
    } else {
      return 'Pekan lalu: $pekanLaluRp (-${selisih.abs().toRupiah()} pekan ini)';
    }
  }

  String _buatTeksCatatanKartuUtama() {
    if (!widget.data.agregat.adaTransaksi) {
      return 'Belum ada pengeluaran tercatat pekan ini. Kamu tetap bisa menulis refleksi dan menetapkan target untuk pekan depan.';
    }
    final selisihTarget = widget.data.selisihTarget;
    if (selisihTarget == null) {
      return 'Tetapkan target pengeluaran di bawah agar pekan depan kamu punya acuan perbandingan.';
    }
    if (selisihTarget == 0) {
      return 'Realisasi pengeluaran pekan ini tepat sama dengan target awalmu.';
    }
    if (selisihTarget > 0) {
      return 'Selisih ${selisihTarget.toRupiah()} dari target awal. Yuk cek kembali ritme kebutuhanmu untuk pekan depan.';
    }
    return 'Tersisa ${selisihTarget.abs().toRupiah()} dari target awal yang kamu tetapkan.';
  }

  Widget _buildKartuRingkasanPekan(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final teksTarget = widget.data.targetPekanIni != null
        ? widget.data.targetPekanIni!.toRupiah()
        : 'belum ada target';

    return KartuBukuTulis(
      radius: AppSizes.radiusTombol,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: AppSizes.ikonKalender,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: AppSpacing.agakKecil),
                    Flexible(
                      child: Text(
                        'PENGELUARAN SEPEKAN',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.kecil),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.kecil,
                  vertical: AppSpacing.mini,
                ),
                decoration: BoxDecoration(
                  color: AppColors.stabilo,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.borderTipis,
                  ),
                ),
                child: Text(
                  'Evaluasi Santai',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sedang),
          Text(
            widget.data.agregat.totalPekanIni.toRupiah(),
            style: AppTheme.nominalUtama,
          ),
          const SizedBox(height: AppSpacing.kecil),
          Wrap(
            spacing: AppSpacing.kecil,
            runSpacing: AppSpacing.kecil,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.kecil,
                  vertical: AppSpacing.sangatKecil,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(
                    AppSizes.radiusKotakIkonAksi,
                  ),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.borderTipis,
                  ),
                ),
                child: Text(
                  'Target: $teksTarget',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.kecil,
                  vertical: AppSpacing.sangatKecil,
                ),
                decoration: BoxDecoration(
                  color: AppColors.grid,
                  borderRadius: BorderRadius.circular(
                    AppSizes.radiusKotakIkonAksi,
                  ),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.borderTipis,
                  ),
                ),
                child: Text(
                  _buatTeksPerbandinganPekanLalu(),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sedang),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sedang),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
              border: Border.all(color: AppColors.ink, width: AppSizes.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  size: AppSizes.ikonAksi,
                  color: AppColors.ink,
                ),
                const SizedBox(width: AppSpacing.kecil),
                Expanded(
                  child: Text(
                    _buatTeksCatatanKartuUtama(),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final adaRefleksiPekanLalu = data.refleksiPekanLalu != null &&
        data.refleksiPekanLalu!.catatanRefleksi != null &&
        data.refleksiPekanLalu!.catatanRefleksi!.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: AppSpacing.besar,
        top: AppSpacing.besar,
        right: AppSpacing.besar,
        bottom: AppSpacing.jarakGulirBawah,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (adaRefleksiPekanLalu) ...[
            KartuPekanLalu(
              refleksi: data.refleksiPekanLalu!,
              target: data.targetPekanIni,
              onTap: () {
                context.push('/refleksi/riwayat');
              },
            ),
            const SizedBox(height: AppSpacing.besar),
          ],
          _buildHeaderKonten(context),
          const SizedBox(height: AppSpacing.besar),
          _buildKartuRingkasanPekan(context),
          const SizedBox(height: AppSpacing.besar),
          KartuAgregatKakeibo(agregat: data.agregat),
          const SizedBox(height: AppSpacing.besar),
          KartuRenunganPengen(agregat: data.agregat),
          const SizedBox(height: AppSpacing.besar),
          if (data.refleksiTersimpan != null && !_sedangMengubah)
            KartuRingkasanRefleksi(
              refleksi: data.refleksiTersimpan!,
              targetPekanDepan: data.targetPekanDepan,
              onUbah: () {
                setState(() {
                  _sedangMengubah = true;
                });
              },
            )
          else
            FormIsianRefleksi(
              catatanAwal: data.refleksiTersimpan?.catatanRefleksi,
              targetAwal: _sedangMengubah ? data.targetPekanDepan : null,
              targetPekanIni: data.targetPekanIni,
              targetBulanan: data.targetBulanan,
              tanggalAcuan: data.awalPekan,
              sedangMenyimpan: widget.sedangMenyimpan,
              onSimpan: (catatan, targetPekanDepan) {
                context.read<RefleksiCubit>().simpan(
                  catatanRefleksi: catatan,
                  targetPekanDepan: targetPekanDepan,
                );
              },
            ),
          const SizedBox(height: AppSpacing.besar),
          Center(
            child: TextButton.icon(
              key: const Key('tombol_lihat_riwayat_refleksi'),
              onPressed: () {
                context.push('/refleksi/riwayat');
              },
              icon: const Icon(Icons.history_outlined, size: AppSizes.ikonAksi),
              label: const Text(
                'Lihat refleksi sebelumnya',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
