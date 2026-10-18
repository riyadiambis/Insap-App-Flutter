import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import '../../../../core/constants/kuota_constants.dart';
import '../../../../core/network/gemini_client.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../kategori/presentation/cubit/kategori_state.dart';
import '../cubit/pindai_cubit.dart';
import '../cubit/pindai_state.dart';
import '../utils/gambar_helper.dart';
import '../widgets/dialog_panduan_pindai.dart';
import 'halaman_konfirmasi_pindai.dart';

/// Layar utama pemindaian struk belanja (F-09, Modul Jaringan REST API, Google ML Kit).
class HalamanPindai extends StatefulWidget {
  /// Parameter opsional untuk langsung menjalankan pemindai setelah inisialisasi
  final bool mulaiLangsung;

  /// Parameter opsional untuk pengujian widget (memungkinkan injeksi pemindai tiruan)
  final Future<List<String>?> Function()? onScanDocument;

  /// Parameter opsional untuk pengujian koneksi internet (No 13)
  final Future<bool> Function()? onCheckConnection;

  /// Parameter opsional untuk pengujian cek kunci API Gemini (No 33)
  final bool Function()? onCheckApiKey;

  const HalamanPindai({
    super.key,
    this.mulaiLangsung = false,
    this.onScanDocument,
    this.onCheckConnection,
    this.onCheckApiKey,
  });

  @override
  State<HalamanPindai> createState() => _HalamanPindaiState();
}

class _HalamanPindaiState extends State<HalamanPindai> {
  bool _sedangMemindai = false;
  DocumentScanner? _scannerAktif;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PindaiCubit>().inisialisasi();
      if (widget.mulaiLangsung && mounted) {
        _jalankanPemindaiDokumen();
      }
    });
  }

  @override
  void dispose() {
    _scannerAktif?.close();
    super.dispose();
  }

  Future<bool> _cekKoneksi() async {
    if (widget.onCheckConnection != null) {
      return widget.onCheckConnection!();
    }
    try {
      final hasil = await InternetAddress.lookup('generativelanguage.googleapis.com')
          .timeout(const Duration(seconds: 3));
      return hasil.isNotEmpty && hasil[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _jalankanPemindaiDokumen() async {
    if (_sedangMemindai) return;

    final cubit = context.read<PindaiCubit>();
    // No 12: Kuota habis -> satu baris pemberitahuan lalu buka /catat
    if (cubit.state.sisaKuota <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kuota pemindaian pekan ini sudah habis')),
      );
      context.go('/catat');
      return;
    }

    setState(() {
      _sedangMemindai = true;
    });

    try {
      // No 33: Periksa kunci Gemini kosong SEBELUM pemindai dibuka
      final adaKunci = widget.onCheckApiKey != null
          ? widget.onCheckApiKey!()
          : GeminiClient.apiKey.trim().isNotEmpty;
      if (!adaKunci) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pindai struk belum aktif di versi ini'),
            ),
          );
          context.go('/catat');
        }
        return;
      }

      // No 13: Periksa koneksi SEBELUM pemindai dibuka (batas 3 detik)
      final terhubung = await _cekKoneksi();
      if (!terhubung) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada koneksi internet. Mengarahkan ke catat manual...'),
            ),
          );
          context.go('/catat');
        }
        return;
      }

      if (!mounted) return;

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
          _scannerAktif = scanner;
          try {
            final result = await scanner.scanDocument();
            images = result.images;
          } finally {
            await scanner.close();
            _scannerAktif = null;
          }
        }
      } on PlatformException catch (e) {
        // No 3: Menekan X di pemindai -> kembali diam-diam tanpa snackbar
        final msg = e.message?.toLowerCase() ?? '';
        final code = e.code.toLowerCase();
        if (msg.contains('cancel') || code.contains('cancel')) {
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka pemindai dokumen')),
          );
        }
        return;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka pemindai dokumen')),
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
      String? pathSiapKirim;

      try {
        // 2. Kecilkan citra ke sisi terpanjang maksimal 1024px menggunakan dart:ui
        pathSiapKirim = await GambarHelper.kompresDanKecilkanCitra(pathAsli);

        if (!mounted) return;

        // 3. Ambil daftar kategori aktif dari KategoriCubit untuk disisipkan ke prompt Gemini
        List<String> daftarKategori = [];
        Map<String, int> petaKategoriId = {};
        final katState = context.read<KategoriCubit>().state;
        if (katState is KategoriLoaded) {
          daftarKategori = katState.kategoriList
              .map((k) => k.nama.toLowerCase())
              .toList();
          petaKategoriId = {
            for (final k in katState.kategoriList)
              if (k.id != null) k.nama.toLowerCase().trim(): k.id!,
          };
        }

        // 4. Kirim ke Gemini AI
        await cubit.prosesPindai(
          imagePath: pathSiapKirim,
          daftarKategori: daftarKategori,
          petaKategoriId: petaKategoriId,
        );
      } finally {
        // No 16: Berkas sementara _1024.png selalu dihapus di finally setelah dikirim termasuk saat gagal
        await GambarHelper.hapusBerkasSementara(pathSiapKirim);
      }
    } finally {
      if (mounted) {
        setState(() {
          _sedangMemindai = false;
        });
      }
    }
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
                  return HalamanKonfirmasiPindai(hasilPindai: state.hasilPindai!);
                }

                return SafeArea(
                  bottom: false,
                  child: Column(
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
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                try {
                                  context.pop();
                                } catch (_) {}
                              }
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
                          Expanded(
                            child: Text(
                              'Pindai Struk',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
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
                                        '${state.sisaKuota} dari $kuotaPindaiPekanan tersisa',
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
                                    'Foto struk dikirim ke layanan Google Gemini untuk dibaca. Insap tidak menyimpan fotonya.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.inkSoft),
                                  ),
                                  const SizedBox(height: AppSpacing.besar),
                                  TextButton(
                                    onPressed: () {
                                      context.read<PindaiCubit>().batalkanPindai();
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
                                    isLoading: _sedangMemindai,
                                    onPressed: _sedangMemindai ? null : _jalankanPemindaiDokumen,
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TombolStabilo(
                                    teks: 'Buka Pemindai Struk',
                                    ikon: Icons.photo_camera_rounded,
                                    isLoading: _sedangMemindai,
                                    onPressed: _sedangMemindai ? null : _jalankanPemindaiDokumen,
                                  ),
                                  const SizedBox(height: AppSpacing.sedang),
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () => tampilkanDialogPanduanPindai(
                                        context,
                                        onLanjut: _jalankanPemindaiDokumen,
                                      ),
                                      icon: const Icon(
                                        Icons.help_outline_rounded,
                                        size: 18,
                                        color: AppColors.inkSoft,
                                      ),
                                      label: const Text(
                                        'Lihat panduan',
                                        style: TextStyle(
                                          color: AppColors.inkSoft,
                                          fontWeight: FontWeight.w700,
                                        ),
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
                  ],
                ),
              );
            },
            ),
          ),
        ),
      ),
    );
  }
}
