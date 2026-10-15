import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../transaksi/presentation/catat/widgets/kolom_input_nominal.dart';

class BottomSheetTargetBulanan extends StatefulWidget {
  final int? targetSaatIni;
  final Future<void> Function(int nominalBaru) onSimpan;

  const BottomSheetTargetBulanan({
    super.key,
    this.targetSaatIni,
    required this.onSimpan,
  });

  @override
  State<BottomSheetTargetBulanan> createState() =>
      _BottomSheetTargetBulananState();
}

class _BottomSheetTargetBulananState extends State<BottomSheetTargetBulanan> {
  late int _nominal;
  bool _sedangMenyimpan = false;

  @override
  void initState() {
    super.initState();
    _nominal = widget.targetSaatIni ?? 0;
  }

  Future<void> _simpan() async {
    if (_nominal <= 0 || _sedangMenyimpan) return;
    setState(() {
      _sedangMenyimpan = true;
    });

    try {
      await widget.onSimpan(_nominal);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _sedangMenyimpan = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.batasLebarKonten,
          ),
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.besar,
            AppSpacing.sedang,
            AppSpacing.besar,
            AppSpacing.besar,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Garis handle kecil
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.garis,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sedang),

              // Header judul dan tombol tutup
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Target Bulanan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                    ),
                  ),
                  IconButton(
                    key: const Key('tombol_tutup_target_sheet'),
                    icon: const Icon(Icons.close, color: AppColors.ink),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.mini),
              Text(
                'Batas pengeluaran sebulan. Kamu bisa ubah kapan saja.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                    ),
              ),
              const SizedBox(height: AppSpacing.besar),

              // Kolom nominal (memakai ulang KolomInputNominal dari halaman Catat)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kartu,
                  borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppSizes.border,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sedang,
                  vertical: AppSpacing.kecil,
                ),
                child: KolomInputNominal(
                  key: const Key('kolom_input_target_bulanan'),
                  nominal: _nominal,
                  onChanged: (nilai) {
                    setState(() {
                      _nominal = nilai;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.besar),

              // Tombol Simpan
              TombolStabilo(
                key: const Key('tombol_simpan_target_bulanan'),
                teks: 'Simpan',
                ikon: Icons.check,
                isLoading: _sedangMenyimpan,
                onPressed: _nominal > 0 && !_sedangMenyimpan ? _simpan : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
