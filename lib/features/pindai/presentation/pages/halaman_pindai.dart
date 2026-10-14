import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../kategori/presentation/cubit/kategori_state.dart';
import '../cubit/pindai_cubit.dart';
import '../cubit/pindai_state.dart';
import '../utils/gambar_helper.dart';
import 'halaman_konfirmasi_draf.dart';

/// Layar utama pemindaian struk belanja (F-09, Modul Jaringan REST API, Google ML Kit).
class HalamanPindai extends StatefulWidget {
  /// Parameter opsional untuk pengujian widget (memungkinkan injeksi pemindai tiruan)
  final Future<List<String>?> Function()? onScanDocument;

  const HalamanPindai({super.key, this.onScanDocument});

  @override
  State<HalamanPindai> createState() => _HalamanPindaiState();
}

class _HalamanPindaiState extends State<HalamanPindai> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PindaiCubit>().inisialisasi();
    });
  }

  Future<void> _jalankanPemindaiDokumen() async {
    final cubit = context.read<PindaiCubit>();
    if (cubit.state.sisaKuota <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kuota pemindaian pekan ini sudah habis')),
      );
      return;
    }

    List<String>? images;
    try {
      if (widget.onScanDocument != null) {
        images = await widget.onScanDocument!();
      } else {
        final scanner = DocumentScanner(
          options: DocumentScannerOptions(
            mode: ScannerMode.full,
            isGalleryImport: true,
            pageLimit: 1,
          ),
        );
        final result = await scanner.scanDocument();
        images = result.images;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka pemindai kamera: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    // Jika pengguna membatalkan pada antarmuka ML Kit
    if (images == null || images.isEmpty) {
      return;
    }

    final pathAsli = images.first;

    // 1. Kecilkan citra ke sisi terpanjang maksimal 1024px menggunakan dart:ui (Keputusan 4)
    final pathSiapKirim = await GambarHelper.kompresDanKecilkanCitra(pathAsli);

    if (!mounted) return;

    // 2. Ambil daftar kategori aktif dari KategoriCubit untuk disisipkan ke prompt Gemini
    List<String> daftarKategori = [];
    final katState = context.read<KategoriCubit>().state;
    if (katState is KategoriLoaded) {
      daftarKategori = katState.kategoriList
          .map((k) => k.nama.toLowerCase())
          .toList();
    }

    // 3. Kirim ke Gemini AI
    await cubit.prosesPindai(
      imagePath: pathSiapKirim,
      daftarKategori: daftarKategori,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.batasLebarKonten,
            ),
            child: BlocConsumer<PindaiCubit, PindaiState>(
              listener: (context, state) {},
              builder: (context, state) {
                // Jika Gemini berhasil mengekstrak dan butuh konfirmasi draf
                if (state.status == PindaiStatus.butuhKonfirmasi &&
                    state.hasilPindai != null) {
                  return HalamanKonfirmasiDraf(hasilPindai: state.hasilPindai!);
                }

                return Column(
                  children: [
                    // Header Navigasi Atas
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.besar,
                        top: AppSpacing.besar,
                        right: AppSpacing.besar,
                        bottom: AppSpacing.sedang,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.read<PindaiCubit>().reset();
                              context.pop();
                            },
                            child: Container(
                              width: AppSizes.kotakIkonAksi,
                              height: AppSizes.kotakIkonAksi,
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: AppSizes.border,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusKotakIkonAksi,
                                ),
                                boxShadow: const [AppTheme.bayanganKecilGelap],
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.ink,
                                size: AppSizes.ikonAksi,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sedang),
                          Text(
                            'Pindai Struk',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.besar),
                        children: [
                          // Kartu Info Sisa Kuota
                          KartuBukuTulis(
                            backgroundColor: AppColors.paper,
                            padding: const EdgeInsets.all(AppSpacing.sedang),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                    AppSpacing.agakKecil,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.stabilo,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusKotakIkonAksi,
                                    ),
                                    border: Border.all(
                                      color: AppColors.ink,
                                      width: AppSizes.borderTipis,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: AppColors.ink,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sedang),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kuota Pindai Pekan Ini',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.inkSoft,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        '${state.sisaKuota} dari 10 tersisa',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: state.sisaKuota <= 0
                                                  ? Colors.red
                                                  : AppColors.ink,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.besar),

                          // Tampilan Saat Sedang Memindai / Memanggil AI (Loading 15 detik)
                          if (state.status == PindaiStatus.memuat) ...[
                            KartuBukuTulis(
                              backgroundColor: AppColors.paper,
                              padding: const EdgeInsets.all(
                                AppSpacing.lebihBesar,
                              ),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(
                                    color: AppColors.ink,
                                    strokeWidth: 3,
                                  ),
                                  const SizedBox(height: AppSpacing.besar),
                                  Text(
                                    'Menganalisis Struk dengan AI...',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.kecil),
                                  Text(
                                    'Gemini sedang membaca nominal, tanggal, dan nama toko. '
                                    'Batas waktu pemindaian maksimal 15 detik.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.inkSoft),
                                  ),
                                  const SizedBox(height: AppSpacing.besar),
                                  TextButton(
                                    onPressed: () {
                                      context.read<PindaiCubit>().reset();
                                    },
                                    child: const Text(
                                      'Batalkan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                          // Tampilan Galat / Error State
                          else if (state.status == PindaiStatus.gagal) ...[
                            KartuBukuTulis(
                              backgroundColor: AppColors.paper,
                              padding: const EdgeInsets.all(AppSpacing.besar),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red.shade700,
                                    size: 48,
                                  ),
                                  const SizedBox(height: AppSpacing.sedang),
                                  Text(
                                    state.pesanGalat ?? 'Gagal memindai struk',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.besar),

                                  // Tawaran Catat Manual jika batas waktu habis atau tidak ada internet
                                  if (state.tawarkanCatatManual) ...[
                                    TombolStabilo(
                                      teks: 'Catat Manual Saja',
                                      ikon: Icons.edit_note_rounded,
                                      onPressed: () {
                                        context.go('/catat');
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.sedang),
                                  ],

                                  TombolStabilo(
                                    teks: 'Coba Pindai Ulang',
                                    ikon: Icons.refresh_rounded,
                                    onPressed: _jalankanPemindaiDokumen,
                                  ),
                                ],
                              ),
                            ),
                          ]
                          // Tampilan Awal / Siap Memindai
                          else ...[
                            KartuBukuTulis(
                              backgroundColor: AppColors.paper,
                              padding: const EdgeInsets.all(AppSpacing.besar),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.document_scanner_outlined,
                                        color: AppColors.ink,
                                        size: 28,
                                      ),
                                      const SizedBox(
                                        width: AppSpacing.agakKecil,
                                      ),
                                      Text(
                                        'Panduan Pemindaian',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.ink,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sedang),
                                  const Text(
                                    '1. Letakkan struk fisik pada permukaan datar dengan pencahayaan cukup.\n'
                                    '2. Kamera akan mendeteksi tepi kertas dan memotong foto otomatis.\n'
                                    '3. AI Gemini akan mengekstrak total nominal dan kategori belanja.\n'
                                    '4. Anda tetap dapat mengedit draf sebelum disimpan ke catatan.',
                                    style: TextStyle(
                                      height: 1.5,
                                      color: AppColors.inkSoft,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.besar),
                                  TombolStabilo(
                                    teks: 'Buka Pemindai Struk',
                                    ikon: Icons.photo_camera_rounded,
                                    onPressed: _jalankanPemindaiDokumen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
