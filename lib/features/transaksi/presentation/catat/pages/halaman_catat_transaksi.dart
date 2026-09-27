import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/paper_background.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/utils/iso_week.dart';
import '../../../../../core/utils/rupiah_extension.dart';
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
      listener: (context, state) {
        if (state.status == StatusCatatTransaksi.berhasil) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil disimpan!')),
          );
          // muat ulang ringkasan beranda biar langsung update (F-05)
          context.read<BerandaCubit>().muatRingkasan();
          // kembali ke tab beranda
          context.go('/');
        } else if (state.status == StatusCatatTransaksi.gagal) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.pesanKesalahan ?? 'Gagal menyimpan.'),
            ),
          );
        }
      },
      child: Scaffold(
        body: PaperBackground(
          child: Center(
            child: Container(
              constraints:
                  const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.besar),
                  children: [
                    const SizedBox(height: AppSpacing.besar),
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
                          teks: '💾  Simpan Transaksi',
                          isLoading:
                              state.status == StatusCatatTransaksi.menyimpan,
                          onPressed: _simpan,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.besar),
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

// judul layar dengan stabilo di kata "Pengeluaran"
class _JudulCatat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Text(
          'Catat ',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 4,
              left: -4,
              right: -4,
              height: 12,
              child: Container(color: AppColors.stabilo),
            ),
            Text(
              'Pengeluaran',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOMINAL PENGELUARAN',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: AppSpacing.kecil),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTheme.nominalBesar.copyWith(fontSize: 32),
            decoration: InputDecoration(
              hintText: 'Rp0',
              hintStyle: AppTheme.nominalBesar.copyWith(
                fontSize: 32,
                color: AppColors.garis,
              ),
              border: InputBorder.none,
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
    final labels = ['📅  Hari ini', '⏪  Kemarin', '📆  Pilih'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TANGGAL TRANSAKSI',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.kecil),
        Wrap(
          spacing: AppSpacing.kecil,
          children: List.generate(labels.length, (i) {
            final aktif = chipAktif == i;
            return ChoiceChip(
              label: Text(labels[i]),
              selected: aktif,
              onSelected: (_) => onPilih(i),
              selectedColor: AppColors.stabilo,
              backgroundColor: AppColors.kartu,
              side: BorderSide(
                color: aktif ? AppColors.ink : AppColors.garis,
                width: AppSizes.border,
              ),
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: aktif ? FontWeight.w700 : FontWeight.w400,
                  ),
            );
          }),
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
              'PILIH KATEGORI',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            BlocBuilder<KategoriCubit, KategoriState>(
              builder: (context, ks) {
                final jumlah =
                    ks is KategoriLoaded ? ks.kategoriList.length : 0;
                return Text(
                  '$jumlah kategori',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
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
            return BlocSelector<CatatTransaksiCubit, CatatTransaksiState,
                int?>(
              selector: (state) => state.kategoriId,
              builder: (context, kategoriIdTerpilih) {
                return Wrap(
                  spacing: AppSpacing.kecil,
                  runSpacing: AppSpacing.kecil,
                  children: daftar.map((k) {
                    final terpilih = k.id == kategoriIdTerpilih;
                    return _ChipKategori(
                      kategori: k,
                      terpilih: terpilih,
                      onTap: () {
                        context
                            .read<CatatTransaksiCubit>()
                            .pilihKategori(k.id!);
                      },
                    );
                  }).toList(),
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
class _ChipKategori extends StatelessWidget {
  final KategoriEntity kategori;
  final bool terpilih;
  final VoidCallback onTap;

  const _ChipKategori({
    required this.kategori,
    required this.terpilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = _parseWarna(kategori.warna);
    final ikon = _parseIkon(kategori.ikon);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.animasiTekan,
        width: (AppSizes.batasLebarKonten - AppSpacing.besar * 2 -
                AppSpacing.kecil * 2) /
            3,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sedang,
        ),
        decoration: BoxDecoration(
          color: terpilih ? warna : AppColors.kartu,
          border: Border.all(
            color: terpilih ? warna : AppColors.garis,
            width: AppSizes.border,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
          boxShadow: terpilih ? [AppTheme.bayanganDefault] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ikon,
              color: terpilih ? AppColors.ikonBadge : warna,
              size: AppSizes.badgeKategori * 0.6,
            ),
            const SizedBox(height: AppSpacing.kecil),
            Text(
              _kapitalPertama(kategori.nama),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: terpilih ? AppColors.ikonBadge : AppColors.ink,
                    fontWeight:
                        terpilih ? FontWeight.w700 : FontWeight.w400,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Ini butuh atau pengen?',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ),
                            const Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.stabilo,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.kecil),
                        // kalimat di kotak bohlam (Keputusan D)
                        Text(
                          'Nggak ada jawaban salah. Nanti kamu lihat '
                          'sendiri polanya di refleksi Minggu.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sedang),
                        Row(
                          children: [
                            _ChipButuhPengen(
                              label: '🫶  Butuh',
                              terpilih: state.tipeKebutuhan == 'butuh',
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
                            const SizedBox(width: AppSpacing.kecil),
                            _ChipButuhPengen(
                              label: '🎁  Pengen',
                              terpilih: state.tipeKebutuhan == 'pengen',
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
                          ],
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
class _ChipButuhPengen extends StatelessWidget {
  final String label;
  final bool terpilih;
  final VoidCallback onTap;

  const _ChipButuhPengen({
    required this.label,
    required this.terpilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.animasiTekan,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.besar,
          vertical: AppSpacing.sedang,
        ),
        decoration: BoxDecoration(
          color: terpilih ? AppColors.stabilo : AppColors.kartu,
          border: Border.all(
            color: terpilih ? AppColors.ink : AppColors.garis,
            width: AppSizes.border,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: terpilih ? FontWeight.w700 : FontWeight.w400,
              ),
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
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.kecil),
        KartuBukuTulis(
          child: TextFormField(
            controller: controller,
            maxLength: AppConstraints.maxPanjangCatatan,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Contoh: Es kopi sama temen',
              hintStyle: Theme.of(context).textTheme.bodySmall,
              border: InputBorder.none,
              counterStyle: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
