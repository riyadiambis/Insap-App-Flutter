import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme.dart';
import '../../../../../core/widgets/tombol_stabilo.dart';
import '../../../../kategori/domain/entities/kategori_entity.dart';
import '../../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../../kategori/presentation/cubit/kategori_state.dart';
import 'riwayat_helper.dart';

/// Lembar bawah saringan riwayat transaksi (F-02, P04-Form).
/// Memungkinkan penyaringan berdasarkan rentang tanggal dan satu kategori pilihan (Keputusan G).
class BottomSheetFilter extends StatefulWidget {
  final String? initialTanggalMulai;
  final String? initialTanggalAkhir;
  final int? initialKategoriId;
  final void Function({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) onTerapkan;
  final VoidCallback onReset;

  const BottomSheetFilter({
    super.key,
    this.initialTanggalMulai,
    this.initialTanggalAkhir,
    this.initialKategoriId,
    required this.onTerapkan,
    required this.onReset,
  });

  /// Helper statis untuk menampilkan bottom sheet saringan
  static Future<void> tampilkan({
    required BuildContext context,
    String? initialTanggalMulai,
    String? initialTanggalAkhir,
    int? initialKategoriId,
    required void Function({
      String? tanggalMulai,
      String? tanggalAkhir,
      int? kategoriId,
    }) onTerapkan,
    required VoidCallback onReset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: context.read<KategoriCubit>(),
          child: BottomSheetFilter(
            initialTanggalMulai: initialTanggalMulai,
            initialTanggalAkhir: initialTanggalAkhir,
            initialKategoriId: initialKategoriId,
            onTerapkan: onTerapkan,
            onReset: onReset,
          ),
        );
      },
    );
  }

  @override
  State<BottomSheetFilter> createState() => _BottomSheetFilterState();
}

class _BottomSheetFilterState extends State<BottomSheetFilter> {
  DateTimeRange? _rentangTanggal;
  int? _kategoriIdTerpilih;

  @override
  void initState() {
    super.initState();
    _kategoriIdTerpilih = widget.initialKategoriId;
    if (widget.initialTanggalMulai != null &&
        widget.initialTanggalAkhir != null) {
      final mulai = DateTime.tryParse(widget.initialTanggalMulai!);
      final akhir = DateTime.tryParse(widget.initialTanggalAkhir!);
      if (mulai != null && akhir != null) {
        _rentangTanggal = DateTimeRange(start: mulai, end: akhir);
      }
    }
  }

  Future<void> _pilihRentangTanggal() async {
    final sekarang = DateTime.now();
    final awal = _rentangTanggal?.start ?? sekarang;
    final akhir = _rentangTanggal?.end ?? sekarang;

    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: sekarang,
      initialDateRange: DateTimeRange(
        start: awal.isAfter(sekarang) ? sekarang : awal,
        end: akhir.isAfter(sekarang) ? sekarang : akhir,
      ),
      helpText: 'PILIH RENTANG TANGGAL',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      saveText: 'PILIH',
    );

    if (hasil != null) {
      setState(() {
        _rentangTanggal = hasil;
      });
    }
  }

  void _terapkan() {
    final tglMulai = _rentangTanggal != null
        ? RiwayatHelper.toIsoDate(_rentangTanggal!.start)
        : null;
    final tglAkhir = _rentangTanggal != null
        ? RiwayatHelper.toIsoDate(_rentangTanggal!.end)
        : null;

    widget.onTerapkan(
      tanggalMulai: tglMulai,
      tanggalAkhir: tglAkhir,
      kategoriId: _kategoriIdTerpilih,
    );
    Navigator.of(context).pop();
  }

  void _reset() {
    widget.onReset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: AppSizes.batasLebarKonten),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusKartu),
        ),
        border: Border.all(
          color: AppColors.ink,
          width: AppSizes.border,
        ),
        boxShadow: const [AppTheme.bayanganAtas],
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.besar,
        right: AppSpacing.besar,
        top: AppSpacing.besar,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.besar,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle baris atas
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: AppColors.garis,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPil),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sedang),

            // Judul lembar saringan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saringan Riwayat',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Tutup',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sedang),

            // Bagian Rentang Tanggal
            Text(
              'RENTANG TANGGAL',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.kecil),
            GestureDetector(
              onTap: _pilihRentangTanggal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sedang,
                  vertical: AppSpacing.sedang,
                ),
                decoration: BoxDecoration(
                  color: AppColors.kartu,
                  borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                  border: Border.all(
                    color: _rentangTanggal != null
                        ? AppColors.ink
                        : AppColors.garis,
                    width: AppSizes.border,
                  ),
                  boxShadow: const [AppTheme.bayanganKecilGelap],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: AppSizes.ikonAksi,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: AppSpacing.kecil),
                    Expanded(
                      child: Text(
                        _rentangTanggal != null
                            ? RiwayatHelper.formatRentangTanggal(
                                _rentangTanggal!)
                            : 'Semua tanggal (ketuk untuk memilih)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: _rentangTanggal != null
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: _rentangTanggal != null
                                  ? AppColors.ink
                                  : AppColors.inkSoft,
                            ),
                      ),
                    ),
                    if (_rentangTanggal != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _rentangTanggal = null;
                          });
                        },
                        child: const Icon(
                          Icons.cancel_rounded,
                          size: AppSizes.ikonAksi,
                          color: AppColors.salah,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lebihBesar),

            // Bagian Kategori (Wrap Single Select)
            Text(
              'KATEGORI',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.kecil),
            BlocBuilder<KategoriCubit, KategoriState>(
              builder: (context, state) {
                if (state is KategoriLoaded) {
                  return Wrap(
                    spacing: AppSpacing.kecil,
                    runSpacing: AppSpacing.kecil,
                    children: state.kategoriList.map((kategori) {
                      final isSelected = _kategoriIdTerpilih == kategori.id;
                      return _ChipKategoriFilter(
                        kategori: kategori,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _kategoriIdTerpilih = null;
                            } else {
                              _kategoriIdTerpilih = kategori.id;
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                }
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.sedang),
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.tebalIndikatorMuat,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lebihBesar),

            // Tombol Aksi
            TombolStabilo(
              teks: 'Terapkan Saringan',
              onPressed: _terapkan,
            ),
            const SizedBox(height: AppSpacing.kecil),
            TextButton(
              onPressed: _reset,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sedang),
                foregroundColor: AppColors.inkSoft,
              ),
              child: Text(
                'Reset Saringan',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipKategoriFilter extends StatelessWidget {
  final KategoriEntity kategori;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipKategoriFilter({
    required this.kategori,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = RiwayatHelper.parseWarna(kategori.warna);
    final ikon = RiwayatHelper.parseIkon(kategori.ikon);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.animasiTekan,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sedang,
          vertical: AppSpacing.kecil,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.stabilo : AppColors.kartu,
          borderRadius: BorderRadius.circular(AppSizes.radiusPil),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.garis,
            width: isSelected ? AppSizes.border : 1.5,
          ),
          boxShadow: [
            isSelected
                ? AppTheme.bayanganKecilGelap
                : AppTheme.bayanganKecil,
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                color: warna,
                shape: BoxShape.circle,
              ),
              child: Icon(
                ikon,
                size: 12.0,
                color: AppColors.ikonBadge,
              ),
            ),
            const SizedBox(width: AppSpacing.agakKecil),
            Text(
              RiwayatHelper.kapitalPertama(kategori.nama),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: AppColors.ink,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
