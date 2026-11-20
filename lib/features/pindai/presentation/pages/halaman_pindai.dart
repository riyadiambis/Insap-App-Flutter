import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import '../../../../core/constants/kuota_constants.dart';
import '../../../../core/network/gemini_client.dart';
import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/header_aplikasi.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/maskot_struki.dart';
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
  bool _sudahInisialisasi = false;
  DocumentScanner? _scannerAktif;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PindaiCubit>().inisialisasi();
      if (mounted) {
        setState(() {
          _sudahInisialisasi = true;
        });
      }
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
    if (cubit.state.sisaKuota <= 0) {
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
              content: Text(
                'Tidak ada koneksi internet. Mengarahkan ke catat manual...',
              ),
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
        final stopwatchPengecilan = Stopwatch()..start();
        // 2. Kecilkan citra ke sisi terpanjang maksimal 1024px menggunakan dart:ui
        pathSiapKirim = await GambarHelper.kompresDanKecilkanCitra(pathAsli);
        stopwatchPengecilan.stop();
        final msPengecilan = stopwatchPengecilan.elapsedMilliseconds;

        double ukuranKb = 0;
        try {
          final fileSiapKirim = File(pathSiapKirim);
          if (await fileSiapKirim.exists()) {
            ukuranKb = (await fileSiapKirim.length()) / 1024.0;
          }
        } catch (_) {}

        if (kDebugMode) {
          debugPrint(
            '[Pindai Struk][Debug] Lama mengecilkan citra: ${msPengecilan}ms | Ukuran berkas dikirim: ${ukuranKb.toStringAsFixed(2)}KB',
          );
        }

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

        final stopwatchMenunggu = Stopwatch()..start();
        // 4. Kirim ke Gemini AI
        await cubit.prosesPindai(
          imagePath: pathSiapKirim,
          daftarKategori: daftarKategori,
          petaKategoriId: petaKategoriId,
        );
        stopwatchMenunggu.stop();
        final msMenunggu = stopwatchMenunggu.elapsedMilliseconds;

        if (kDebugMode) {
          debugPrint(
            '[Pindai Struk][Debug] Lama menunggu jawaban Gemini: ${msMenunggu}ms',
          );
        }
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

  void _kembali(BuildContext context) {
    context.read<PindaiCubit>().reset();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.pop();
      } catch (_) {}
    }
  }

  void _bukaLangganan(BuildContext context) {
    context.push('/langganan');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PindaiCubit, PindaiState>(
      listenWhen: (prev, curr) => prev.statusKlaimBonus != curr.statusKlaimBonus,
      listener: (context, state) {
        if (state.statusKlaimBonus == StatusKlaimBonus.gagal) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Iklan belum tersedia atau belum selesai ditonton. Coba lagi sebentar lagi.',
                ),
              ),
            );
        } else if (state.statusKlaimBonus == StatusKlaimBonus.berhasil) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Yay, +1 pindai!')),
            );
        }
      },
      builder: (context, state) {
        // Jika Gemini berhasil mengekstrak dan butuh konfirmasi draf
        if (state.status == PindaiStatus.butuhKonfirmasi &&
            state.hasilPindai != null) {
          return HalamanKonfirmasiPindai(hasilPindai: state.hasilPindai!);
        }

        final bool kuotaHabis =
            state.status == PindaiStatus.awal &&
            _sudahInisialisasi &&
            state.sisaKuota <= 0;

        return Scaffold(
          appBar: HeaderAplikasi(
            namaLayar: 'Pindai Struk',
            modeKembali: true,
            onKembali: () => _kembali(context),
          ),
          body: PaperBackground(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.batasLebarKonten,
                ),
                padding: const EdgeInsets.all(AppSpacing.besar),
                child: _bangunKonten(context, state, kuotaHabis),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bangunKonten(
    BuildContext context,
    PindaiState state,
    bool kuotaHabis,
  ) {
    if (state.status == PindaiStatus.memuat) {
      return KartuMemuatPindai(
        onBatalkan: () {
          context.read<PindaiCubit>().batalkanPindai();
        },
      );
    }

    if (state.status == PindaiStatus.gagal) {
      return _TampilanPindaiGagal(
        pesanGalat: state.pesanGalat,
        tawarkanCatatManual: state.tawarkanCatatManual,
        sedangMemindai: _sedangMemindai,
        onPindaiUlang: _jalankanPemindaiDokumen,
        onCatatManual: () => context.go('/catat'),
      );
    }

    if (kuotaHabis) {
      return _TampilanKuotaHabis(
        sisaBonusIklan: state.sisaBonusIklan,
        sedangMemuatBonus: state.statusKlaimBonus == StatusKlaimBonus.sedang,
        onTontonIklan: () => context.read<PindaiCubit>().klaimBonusIklan(),
        onBukaLangganan: () => _bukaLangganan(context),
        onCatatManual: () => context.go('/catat'),
      );
    }

    // Tampilan Awal / Siap Memindai
    return ListView(
      children: [
        KartuBukuTulis(
          backgroundColor: AppColors.kartu,
          shadow: AppTheme.bayanganGelap,
          pressedShadow: AppTheme.bayanganGelapTertekan,
          padding: const EdgeInsets.all(AppSpacing.sedang),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.agakKecil),
                decoration: BoxDecoration(
                  color: AppColors.stabilo,
                  borderRadius: BorderRadius.circular(
                    AppSizes.radiusKotakIkonAksi,
                  ),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.border,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kuota Pindai Pekan Ini',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                    ),
                    Text(
                      '${state.sisaKuota} dari $kuotaPindaiPekanan tersisa',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: state.sisaKuota <= 0
                                ? AppColors.merahTeks
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
        KartuBukuTulis(
          backgroundColor: AppColors.kartu,
          shadow: AppTheme.bayanganGelap,
          pressedShadow: AppTheme.bayanganGelapTertekan,
          padding: const EdgeInsets.all(AppSpacing.besar),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TombolStabilo(
                teks: 'Buka Pemindai Struk',
                ikon: Icons.qr_code_scanner_rounded,
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
    );
  }
}

class _TampilanPindaiGagal extends StatelessWidget {
  final String? pesanGalat;
  final bool tawarkanCatatManual;
  final bool sedangMemindai;
  final VoidCallback onPindaiUlang;
  final VoidCallback onCatatManual;

  const _TampilanPindaiGagal({
    required this.pesanGalat,
    required this.tawarkanCatatManual,
    required this.sedangMemindai,
    required this.onPindaiUlang,
    required this.onCatatManual,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sedang),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MaskotStruki(pose: PoseMaskot.puyeng, ukuran: 210),
                  const SizedBox(height: AppSpacing.sedang),
                  Text(
                    'Struknya belum terbaca',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.kecil),
                  Text(
                    pesanGalat ??
                        'Tulisannya terlalu buram buat Struki. Coba foto lagi di tempat terang, struk diratakan.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          color: AppColors.inkSoft,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sedang),
        TombolStabilo(
          teks: 'Coba Pindai Ulang',
          ikon: Icons.refresh_rounded,
          isLoading: sedangMemindai,
          onPressed: sedangMemindai ? null : onPindaiUlang,
        ),
        if (tawarkanCatatManual) ...[
          const SizedBox(height: AppSpacing.sedang),
          _TombolPutih(
            teks: 'Catat Manual Saja',
            ikon: Icons.edit_note_rounded,
            onPressed: onCatatManual,
          ),
        ],
      ],
    );
  }
}

class _TampilanKuotaHabis extends StatelessWidget {
  final int sisaBonusIklan;
  final bool sedangMemuatBonus;
  final VoidCallback onTontonIklan;
  final VoidCallback onBukaLangganan;
  final VoidCallback onCatatManual;

  const _TampilanKuotaHabis({
    required this.sisaBonusIklan,
    required this.sedangMemuatBonus,
    required this.onTontonIklan,
    required this.onBukaLangganan,
    required this.onCatatManual,
  });

  @override
  Widget build(BuildContext context) {
    final bool bisaTonton = !sedangMemuatBonus && sisaBonusIklan > 0;
    final String teksTombolBonus = sisaBonusIklan <= 0
        ? 'Bonus iklan pekan ini sudah habis'
        : 'Tonton iklan, dapat +1 pindai';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sedang),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MaskotStruki(pose: PoseMaskot.cukup, ukuran: 170),
                  const SizedBox(height: AppSpacing.sedang),
                  Text(
                    'Jatah pindai pekan ini habis',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.kecil),
                  Text(
                    'Kamu sudah memakai $kuotaPindaiPekanan dari $kuotaPindaiPekanan pindai. Jatah kembali penuh hari Senin.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          color: AppColors.inkSoft,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sedang),
        Semantics(
          button: true,
          enabled: bisaTonton,
          label: teksTombolBonus,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: TombolStabilo(
              key: const Key('tombol_bonus_iklan'),
              teks: teksTombolBonus,
              ikon: sisaBonusIklan <= 0 ? null : Icons.play_arrow_rounded,
              isLoading: sedangMemuatBonus,
              onPressed: bisaTonton ? onTontonIklan : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.kecil),
        Text(
          'Sisa bonus pekan ini: $sisaBonusIklan dari $bonusIklanMaksimalPekanan',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sedang),
        KartuBukuTulis(
          onTap: onBukaLangganan,
          backgroundColor: AppColors.kartu,
          shadow: AppTheme.bayanganGelap,
          pressedShadow: AppTheme.bayanganGelapTertekan,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.stabilo,
                  borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.border,
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sedang),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Butuh lebih banyak?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                    ),
                    Text(
                      'Plus 50 pindai, Pro 100 pindai per pekan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.ink,
                size: 22,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sedang),
        _TombolPutih(
          teks: 'Catat manual',
          ikon: Icons.edit_rounded,
          onPressed: onCatatManual,
        ),
      ],
    );
  }
}

class _TombolPutih extends StatefulWidget {
  final String teks;
  final IconData? ikon;
  final VoidCallback onPressed;

  const _TombolPutih({
    required this.teks,
    this.ikon,
    required this.onPressed,
  });

  @override
  State<_TombolPutih> createState() => _TombolPutihState();
}

class _TombolPutihState extends State<_TombolPutih> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const geser = AppSizes.geserTekan;

    return Semantics(
      button: true,
      label: widget.teks,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: AnimatedContainer(
            duration: AppDurations.animasiTekan,
            height: AppSizes.tinggiTombol,
            margin: EdgeInsets.only(
              left: _isPressed ? geser : 0,
              top: _isPressed ? geser : 0,
              right: _isPressed ? 0 : geser,
              bottom: _isPressed ? 0 : geser,
            ),
            decoration: BoxDecoration(
              color: AppColors.kartu,
              border: Border.all(color: AppColors.ink, width: AppSizes.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
              boxShadow: [
                _isPressed
                    ? AppTheme.bayanganGelapTertekan
                    : const BoxShadow(
                        color: AppColors.ink,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.ikon != null) ...[
                    Icon(widget.ikon, size: AppSizes.ikonAksi, color: AppColors.ink),
                    const SizedBox(width: AppSpacing.kecil),
                  ],
                  Text(
                    widget.teks,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
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

/// Widget kartu memuat dengan teks tunggu bertahap (K2, ISSUE-32).
///
/// Berubah bertahap:
/// - 0..14 detik: "Menganalisis Struk dengan AI..."
/// - setelah 15 detik: "Struknya agak panjang, masih dibaca..."
/// - setelah 45 detik: "Masih menunggu jawaban. Kalau terlalu lama, ketuk Batalkan lalu catat manual."
/// Kalimat privasi dan tombol Batalkan tetap tampil.
class KartuMemuatPindai extends StatefulWidget {
  final VoidCallback onBatalkan;

  const KartuMemuatPindai({
    super.key,
    required this.onBatalkan,
  });

  @override
  State<KartuMemuatPindai> createState() => _KartuMemuatPindaiState();
}

class _KartuMemuatPindaiState extends State<KartuMemuatPindai> {
  Timer? _timer15;
  Timer? _timer45;
  String _teksTunggu = 'Menganalisis Struk dengan AI...';
  double _progres = 0.45;

  @override
  void initState() {
    super.initState();
    _mulaiTimer();
  }

  void _mulaiTimer() {
    _timer15 = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _teksTunggu = 'Struknya agak panjang, masih dibaca...';
          _progres = 0.72;
        });
      }
    });

    _timer45 = Timer(const Duration(seconds: 45), () {
      if (mounted) {
        setState(() {
          _teksTunggu =
              'Masih menunggu jawaban. Kalau terlalu lama, ketuk Batalkan lalu catat manual.';
          _progres = 0.90;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer15?.cancel();
    _timer45?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sedang),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MaskotStruki(pose: PoseMaskot.scan, ukuran: 210),
                  const SizedBox(height: AppSpacing.sedang),
                  Text(
                    _teksTunggu,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.kecil),
                  Text(
                    'Foto struk dikirim ke layanan Google Gemini untuk dibaca. Insap tidak menyimpan fotonya.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          color: AppColors.inkSoft,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.besar),
                  Container(
                    width: 220,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.kartu,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppSizes.border,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progres,
                        child: Container(color: AppColors.daun),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sedang),
        _TombolPutih(
          teks: 'Batalkan',
          onPressed: widget.onBatalkan,
        ),
      ],
    );
  }
}
