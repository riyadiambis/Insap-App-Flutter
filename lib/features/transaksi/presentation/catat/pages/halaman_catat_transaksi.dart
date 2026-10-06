import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/paper_background.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/utils/iso_week.dart';
import '../../../../../core/utils/rupiah_extension.dart';
import '../../../../../core/widgets/header_aplikasi.dart';
import '../../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../../core/widgets/tombol_stabilo.dart';
import '../../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../../kategori/domain/entities/kategori_entity.dart';
import '../../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../../kategori/presentation/cubit/kategori_state.dart';
import '../cubit/catat_transaksi_cubit.dart';
import '../cubit/catat_transaksi_state.dart';

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
  final _nominalController = TextEditingController();
  final _catatanController = TextEditingController();
  final _nominalFocusNode = FocusNode();

  // chip tanggal: 0 = Hari ini, 1 = Kemarin, 2 = Pilih
  int _chipTanggalAktif = 0;

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
    _nominalController.dispose();
    _catatanController.dispose();
    _nominalFocusNode.dispose();
    super.dispose();
  }

  // parse angka dari teks yang sudah diformat Rp
  int _parseNominal(String teks) {
    final cleaned = teks.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  // format angka sambil diketik jadi Rp
  void _onNominalChanged(String value) {
    final angka = _parseNominal(value);
    context.read<CatatTransaksiCubit>().ubahNominal(angka);

    // update tampilan format rupiah
    if (angka > 0) {
      final formatted = angka.toRupiah();
      _nominalController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else if (value.isNotEmpty) {
      _nominalController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
  }

  void _pilihTanggal(BuildContext context, int chipIndex) async {
    final cubit = context.read<CatatTransaksiCubit>();
    final sekarang = DateTime.now();

    if (chipIndex == 0) {
      // hari ini
      cubit.pilihTanggal(formatTanggalIso(sekarang));
    } else if (chipIndex == 1) {
      // kemarin
      final kemarin = sekarang.subtract(const Duration(days: 1));
      cubit.pilihTanggal(formatTanggalIso(kemarin));
    } else {
      // datepicker, tanggal masa depan ditolak (F-01)
      final picked = await showDatePicker(
        context: context,
        initialDate: sekarang,
        firstDate: DateTime(2020),
        lastDate: sekarang,
      );
      if (picked != null && context.mounted) {
        cubit.pilihTanggal(formatTanggalIso(picked));
      } else {
        // kalau batal pilih, balik ke chip sebelumnya
        return;
      }
    }
    setState(() => _chipTanggalAktif = chipIndex);
  }

  void _simpan() {
    // FocusScope unfocus saat simpan (P04-Form)
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // validasi kategori di sisi cubit (formState cuma urus nominal)
    final state = context.read<CatatTransaksiCubit>().state;
    if (state.kategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori wajib dipilih.')),
      );
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
          // kembali ke tab beranda
          context.go('/');
          _nominalController.clear();
          _catatanController.clear();
          setState(() {
            _chipTanggalAktif = 0;
          });
          context.read<CatatTransaksiCubit>().reset();
        } else if (state.status == StatusCatatTransaksi.gagal) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.pesanKesalahan ?? 'Gagal menyimpan.'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: const HeaderAplikasi(namaLayar: 'CATAT'),
        body: PaperBackground(
          child: Center(
            child: Container(
              constraints:
                  const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
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
                    // judul layar dengan aksen stabilo
                    _JudulCatat(),
                    const SizedBox(height: AppSpacing.besar),
                    // kolom nominal
                    _BagianNominal(
                      controller: _nominalController,
                      focusNode: _nominalFocusNode,
                      onChanged: _onNominalChanged,
                    ),
                    const SizedBox(height: AppSpacing.besar),
                    // chip tanggal
                    _BagianTanggal(
                      chipAktif: _chipTanggalAktif,
                      onPilih: (i) => _pilihTanggal(context, i),
                    ),
                    const SizedBox(height: AppSpacing.besar),
                    // grid kategori
                    _BagianKategori(),
                    // kartu butuh/pengen (muncul cuma buat opsional & hiburan)
                    _BagianButuhPengen(),
                    const SizedBox(height: AppSpacing.besar),
                    // kolom catatan
                    _BagianCatatan(controller: _catatanController),
                    const SizedBox(height: AppSpacing.besar),
                    // tombol simpan
                    BlocBuilder<CatatTransaksiCubit, CatatTransaksiState>(
                      buildWhen: (prev, curr) => prev.status != curr.status,
                      builder: (context, state) {
                        return TombolStabilo(
                          teks: 'Simpan Transaksi',
                          ikon: Icons.save_outlined,
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

// judul layar dengan aksen stabilo dan badge buku harian
class _JudulCatat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: AppSizes.ukuranTitikIndikator,
                height: AppSizes.ukuranTitikIndikator,
                decoration: BoxDecoration(
                  color: AppColors.stabilo,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.ink,
                    width: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.agakKecil),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Catat ',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            bottom: AppSizes.geserStabiloJudul,
                            left: -AppSizes.geserStabiloJudul,
                            right: -AppSizes.geserStabiloJudul,
                            height: AppSizes.tinggiStabiloJudul,
                            child: Container(color: AppColors.stabilo),
                          ),
                          Text(
                            'Pengeluaran',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.kecil),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sedang,
            vertical: AppSpacing.mini,
          ),
          decoration: BoxDecoration(
            color: AppColors.grid,
            border: Border.all(
              color: AppColors.ink,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusPil),
          ),
          child: Text(
            'BUKU HARIAN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

// input nominal dengan format rupiah sambil diketik
class _BagianNominal extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _BagianNominal({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return KartuBukuTulis(
      radius: AppSizes.radiusTombol,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NOMINAL PENGELUARAN',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
              ),
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
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
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTheme.nominalUtama,
            decoration: InputDecoration(
              hintText: 'Rp0',
              hintStyle: AppTheme.nominalUtama.copyWith(
                color: AppColors.garis,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (value) {
              final angka = int.tryParse(
                    (value ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  0;
              if (angka <= 0) return 'Nominal wajib diisi.';
              return null;
            },
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// tiga chip tanggal: Hari ini (bawaan), Kemarin, Pilih
class _BagianTanggal extends StatelessWidget {
  final int chipAktif;
  final ValueChanged<int> onPilih;

  const _BagianTanggal({
    required this.chipAktif,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (ikon: Icons.calendar_today_outlined, label: 'Hari ini'),
      (ikon: Icons.history, label: 'Kemarin'),
      (ikon: Icons.edit_calendar_outlined, label: 'Pilih'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TANGGAL TRANSAKSI',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: AppSpacing.kecil),
        Row(
          children: List.generate(items.length, (i) {
            final aktif = chipAktif == i;
            final item = items[i];

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: i < items.length - 1 ? AppSpacing.kecil : 0,
                ),
                child: _TombolPilihanTanggal(
                  label: item.label,
                  ikon: item.ikon,
                  terpilih: aktif,
                  onTap: () => onPilih(i),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TombolPilihanTanggal extends StatefulWidget {
  final String label;
  final IconData ikon;
  final bool terpilih;
  final VoidCallback onTap;

  const _TombolPilihanTanggal({
    required this.label,
    required this.ikon,
    required this.terpilih,
    required this.onTap,
  });

  @override
  State<_TombolPilihanTanggal> createState() => _TombolPilihanTanggalState();
}

class _TombolPilihanTanggalState extends State<_TombolPilihanTanggal> {
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
        height: AppSizes.tinggiPilihanTanggal,
        decoration: BoxDecoration(
          color: widget.terpilih ? AppColors.stabilo : AppColors.kartu,
          border: Border.all(
            color: AppColors.ink,
            width: AppSizes.border,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonKuota),
          boxShadow: [
            _isPressed
                ? (widget.terpilih
                    ? AppTheme.bayanganGelapTertekan
                    : AppTheme.bayanganDefaultTertekan)
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
              size: AppSizes.ikonKecil,
              color: AppColors.ink,
            ),
            const SizedBox(width: AppSpacing.sangatKecil),
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight:
                          widget.terpilih ? FontWeight.w800 : FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
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
              'PILIH KATEGORI',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
            ),
            Text(
              'Wajib 1',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
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
                    final double lebarItem = (constraints.maxWidth -
                            AppSpacing.kecil * (AppSizes.kolomKategori - 1)) /
                        AppSizes.kolomKategori;
                    return Wrap(
                      spacing: AppSpacing.kecil,
                      runSpacing: AppSpacing.kecil,
                      children: daftar.map((k) {
                        final terpilih = k.id == kategoriIdTerpilih;
                        return SizedBox(
                          width: lebarItem,
                          child: _ChipKategori(
                            kategori: k,
                            terpilih: terpilih,
                            onTap: () {
                              context
                                  .read<CatatTransaksiCubit>()
                                  .pilihKategori(k.id!);
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

// satu chip kategori: badge ikon + nama
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

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppDurations.animasiTekan,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sedang,
          horizontal: AppSpacing.sangatKecil,
        ),
        decoration: BoxDecoration(
          color: widget.terpilih ? warna : AppColors.kartu,
          border: Border.all(
            color: AppColors.ink,
            width: AppSizes.border,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonKuota),
          boxShadow: [
            _isPressed
                ? (widget.terpilih
                    ? AppTheme.bayanganGelapTertekan
                    : AppTheme.bayanganDefaultTertekan)
                : (widget.terpilih
                    ? AppTheme.bayanganKecilGelap
                    : AppTheme.bayanganKecil),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (widget.terpilih)
              Positioned(
                top: -AppSpacing.agakKecil,
                right: 0,
                child: Container(
                  width: AppSizes.ukuranTitikIndikator,
                  height: AppSizes.ukuranTitikIndikator,
                  decoration: BoxDecoration(
                    color: AppColors.stabilo,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 1.0),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSizes.kotakIkonAksi,
                  height: AppSizes.kotakIkonAksi,
                  decoration: BoxDecoration(
                    color: widget.terpilih
                        ? AppColors.ink.withValues(alpha: 0.2)
                        : warna,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusKotakIkonAksi),
                    border: widget.terpilih
                        ? Border.all(
                            color: AppColors.ink.withValues(alpha: 0.1),
                            width: 1.0,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      ikon,
                      color: AppColors.ikonBadge,
                      size: AppSizes.ikonAksi,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.agakKecil),
                Text(
                  _kapitalPertama(widget.kategori.nama),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: widget.terpilih
                            ? AppColors.kartu
                            : AppColors.ink,
                        fontWeight:
                            widget.terpilih ? FontWeight.w800 : FontWeight.w700,
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
    );
  }
}

// kartu butuh/pengen, HANYA muncul untuk kelompok opsional dan hiburan
// (KATEGORI.md). muncul dengan animasi naik ~200ms. boleh dilewati,
// tersimpan NULL (Keputusan D)
class _BagianButuhPengen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatatTransaksiCubit, CatatTransaksiState>(
      buildWhen: (prev, curr) =>
          prev.kategoriId != curr.kategoriId ||
          prev.tipeKebutuhan != curr.tipeKebutuhan,
      builder: (context, state) {
        // cek kelompok kakeibo kategori terpilih
        final kategoriId = state.kategoriId;
        if (kategoriId == null) return const SizedBox();

        final kategoriCubit = context.read<KategoriCubit>();
        final kategori = kategoriCubit.kategoriById(kategoriId);
        if (kategori == null) return const SizedBox();

        final kelompok = kategori.kelompokKakeibo;
        final tampil = kelompok == 'opsional' || kelompok == 'hiburan';

        return AnimatedSize(
          duration: AppDurations.animasiMunculKartu,
          curve: Curves.easeOut,
          child: tampil
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.besar),
                  child: KartuBukuTulis(
                    radius: AppSizes.radiusTombol,
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
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.mini),
                                  Text(
                                    'Jujur ke diri sendiri, yuk sadari niat belanjamu.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
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
                                boxShadow: const [
                                  AppTheme.bayanganKecilGelap,
                                ],
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
                                  final cubit =
                                      context.read<CatatTransaksiCubit>();
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
                                  final cubit =
                                      context.read<CatatTransaksiCubit>();
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
                            color: AppColors.grid,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
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
          border: Border.all(
            color: AppColors.ink,
            width: AppSizes.border,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusKotakIkonAksi),
          boxShadow: [
            _isPressed
                ? (widget.terpilih
                    ? AppTheme.bayanganGelapTertekan
                    : AppTheme.bayanganDefaultTertekan)
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
                    fontWeight:
                        widget.terpilih ? FontWeight.w800 : FontWeight.w700,
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
          'CATATAN TAMBAHAN',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: AppSpacing.kecil),
        KartuBukuTulis(
          radius: AppSizes.radiusTombol,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sedang,
            vertical: AppSpacing.sangatKecil,
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  decoration: InputDecoration(
                    hintText: 'Tambah catatan (misal: Es kopi sama temen)...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkSoft,
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
