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

  static const _fiturGratis = [
    'Bonus +1 pindai/iklan (maks 10, plafon 15/pekan) · segera hadir',
    'Catat manual dan refleksi tanpa batas',
    'Anggaran kategori bawaan',
    'Ekspor ZIP data pribadi (UU PDP)',
    'Cadangan manual',
  ];

  static const _fiturPlus = [
    '50 pindai/pekan, bebas iklan',
    'Kategori kustom',
    'Unduh foto struk per struk',
    'Ekspor PDF mingguan/bulanan',
    'Cadangan otomatis Google Drive',
  ];

  static const _fiturPro = [
    '100 pindai/pekan, bebas iklan & semua isi Plus',
    'Multi-Kantong saldo',
    'Radar Saldo Kritis (prediksi habis + batas belanja harian)',
    'Audit Kebocoran AI 1x/pekan & evaluasi bulanan AI',
    'Patungan tagihan & target tabungan',
    'Tema eksklusif',
  ];

  String get _labelTombolCta => switch (_paketTerpilih) {
    PaketInsap.gratis => 'Paketmu sekarang',
    PaketInsap.plus => 'Langganan Plus · Rp15.000/bulan',
    PaketInsap.pro => 'Langganan Pro · Rp29.000/bulan',
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
                            deskripsi: 'Catat, refleksi, ekspor ZIP, cadangan manual',
                            harga: 'Rp0',
                            kuota: '5 pindai/pekan',
                            catatanStatus: 'Paketmu sekarang',
                            daftarFitur: _fiturGratis,
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
                            deskripsi: '50 pindai/pekan, bebas iklan, ekspor PDF',
                            harga: 'Rp15 rb',
                            kuota: '50 pindai/pekan',
                            daftarFitur: _fiturPlus,
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
                            deskripsi: 'Semua isi Plus + AI, Multi-Kantong, patungan',
                            harga: 'Rp29 rb',
                            kuota: '100 pindai/pekan',
                            labelSorotan: 'PALING LENGKAP',
                            daftarFitur: _fiturPro,
                            terpilih: _paketTerpilih == PaketInsap.pro,
                            onTap: () => setState(
                              () => _paketTerpilih = PaketInsap.pro,
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
                          onPressed: _paketTerpilih == PaketInsap.gratis
                              ? null
                              : () => tampilkanDialogFiturDikembangkan(context),
                        ),
                        const SizedBox(height: AppSpacing.kecil),
                        Text(
                          'Pembayaran langganan belum aktif. Kami kabari begitu siap.',
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
  final List<String> daftarFitur;
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
    this.daftarFitur = const [],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                height: 1.15,
                              ),
                        ),
                        Text(
                          kuota,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (daftarFitur.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.kecil),
                  for (final fitur in daftarFitur)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.daunTua,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              fitur,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                    height: 1.3,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
