import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme.dart';
import '../../../../../core/widgets/tombol_stabilo.dart';
import '../../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../../kategori/presentation/cubit/kategori_state.dart';
import '../cubit/riwayat_cubit.dart';
import 'riwayat_helper.dart';

class BottomSheetFilter extends StatefulWidget {
  final String? tanggalMulaiAwal;
  final String? tanggalAkhirAwal;
  final int? kategoriIdAwal;

  const BottomSheetFilter({
    super.key,
    this.tanggalMulaiAwal,
    this.tanggalAkhirAwal,
    this.kategoriIdAwal,
  });

  static Future<void> tampilkan(BuildContext context) {
    final state = context.read<RiwayatCubit>().state;
    final cubit = context.read<RiwayatCubit>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusKartu),
        ),
        side: BorderSide(
          color: AppColors.ink,
          width: AppSizes.border,
        ),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: BottomSheetFilter(
            tanggalMulaiAwal: state.filterTanggalMulai,
            tanggalAkhirAwal: state.filterTanggalAkhir,
            kategoriIdAwal: state.filterKategoriId,
          ),
        );
      },
    );
  }

  @override
  State<BottomSheetFilter> createState() => _BottomSheetFilterState();
}

class _BottomSheetFilterState extends State<BottomSheetFilter> {
  late String? _tanggalMulai;
  late String? _tanggalAkhir;
  late int? _kategoriId;

  @override
  void initState() {
    super.initState();
    _tanggalMulai = widget.tanggalMulaiAwal;
    _tanggalAkhir = widget.tanggalAkhirAwal;
    _kategoriId = widget.kategoriIdAwal;
  }

  Future<void> _pilihRentangTanggal() async {
    DateTime awal = DateTime.now();
    DateTime akhir = DateTime.now();

    if (_tanggalMulai != null) {
      try {
        final p = _tanggalMulai!.split('-');
        awal = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      } catch (_) {}
    }
    if (_tanggalAkhir != null) {
      try {
        final p = _tanggalAkhir!.split('-');
        akhir = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      } catch (_) {}
    }

    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: awal, end: akhir),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.ink,
              onPrimary: AppColors.paper,
              surface: AppColors.paper,
              onSurface: AppColors.ink,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (hasil != null) {
      setState(() {
        _tanggalMulai = RiwayatHelper.formatYmd(hasil.start);
        _tanggalAkhir = RiwayatHelper.formatYmd(hasil.end);
      });
    }
  }

  void _hapusPilihanTanggal() {
    setState(() {
      _tanggalMulai = null;
      _tanggalAkhir = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adaPilihanTanggal = _tanggalMulai != null && _tanggalAkhir != null;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.besar,
          AppSpacing.besar,
          AppSpacing.besar,
          AppSpacing.lebihBesar,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Garis pegangan kecil di atas
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inkSoft.withAlpha(80),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sedang),

              // Baris Judul
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saring Riwayat',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.ink),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sedang),

              // Bagian Rentang Tanggal
              Text(
                'RENTANG TANGGAL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
              ),
              const SizedBox(height: AppSpacing.kecil),
              GestureDetector(
                onTap: _pilihRentangTanggal,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.besar,
                    vertical: AppSpacing.sedang,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.kartu,
                    borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppSizes.border,
                    ),
                    boxShadow: const [AppTheme.bayanganDefault],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.ink,
                        size: AppSizes.ikonAksi,
                      ),
                      const SizedBox(width: AppSpacing.sedang),
                      Expanded(
                        child: Text(
                          adaPilihanTanggal
                              ? RiwayatHelper.formatRentangTanggal(
                                  _tanggalMulai!,
                                  _tanggalAkhir!,
                                )
                              : 'Pilih rentang tanggal...',
                          style: TextStyle(
                            color: adaPilihanTanggal
                                ? AppColors.ink
                                : AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (adaPilihanTanggal)
                        GestureDetector(
                          onTap: _hapusPilihanTanggal,
                          child: const Icon(
                            Icons.close_rounded,
                            size: AppSizes.ikonKecil,
                            color: AppColors.inkSoft,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lebihBesar),

              // Bagian Kategori
              Text(
                'KATEGORI',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
              ),
              const SizedBox(height: AppSpacing.kecil),
              BlocBuilder<KategoriCubit, KategoriState>(
                builder: (context, state) {
                  if (state is KategoriLoaded) {
                    return Wrap(
                      spacing: AppSpacing.kecil,
                      runSpacing: AppSpacing.kecil,
                      children: state.kategoriList.map((kat) {
                        final dipilih = _kategoriId == kat.id;
                        final ikon = RiwayatHelper.parseIkon(kat.ikon);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _kategoriId = dipilih ? null : kat.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sedang,
                              vertical: AppSpacing.agakKecil,
                            ),
                            decoration: BoxDecoration(
                              color: dipilih ? AppColors.stabilo : AppColors.kartu,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusPil),
                              border: Border.all(
                                color: AppColors.ink,
                                width: AppSizes.border,
                              ),
                              boxShadow: dipilih
                                  ? const [AppTheme.bayanganKecilGelap]
                                  : const [AppTheme.bayanganDefault],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ikon,
                                  size: AppSizes.ikonKecil,
                                  color: AppColors.ink,
                                ),
                                const SizedBox(width: AppSpacing.kecil),
                                Text(
                                  kat.nama,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox(
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.tebalIndikatorMuat,
                        valueColor: AlwaysStoppedAnimation(AppColors.ink),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.antarBagian),

              // Tombol Terapkan
              TombolStabilo(
                teks: 'Terapkan',
                onPressed: () {
                  context.read<RiwayatCubit>().terapkanFilter(
                        tanggalMulai: _tanggalMulai,
                        tanggalAkhir: _tanggalAkhir,
                        kategoriId: _kategoriId,
                      );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.kecil),

              // Tombol Reset Saringan
              TextButton(
                onPressed: () {
                  context.read<RiwayatCubit>().resetFilter();
                  Navigator.pop(context);
                },
                child: Text(
                  'Reset Saringan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.salah,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
