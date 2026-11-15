import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme.dart';
import '../tur/langkah_tur.dart';
import '../tur/tur_cubit.dart';
import '../tur/tur_state.dart';

/// Lapisan gelap di atas layar utama yang menyorot satu widget per langkah
/// dan menampilkan balon penjelasan dengan tombol Lanjut (ISSUE-37).
class LapisanTur extends StatefulWidget {
  final TurCubit cubit;
  final List<LangkahTur> langkah;

  /// Dipanggil saat petunjuk mulai, supaya layar pindah ke tab Beranda.
  final VoidCallback? onMulai;

  /// Dipanggil saat pengguna memilih Daftar Akun di langkah terakhir.
  final VoidCallback? onDaftarAkun;

  const LapisanTur({
    super.key,
    required this.cubit,
    required this.langkah,
    this.onMulai,
    this.onDaftarAkun,
  });

  @override
  State<LapisanTur> createState() => _LapisanTurState();
}

class _LapisanTurState extends State<LapisanTur> {
  @override
  void initState() {
    super.initState();
    widget.cubit.periksa();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TurCubit, TurState>(
      bloc: widget.cubit,
      listenWhen: (lama, baru) => !lama.aktif && baru.aktif,
      listener: (context, state) => widget.onMulai?.call(),
      builder: (context, state) {
        if (!state.aktif || state.indeks >= widget.langkah.length) {
          return const SizedBox.shrink();
        }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (sudahKeluar, hasil) {
            if (!sudahKeluar) widget.cubit.selesai();
          },
          child: _SorotanLangkah(
            key: ValueKey('langkah_tur_${state.indeks}'),
            langkah: widget.langkah[state.indeks],
            indeks: state.indeks,
            jumlah: widget.langkah.length,
            sudahMasuk: state.sudahMasuk,
            onLanjut: widget.cubit.lanjut,
            onKembali: widget.cubit.kembali,
            onSelesai: widget.cubit.selesai,
            onDaftarAkun: () async {
              await widget.cubit.selesai();
              widget.onDaftarAkun?.call();
            },
          ),
        );
      },
    );
  }
}

class _SorotanLangkah extends StatefulWidget {
  final LangkahTur langkah;
  final int indeks;
  final int jumlah;
  final bool sudahMasuk;
  final VoidCallback onLanjut;
  final VoidCallback onKembali;
  final VoidCallback onSelesai;
  final VoidCallback onDaftarAkun;

  const _SorotanLangkah({
    super.key,
    required this.langkah,
    required this.indeks,
    required this.jumlah,
    required this.sudahMasuk,
    required this.onLanjut,
    required this.onKembali,
    required this.onSelesai,
    required this.onDaftarAkun,
  });

  @override
  State<_SorotanLangkah> createState() => _SorotanLangkahState();
}

class _SorotanLangkahState extends State<_SorotanLangkah> {
  // targetnya bisa belum ada (beranda masih memuat), jadi dicoba beberapa kali
  static const int _maksPercobaan = 20;
  static const Duration _jedaPercobaan = Duration(milliseconds: 100);

  Rect? _target;
  int _percobaan = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cariTarget());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _cariTarget() {
    if (!mounted) return;
    final konteksTarget = widget.langkah.kunci.currentContext;
    final kotakTarget = konteksTarget?.findRenderObject();
    final kotakSendiri = context.findRenderObject();

    if (konteksTarget != null &&
        kotakTarget is RenderBox &&
        kotakTarget.attached &&
        kotakTarget.hasSize &&
        kotakSendiri is RenderBox &&
        kotakSendiri.hasSize) {
      // gulir dulu kalau targetnya di bawah lipatan, baru ukur posisinya
      Scrollable.ensureVisible(konteksTarget, alignment: 0.3);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !kotakTarget.attached) return;
        final posisi = kotakTarget.localToGlobal(
          Offset.zero,
          ancestor: kotakSendiri,
        );
        setState(() => _target = posisi & kotakTarget.size);
      });
      WidgetsBinding.instance.scheduleFrame();
      return;
    }

    _percobaan++;
    if (_percobaan >= _maksPercobaan) {
      // widgetnya tidak ada di layar ini, lompat ke langkah berikutnya
      widget.onLanjut();
      return;
    }
    _timer = Timer(_jedaPercobaan, _cariTarget);
  }

  bool get _langkahTerakhir => widget.indeks == widget.jumlah - 1;

  @override
  Widget build(BuildContext context) {
    final target = _target;
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, batas) {
          final ukuran = batas.biggest;
          return Stack(
            children: [
              // menelan semua ketukan supaya layar di bawahnya tidak ikut tertekan
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: CustomPaint(painter: _PelukisSorotan(target: target)),
                ),
              ),
              if (target != null) _bangunBalon(context, target, ukuran),
            ],
          );
        },
      ),
    );
  }

  Widget _bangunBalon(BuildContext context, Rect target, Size ukuran) {
    final balonDiBawah = target.center.dy < ukuran.height / 2;
    const jarak = AppSpacing.besar + _PelukisSorotan.lebihan;

    return Positioned(
      left: AppSpacing.besar,
      right: AppSpacing.besar,
      top: balonDiBawah ? target.bottom + jarak : null,
      bottom: balonDiBawah ? null : ukuran.height - target.top + jarak,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.batasLebarKonten - AppSpacing.antarBagian,
          ),
          child: _bangunKartu(context),
        ),
      ),
    );
  }

  Widget _bangunKartu(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final akunSudahMasuk = _langkahTerakhir && widget.sudahMasuk;
    final judul = akunSudahMasuk ? judulAkunSudahMasuk : widget.langkah.judul;
    final isi = akunSudahMasuk ? isiAkunSudahMasuk : widget.langkah.isi;

    return Container(
      key: const Key('balon_tur'),
      padding: const EdgeInsets.all(AppSpacing.besar),
      decoration: BoxDecoration(
        color: AppColors.kartu,
        border: Border.all(color: AppColors.ink, width: AppSizes.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
        boxShadow: const [AppTheme.bayanganGelap],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LANGKAH ${widget.indeks + 1} DARI ${widget.jumlah}',
            style: teks.labelSmall?.copyWith(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sangatKecil),
          Text(
            judul,
            style: teks.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.kecil),
          Text(isi, style: teks.bodyMedium?.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.sedang),
          // Wrap, bukan Row: di layar sempit tombolnya turun baris, tidak meluber
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sangatKecil,
              runSpacing: AppSpacing.sangatKecil,
              children: [
                _bangunTombolKiri(),
                if (widget.indeks > 0)
                  TextButton(
                    key: const Key('tombol_tur_kembali'),
                    onPressed: widget.onKembali,
                    child: const Text('Kembali'),
                  ),
                _bangunTombolUtama(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunTombolKiri() {
    // di langkah akun, pilihan menolak ditulis jelas: "Nanti saja"
    final ajakDaftar = _langkahTerakhir && !widget.sudahMasuk;
    if (_langkahTerakhir && !ajakDaftar) return const SizedBox.shrink();
    return TextButton(
      key: Key(ajakDaftar ? 'tombol_tur_nanti' : 'tombol_tur_lewati'),
      onPressed: widget.onSelesai,
      child: Text(ajakDaftar ? 'Nanti saja' : 'Lewati'),
    );
  }

  Widget _bangunTombolUtama() {
    final gaya = FilledButton.styleFrom(
      backgroundColor: AppColors.stabilo,
      foregroundColor: AppColors.ink,
      side: const BorderSide(color: AppColors.ink, width: AppSizes.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    );

    if (!_langkahTerakhir) {
      return FilledButton(
        key: const Key('tombol_tur_lanjut'),
        style: gaya,
        onPressed: widget.onLanjut,
        child: const Text('Lanjut'),
      );
    }
    if (widget.sudahMasuk) {
      return FilledButton(
        key: const Key('tombol_tur_selesai'),
        style: gaya,
        onPressed: widget.onSelesai,
        child: const Text('Selesai'),
      );
    }
    return FilledButton(
      key: const Key('tombol_tur_daftar'),
      style: gaya,
      onPressed: widget.onDaftarAkun,
      child: const Text('Daftar Akun'),
    );
  }
}

/// Menggambar lapisan gelap dengan lubang di sekitar widget yang disorot.
class _PelukisSorotan extends CustomPainter {
  /// Jarak lubang dari tepi widget, biar sorotannya tidak mepet.
  static const double lebihan = 6.0;

  final Rect? target;

  const _PelukisSorotan({required this.target});

  @override
  void paint(Canvas canvas, Size size) {
    final gelap = Paint()..color = AppColors.ink.withValues(alpha: 0.72);
    final layar = Path()..addRect(Offset.zero & size);
    final sasaran = target;

    if (sasaran == null) {
      canvas.drawPath(layar, gelap);
      return;
    }

    final lubang = RRect.fromRectAndRadius(
      sasaran.inflate(lebihan),
      const Radius.circular(AppSizes.radiusTombol),
    );
    canvas.drawPath(
      Path.combine(PathOperation.difference, layar, Path()..addRRect(lubang)),
      gelap,
    );
    canvas.drawRRect(
      lubang,
      Paint()
        ..color = AppColors.stabilo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
  }

  @override
  bool shouldRepaint(_PelukisSorotan lama) => lama.target != target;
}
