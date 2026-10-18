import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/rupiah_extension.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/tombol_stabilo.dart';

class FormIsianRefleksi extends StatefulWidget {
  final String? catatanAwal;
  final int? targetAwal;
  final int? targetPekanIni;
  final int? targetBulanan;
  final DateTime? tanggalAcuan;
  final bool sedangMenyimpan;
  final void Function(String catatan, int? targetPekanDepan) onSimpan;

  const FormIsianRefleksi({
    super.key,
    this.catatanAwal,
    this.targetAwal,
    this.targetPekanIni,
    this.targetBulanan,
    this.tanggalAcuan,
    this.sedangMenyimpan = false,
    required this.onSimpan,
  });

  @override
  State<FormIsianRefleksi> createState() => _FormIsianRefleksiState();
}

class _FormIsianRefleksiState extends State<FormIsianRefleksi> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _catatanController;
  late final TextEditingController _targetController;

  static String _formatNominal(int? nominal) {
    if (nominal == null || nominal <= 0) return '';
    return formatRupiah(nominal).replaceFirst('Rp', '');
  }

  @override
  void initState() {
    super.initState();
    _catatanController = TextEditingController(text: widget.catatanAwal ?? '');
    _targetController = TextEditingController(
      text: _formatNominal(widget.targetAwal),
    );
  }

  @override
  void didUpdateWidget(covariant FormIsianRefleksi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catatanAwal != oldWidget.catatanAwal &&
        widget.catatanAwal != null &&
        _catatanController.text.isEmpty) {
      _catatanController.text = widget.catatanAwal!;
    }
    if (widget.targetAwal != oldWidget.targetAwal &&
        widget.targetAwal != null &&
        _targetController.text.isEmpty) {
      _targetController.text = _formatNominal(widget.targetAwal);
    }
  }

  void _onTargetChanged(String val) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
    final angka = int.tryParse(cleaned);
    if (angka != null && angka > 0) {
      final formatted = formatRupiah(angka).replaceFirst('Rp', '');
      _targetController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      _targetController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final catatan = _catatanController.text.trim();
    final angkaBersih = _targetController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final int? targetPekanDepan = angkaBersih.isNotEmpty
        ? int.tryParse(angkaBersih)
        : null;

    widget.onSimpan(catatan, targetPekanDepan);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KartuBukuTulis(
            radius: AppSizes.radiusTombol,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSizes.kotakIkonAksi,
                      height: AppSizes.kotakIkonAksi,
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
                        Icons.edit_note,
                        size: AppSizes.ikonAksi,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.kecil),
                    Expanded(
                      child: Text(
                        'Rencana Pekan Depan',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.besar),
                Text(
                  'Satu hal yang mau diperbaiki pekan depan:',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.kecil),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sedang,
                    vertical: AppSpacing.kecil,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppSizes.border,
                    ),
                    boxShadow: const [AppTheme.bayanganKecil],
                  ),
                  child: TextFormField(
                    key: const Key('input_catatan_refleksi'),
                    controller: _catatanController,
                    maxLines: 2,
                    maxLength: AppConstraints.maxPanjangCatatan,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Bawa botol minum sendiri dari kos saat kuliah.',
                      hintStyle: textTheme.bodySmall,
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tuliskan satu hal yang ingin diperbaiki pekan depan.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.besar),
                Text(
                  'Target pengeluaran pekan depan (opsional):',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.kecil),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sedang,
                    vertical: AppSpacing.sangatKecil,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppSizes.border,
                    ),
                    boxShadow: const [AppTheme.bayanganKecil],
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Rp',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.kecil),
                      Expanded(
                        child: TextFormField(
                          key: const Key('input_target_pekan_depan'),
                          controller: _targetController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: '350.000',
                            hintStyle: textTheme.titleMedium?.copyWith(
                              color: AppColors.garis,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: _onTargetChanged,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final angkaBersih = value.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            final angka = int.tryParse(angkaBersih);
                            if (angka == null || angka <= 0) {
                              return 'Target harus berupa angka lebih dari 0.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const Icon(
                        Icons.flag_outlined,
                        size: AppSizes.ikonAksi,
                        color: AppColors.inkSoft,
                      ),
                    ],
                  ),
                ),
                if (widget.targetPekanIni != null &&
                    widget.targetPekanIni! > 0) ...[
                  const SizedBox(height: AppSpacing.sangatKecil),
                  Text(
                    'Pekan ini: ${widget.targetPekanIni!.toRupiah()}',
                    key: const Key('teks_bantu_target_pekan_ini'),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (widget.targetBulanan != null &&
                    widget.targetBulanan! > 0) ...[
                  const SizedBox(height: AppSpacing.sangatKecil),
                  Builder(
                    builder: (context) {
                      final acuan = widget.tanggalAcuan ?? DateTime.now();
                      final hariDalamBulan =
                          DateTime(acuan.year, acuan.month + 1, 0).day;
                      final perPekan =
                          ((widget.targetBulanan! * 7 / hariDalamBulan) /
                                  1000)
                              .round() *
                          1000;
                      return Text(
                        'Target bulananmu ${widget.targetBulanan!.toRupiah()}, kira-kira ${perPekan.toRupiah()} per pekan.',
                        key: const Key('teks_bantu_target_bulanan_per_pekan'),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.besar),
          TombolStabilo(
            key: const Key('tombol_simpan_refleksi'),
            teks: 'Simpan Refleksi',
            ikon: Icons.bookmark_added_outlined,
            isLoading: widget.sedangMenyimpan,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
