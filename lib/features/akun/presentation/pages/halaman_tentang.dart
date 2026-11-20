import 'package:flutter/material.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/header_aplikasi.dart';
import '../../../../core/widgets/kartu_tentang_aplikasi.dart';

/// Halaman terpisah untuk kartu Tentang Aplikasi (ISSUE-38), supaya
/// halaman Akun dan Masuk tidak terlalu panjang. Dibuka lewat tombol
/// "Tentang Aplikasi".
class HalamanTentang extends StatelessWidget {
  const HalamanTentang({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderAplikasi(
        namaLayar: 'Tentang Aplikasi',
        modeKembali: true,
      ),
      body: PaperBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.besar),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.batasLebarKonten,
              ),
              child: const KartuTentangAplikasi(),
            ),
          ),
        ),
      ),
    );
  }
}
