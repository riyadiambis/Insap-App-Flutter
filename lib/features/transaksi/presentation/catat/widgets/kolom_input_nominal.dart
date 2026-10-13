import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme.dart';
import '../../../../../core/utils/rupiah_extension.dart';

// widget input nominal dengan siklus hidup lengkap (Modul 4 praktikum)
class KolomInputNominal extends StatefulWidget {
  final int nominal;
  final ValueChanged<int> onChanged;
  final FocusNode? focusNode;

  const KolomInputNominal({
    super.key,
    required this.nominal,
    required this.onChanged,
    this.focusNode,
  });

  @override
  State<KolomInputNominal> createState() => _KolomInputNominalState();
}

class _KolomInputNominalState extends State<KolomInputNominal> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final teksAwal = widget.nominal > 0 ? widget.nominal.toRupiah() : '';
    _controller = TextEditingController(text: teksAwal);
  }

  @override
  void didUpdateWidget(covariant KolomInputNominal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // sinkronkan teks controller jika nominal berubah dari parent
    if (widget.nominal != oldWidget.nominal) {
      final teksBaru = widget.nominal > 0 ? widget.nominal.toRupiah() : '';
      final nilaiSaatIni = _parseAngka(_controller.text);
      if (nilaiSaatIni != widget.nominal) {
        _controller.value = TextEditingValue(
          text: teksBaru,
          selection: TextSelection.collapsed(offset: teksBaru.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _parseAngka(String teks) {
    final cleaned = teks.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  void _handleChanged(String value) {
    final angka = _parseAngka(value);
    if (angka > 0) {
      final formatted = angka.toRupiah();
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      _controller.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    widget.onChanged(angka);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTheme.nominalUtama,
      decoration: InputDecoration(
        hintText: 'Rp0',
        hintStyle: AppTheme.nominalUtama.copyWith(color: AppColors.garis),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      validator: (value) {
        final angka = _parseAngka(value ?? '');
        if (angka <= 0) return 'Nominal wajib diisi.';
        return null;
      },
      onChanged: _handleChanged,
    );
  }
}
