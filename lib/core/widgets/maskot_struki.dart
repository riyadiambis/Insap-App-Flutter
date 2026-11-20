import 'package:flutter/material.dart';

/// Daftar pose maskot Struki yang tersedia di aset `assets/images/maskot/`.
enum PoseMaskot {
  mulai,
  nabung,
  catat,
  scan,
  detektif,
  hemat,
  boncos,
  puyeng,
  cukup,
}

/// Widget dekoratif untuk menampilkan ilustrasi maskot Struki sesuai [pose].
class MaskotStruki extends StatelessWidget {
  final PoseMaskot pose;
  final double ukuran;

  const MaskotStruki({
    super.key,
    required this.pose,
    this.ukuran = 160,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Image.asset(
        'assets/images/maskot/maskot_${pose.name}.png',
        width: ukuran,
        height: ukuran,
        fit: BoxFit.contain,
      ),
    );
  }
}
