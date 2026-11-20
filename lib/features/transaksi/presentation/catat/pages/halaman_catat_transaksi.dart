import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/paper_background.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/utils/iso_week.dart';
import '../../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../../core/widgets/tombol_stabilo.dart';
import '../../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../../kategori/domain/entities/kategori_entity.dart';
import '../../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../../kategori/presentation/cubit/kategori_state.dart';
import '../../riwayat/cubit/riwayat_cubit.dart';
import '../cubit/catat_transaksi_cubit.dart';
import '../cubit/catat_transaksi_state.dart';
import '../widgets/kolom_input_nominal.dart';

// helper parse warna hex dari basis data
Color _parseWarna(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) hexColor = 'FF$hexColor';
  return Color(int.parse(hexColor, radix: 16));
}

IconData _parseIkon(String namaIkon) {
  switch (namaIkon) {
    case 'restaurant':
      return Icons.restaurant;
    case 'two_wheeler':
      return Icons.two_wheeler;
    case 'home':
      return Icons.home;
    case 'school':
      return Icons.school;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'local_cafe':
      return Icons.local_cafe;
    case 'sports_esports':
      return Icons.sports_esports;
    case 'medical_services':
      return Icons.medical_services;
    case 'more_horiz':
    default:
      return Icons.more_horiz;
  }
}

String _kapitalPertama(String teks) {
  if (teks.isEmpty) return teks;
  return teks[0].toUpperCase() + teks.substring(1);
}

const List<String> _namaHariId = [
  '',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const List<String> _namaBulanId = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _formatTanggalIndonesia(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;
  final hari = _namaHariId[parsed.weekday];
  final bulan = _namaBulanId[parsed.month];
  return '$hari, ${parsed.day} $bulan ${parsed.year}';
}

// F-01, Tahap 8. CatatTransaksiCubit disediakan di sini lewat
// BlocProvider yang ambil dari sl, bukan di main.dart
class HalamanCatatTransaksi extends StatelessWidget {
  const HalamanCatatTransaksi({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CatatTransaksiCubit>(),
      child: const _CatatTransaksiView(),
    );
  }
}

class _CatatTransaksiView extends StatefulWidget {
  const _CatatTransaksiView();

  @override
  State<_CatatTransaksiView> createState() => _CatatTransaksiViewState();
}

class _CatatTransaksiViewState extends State<_CatatTransaksiView> {
  final _formKey = GlobalKey<FormState>();
  final _catatanController = TextEditingController();
  final _nominalFocusNode = FocusNode();

  // nominal disimpan di state lokal untuk sinkronisasi ke KolomInputNominal
  int _nominal = 0;

  @override
  void initState() {
    super.initState();
    // papan ketik langsung terbuka di kolom nominal (F-01)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nominalFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _nominalFocusNode.dispose();
    super.dispose();
  }

  void _onNominalChanged(int angka) {
    setState(() => _nominal = angka);
    context.read<CatatTransaksiCubit>().ubahNominal(angka);
  }

  Future<void> _pilihTanggal(BuildContext context, String tanggalSekarang) async {
    final cubit = context.read<CatatTransaksiCubit>();
    final sekarang = DateTime.now();
    final awal = DateTime.tryParse(tanggalSekarang) ?? sekarang;
    final initialDate = awal.isAfter(sekarang) ? sekarang : awal;

    // datepicker, tanggal masa depan ditolak (F-01)
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: sekarang,
    );
    if (picked != null && context.mounted) {
      cubit.pilihTanggal(formatTanggalIso(picked));
    }
  }

  void _simpan() {
    // FocusScope unfocus saat simpan (P04-Form)
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // validasi kategori di sisi cubit (formState cuma urus nominal)
    final state = context.read<CatatTransaksiCubit>().state;
    if (state.kategoriId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kategori wajib dipilih.')));
      return;
    }

    // update catatan terakhir ke cubit
    final catatan = _catatanController.text.trim();
    context.read<CatatTransaksiCubit>().ubahCatatan(
      catatan.isEmpty ? null : catatan,
    );

    context.read<CatatTransaksiCubit>().simpan();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CatatTransaksiCubit, CatatTransaksiState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == StatusCatatTransaksi.berhasil) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil disimpan!')),
          );
          // muat ulang ringkasan beranda biar langsung update (F-05)
          context.read<BerandaCubit>().muatRingkasan();
          // riwayat juga, soalnya tab-nya nggak dibangun ulang (ISSUE-16)
          context.read<RiwayatCubit>().muatRiwayat();
          // kembali ke tab beranda
          context.go('/');
          _catatanController.clear();
          setState(() {
            _nominal = 0;
          });
          context.read<CatatTransaksiCubit>().reset();
        } else if (state.status == StatusCatatTransaksi.gagal) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.pesanKesalahan ?? 'Gagal menyimpan.')),
          );
        }
      },
      child: Scaffold(
        body: PaperBackground(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.batasLebarKonten,
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.besar,
                    top: AppSpacing.besar,
                    right: AppSpacing.besar,
                    bottom: AppSpacing.jarakGulirBawah,
                  ),
                  children: [
                    // 1. NOMINAL
                    _BagianNominal(
                      nominal: _nominal,
                      focusNode: _nominalFocusNode,
                      onChanged: _onNominalChanged,
                      onHapus: () => _onNominalChanged(0),
                    ),
                    const SizedBox(height: 14),

                    // 2. KATEGORI (kisi 3 kolom petak seragam tinggi 76)
                    _BagianKategori(),

                    // Kartu butuh/pengen (muncul cuma buat opsional & hiburan)
                    _BagianButuhPengen(),
                    const SizedBox(height: 14),

                    // 3. CATATAN
                    _BagianCatatan(controller: _catatanController),
                    const SizedBox(height: 14),

                    // 4. TANGGAL
                    BlocSelector<CatatTransaksiCubit, CatatTransaksiState,
                        String>(
                      selector: (state) => state.tanggal,
                      builder: (context, tanggal) {
                        return _BagianTanggal(
                          tanggal: tanggal,
                          onTap: () => _pilihTanggal(context, tanggal),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lebihBesar),

                    // 5. Tombol Simpan
                    BlocBuilder<CatatTransaksiCubit, CatatTransaksiState>(
                      buildWhen: (prev, curr) => prev.status != curr.status,
                      builder: (context, state) {
                        return TombolStabilo(
                          teks: 'Simpan Transaksi',
                          ikon: Icons.check_rounded,
                          isLoading:
                              state.status == StatusCatatTransaksi.menyimpan,
                          onPressed: _simpan,
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
    );
  }
}

class _BagianNominal extends StatelessWidget {
  final int nominal;
  final FocusNode focusNode;
  final ValueChanged<int> onChanged;
  final VoidCallback onHapus;

  const _BagianNominal({
    required this.nominal,
    required this.focusNode,
    required this.onChanged,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NOMINAL',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
            ),
            if (nominal > 0)
              GestureDetector(
                onTap: onHapus,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.backspace_outlined,
                      size: AppSizes.ikonKecil,
                      color: AppColors.inkSoft,
                    ),
                    const SizedBox(width: AppSpacing.sangatKecil),
                    Text(
                      'Hapus',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.kecil),
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: AppSpacing.kecil,
          ),
          decoration: BoxDecoration(
            color: AppColors.kartu,
            border: Border.all(
              color: AppColors.ink,
              width: AppSizes.border,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonKuota),
            boxShadow: const [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.centerLeft,
          child: KolomInputNominal(
            nominal: nominal,
            focusNode: focusNode,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _BagianTanggal extends StatelessWidget {
  final String tanggal;
  final VoidCallback onTap;

  const _BagianTanggal({required this.tanggal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TANGGAL',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.kecil),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonKuota),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.kartu,
              border: Border.all(
                color: AppColors.ink,
                width: AppSizes.border,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonKuota),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatTanggalIndonesia(tanggal),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.kecil),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.ink,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// grid kategori 3 kolom, dari KategoriCubit (Keputusan E: nama dari db,
// huruf pertama kapital)
class _BagianKategori extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'KATEGORI',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
            ),
            Text(
              'Wajib 1',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.kecil),
        BlocBuilder<KategoriCubit, KategoriState>(
          builder: (context, kategoriState) {
            if (kategoriState is KategoriLoading ||
                kategoriState is KategoriInitial) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.besar),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                  ),
                ),
              );
            }
            if (kategoriState is KategoriError) {
              return Text('Gagal memuat kategori: ${kategoriState.pesan}');
            }
            final daftar = (kategoriState as KategoriLoaded).kategoriList;
            return BlocSelector<CatatTransaksiCubit, CatatTransaksiState, int?>(
              selector: (state) => state.kategoriId,
              builder: (context, kategoriIdTerpilih) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final double lebarItem =
                        (constraints.maxWidth -
                            AppSpacing.kecil * (AppSizes.kolomKategori - 1)) /
                        AppSizes.kolomKategori;
                    return Wrap(
                      spacing: AppSpacing.kecil,
                      runSpacing: AppSpacing.kecil,
                      children: daftar.map((k) {
                        final terpilih = k.id == kategoriIdTerpilih;
                        return SizedBox(
                          width: lebarItem,
                          height: 76,
                          child: _ChipKategori(
                            kategori: k,
                            terpilih: terpilih,
                            onTap: () {
                              context.read<CatatTransaksiCubit>().pilihKategori(
                                k.id!,
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// satu petak kategori seragam tinggi 76: petak ikon berwarna + nama di bawah
class _ChipKategori extends StatefulWidget {
  final KategoriEntity kategori;
  final bool terpilih;
  final VoidCallback onTap;

  const _ChipKategori({
    required this.kategori,
    required this.terpilih,
    required this.onTap,
  });

  @override
  State<_ChipKategori> createState() => _ChipKategoriState();
}

class _ChipKategoriState extends State<_ChipKategori> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final warna = _parseWarna(widget.kategori.warna);
    final ikon = _parseIkon(widget.kategori.ikon);

    return Semantics(
      selected: widget.terpilih,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.animasiTekan,
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sangatKecil),
          decoration: BoxDecoration(
            color: widget.terpilih ? AppColors.kuningMuda : AppColors.kartu,
            border: Border.all(
              color: widget.terpilih ? AppColors.ink : AppColors.garisPutus,
              width: widget.terpilih ? 3.0 : AppSizes.border,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
            boxShadow: widget.terpilih
                ? [
                    _isPressed
                        ? AppTheme.bayanganGelapTertekan
                        : const BoxShadow(
                            color: AppColors.ink,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.terpilih)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.check_rounded,
                    size: AppSizes.ikonKecil,
                    color: AppColors.ink,
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: warna,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppSizes.border,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        ikon,
                        color: AppColors.ikonBadge,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.agakKecil),
                  Text(
                    _kapitalPertama(widget.kategori.nama),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 13,
                          letterSpacing: 0,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// kartu butuh/pengen, HANYA muncul untuk kelompok opsional dan hiburan
// (KATEGORI.md). muncul dengan animasi naik ~200ms. boleh dilewati,
// tersimpan NULL (Keputusan D)
class _BagianButuhPengen extends StatelessWidget {
  static const Set<String> _kelompokTanyaNiat = {'opsional', 'hiburan'};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatatTransaksiCubit, CatatTransaksiState>(
      buildWhen: (prev, curr) =>
          prev.kategoriId != curr.kategoriId ||
          prev.tipeKebutuhan != curr.tipeKebutuhan,
      builder: (context, state) {
        final kategoriId = state.kategoriId;
        if (kategoriId == null) return const SizedBox();

        final kategoriCubit = context.read<KategoriCubit>();
        final kategori = kategoriCubit.kategoriById(kategoriId);
        if (kategori == null) return const SizedBox();

        final kelompok = kategori.kelompokKakeibo;
        final tampil = _kelompokTanyaNiat.contains(kelompok);

        return AnimatedSize(
          duration: AppDurations.animasiMunculKartu,
          curve: Curves.easeOut,
          child: tampil
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.besar),
                  child: KartuBukuTulis(
                    radius: AppSizes.radiusTombol,
                    shadow: AppTheme.bayanganGelap,
                    pressedShadow: AppTheme.bayanganGelapTertekan,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ini butuh atau pengen?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: AppSpacing.mini),
                                  Text(
                                    'Jujur ke diri sendiri, yuk sadari niat belanjamu.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.inkSoft,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.kecil),
                            Container(
                              width: AppSizes.kotakIkonAksi,
                              height: AppSizes.kotakIkonAksi,
                              decoration: BoxDecoration(
                                color: AppColors.stabilo,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: AppSizes.border,
                                ),
                                boxShadow: const [AppTheme.bayanganKecilGelap],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.psychology_alt,
                                  size: AppSizes.ikonAksi,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sedang),
                        Row(
                          children: [
                            Expanded(
                              child: _ChipButuhPengen(
                                label: 'Butuh',
                                ikon: Icons.eco_outlined,
                                terpilih: state.tipeKebutuhan == 'butuh',
                                warnaTerpilih: AppColors.stabilo,
                                onTap: () {
                                  final cubit = context
                                      .read<CatatTransaksiCubit>();
                                  if (state.tipeKebutuhan == 'butuh') {
                                    cubit.pilihTipeKebutuhan(null);
                                  } else {
                                    cubit.pilihTipeKebutuhan('butuh');
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sedang),
                            Expanded(
                              child: _ChipButuhPengen(
                                label: 'Pengen',
                                ikon: Icons.auto_awesome,
                                terpilih: state.tipeKebutuhan == 'pengen',
                                warnaTerpilih: AppColors.aksenPengen,
                                onTap: () {
                                  final cubit = context
                                      .read<CatatTransaksiCubit>();
                                  if (state.tipeKebutuhan == 'pengen') {
                                    cubit.pilihTipeKebutuhan(null);
                                  } else {
                                    cubit.pilihTipeKebutuhan('pengen');
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sedang),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sedang,
                            vertical: AppSpacing.kecil,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.kuningMuda,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusKotakIkonAksi,
                            ),
                            border: Border.all(
                              color: AppColors.ink,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.tips_and_updates_outlined,
                                size: AppSizes.ikonKalender,
                                color: AppColors.ink,
                              ),
                              const SizedBox(width: AppSpacing.kecil),
                              Expanded(
                                child: Text(
                                  'Nggak ada jawaban salah. Nanti kamu lihat '
                                  'sendiri polanya di refleksi Minggu.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
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
                  ),
                )
              : const SizedBox(),
        );
      },
    );
  }
}

// chip butuh atau pengen
class _ChipButuhPengen extends StatefulWidget {
  final String label;
  final IconData ikon;
  final bool terpilih;
  final Color warnaTerpilih;
  final VoidCallback onTap;

  const _ChipButuhPengen({
    required this.label,
    required this.ikon,
    required this.terpilih,
    required this.warnaTerpilih,
    required this.onTap,
  });

  @override
  State<_ChipButuhPengen> createState() => _ChipButuhPengenState();
}

class _ChipButuhPengenState extends State<_ChipButuhPengen> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppDurations.animasiTekan,
        height: AppSizes.tinggiPilihanKebutuhan,
        decoration: BoxDecoration(
          color: widget.terpilih ? widget.warnaTerpilih : AppColors.kartu,
          border: Border.all(color: AppColors.ink, width: AppSizes.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonAksi),
          boxShadow: [
            _isPressed
                ? AppTheme.bayanganGelapTertekan
                : (widget.terpilih
                      ? AppTheme.bayanganKecilGelap
                      : AppTheme.bayanganKecil),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.ikon,
              size: AppSizes.ikonKalender,
              color: AppColors.ink,
            ),
            const SizedBox(width: AppSpacing.agakKecil),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: widget.terpilih
                        ? FontWeight.w800
                        : FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// kolom catatan opsional, max 100 karakter
class _BagianCatatan extends StatelessWidget {
  final TextEditingController controller;

  const _BagianCatatan({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATATAN',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.kecil),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.kartu,
            border: Border.all(color: AppColors.ink, width: AppSizes.border),
            borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonKuota),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: AppSizes.ikonNavigasi,
                color: AppColors.inkSoft,
              ),
              const SizedBox(width: AppSpacing.kecil),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  maxLength: AppConstraints.maxPanjangCatatan,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                  decoration: InputDecoration(
                    hintText: 'Tambah catatan (misal: Es kopi sama temen)...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                    border: InputBorder.none,
                    counterText: '',
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
