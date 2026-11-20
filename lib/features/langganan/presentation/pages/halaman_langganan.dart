import 'package:flutter/material.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_fitur_dikembangkan.dart';
import '../../../../core/widgets/header_aplikasi.dart';
import '../../../../core/widgets/lencana_paket.dart';
import '../../../../core/widgets/maskot_struki.dart';
import '../../../../core/widgets/tombol_stabilo.dart';

/// Halaman pilihan paket langganan Insap sesuai `Langganan.dc.html`.
/// Pilihan paket hanya state lokal; tombol beli menampilkan dialog pengembangan.
class HalamanLangganan extends StatefulWidget {
  const HalamanLangganan({super.key});

  @override
  State<HalamanLangganan> createState() => _HalamanLanggananState();
}

class _HalamanLanggananState extends State<HalamanLangganan> {
  PaketInsap _paketTerpilih = PaketInsap.pro;

  static const _daftarFiturPro = [
    (ikon: Icons.auto_awesome_outlined, label: 'Laporan AI bulanan'),
    (ikon: Icons.chat_bubble_outline_rounded, label: 'Tanya Struki 30x per pekan'),
    (ikon: Icons.group_outlined, label: 'Patungan dari struk'),
    (ikon: Icons.savings_outlined, label: 'Target tabungan'),
    (ikon: Icons.palette_outlined, label: 'Tema dan pose maskot eksklusif'),
  ];

  String get _labelTombolCta => switch (_paketTerpilih) {
    PaketInsap.gratis => 'Langganan Gratis · Rp0/bulan',
    PaketInsap.plus => 'Langganan Plus · Rp15.000/bulan',
    PaketInsap.pro => 'Langganan Pro · Rp39.000/bulan',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderAplikasi(
        namaLayar: 'Langganan',
        modeKembali: true,
      ),
      body: PaperBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.batasLebarKonten,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.besar,
                        AppSpacing.besar,
                        AppSpacing.besar,
                        AppSpacing.sedang,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const MaskotStruki(
                                pose: PoseMaskot.nabung,
                                ukuran: 84,
                              ),
                              const SizedBox(width: AppSpacing.sedang),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pilih paket Insap',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.ink,
                                            height: 1.15,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.mini),
                                    Text(
                                      'Mencatat dan refleksi tetap gratis selamanya.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize: 14,
                                            color: AppColors.inkSoft,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.besar),
                          _KartuPaket(
                            key: const Key('kartu_paket_gratis'),
                            paket: PaketInsap.gratis,
                            judul: 'Gratis',
                            deskripsi: 'Catat, refleksi, cadangan manual',
                            harga: 'Rp0',
                            kuota: '10 pindai/pekan',
                            catatanStatus: 'Paketmu sekarang',
                            terpilih: _paketTerpilih == PaketInsap.gratis,
                            onTap: () => setState(
                              () => _paketTerpilih = PaketInsap.gratis,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sedang),
                          _KartuPaket(
                            key: const Key('kartu_paket_plus'),
                            paket: PaketInsap.plus,
                            judul: 'Plus',
                            deskripsi: 'Unduh struk, cadangan otomatis, PDF',
                            harga: 'Rp15 rb',
                            kuota: '40 pindai/pekan',
                            terpilih: _paketTerpilih == PaketInsap.plus,
                            onTap: () => setState(
                              () => _paketTerpilih = PaketInsap.plus,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.besar),
                          _KartuPaket(
                            key: const Key('kartu_paket_pro'),
                            paket: PaketInsap.pro,
                            judul: 'Pro',
                            deskripsi: 'Semua Plus + fitur AI dan patungan',
                            harga: 'Rp39 rb',
                            kuota: '100 pindai/pekan',
                            labelSorotan: 'PALING LENGKAP',
                            terpilih: _paketTerpilih == PaketInsap.pro,
                            onTap: () => setState(
                              () => _paketTerpilih = PaketInsap.pro,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.besar),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.kartu,
                              border: Border.all(
                                color: AppColors.ink,
                                width: AppSizes.border,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusKartu,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YANG KAMU DAPAT DI PRO',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                        color: AppColors.inkSoft,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.sangatKecil),
                                for (final fitur in _daftarFiturPro)
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 34,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          fitur.ikon,
                                          size: 18,
                                          color: AppColors.ink,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            fitur.label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.kecil),
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: AppColors.daunTua,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.besar,
                      AppSpacing.kecil,
                      AppSpacing.besar,
                      AppSpacing.besar,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TombolStabilo(
                          key: const Key('tombol_langganan_cta'),
                          teks: _labelTombolCta,
                          onPressed: () =>
                              tampilkanDialogFiturDikembangkan(context),
                        ),
                        const SizedBox(height: AppSpacing.kecil),
                        Text(
                          'Ditagih bulanan lewat Google Play. Batalkan kapan saja.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KartuPaket extends StatelessWidget {
  final PaketInsap paket;
  final String judul;
  final String deskripsi;
  final String harga;
  final String kuota;
  final String? catatanStatus;
  final String? labelSorotan;
  final bool terpilih;
  final VoidCallback onTap;

  const _KartuPaket({
    super.key,
    required this.paket,
    required this.judul,
    required this.deskripsi,
    required this.harga,
    required this.kuota,
    this.catatanStatus,
    this.labelSorotan,
    required this.terpilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.kartu,
              border: Border.all(
                color: AppColors.ink,
                width: terpilih ? 3.0 : AppSizes.border,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
              boxShadow: terpilih
                  ? const [
                      BoxShadow(
                        color: AppColors.ink,
                        offset: Offset(5, 5),
                        spreadRadius: 2,
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: AppColors.stabilo,
                        offset: Offset(5, 5),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppSizes.border,
                    ),
                  ),
                  child: terpilih
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.ink,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sedang),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          LencanaPaket(paket: paket),
                          const SizedBox(width: AppSpacing.kecil),
                          Flexible(
                            child: Text(
                              judul,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                    height: 1.15,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        deskripsi,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (catatanStatus != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          catatanStatus!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 12,
                                color: AppColors.daunTua,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.kecil),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      harga,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      kuota,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (labelSorotan != null)
            Positioned(
              top: -12,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                ),
                child: Text(
                  labelSorotan!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.stabilo,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
