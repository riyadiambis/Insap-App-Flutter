import 'package:flutter/material.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/kartu_tentang_aplikasi.dart';

/// Halaman terpisah untuk kartu Tentang Aplikasi (ISSUE-38), supaya
/// halaman Akun dan Masuk tidak terlalu panjang. Dibuka lewat tombol
/// "Tentang Aplikasi".
class HalamanTentang extends StatelessWidget {
  const HalamanTentang({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tentang Aplikasi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: AppColors.paper,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppSizes.borderTipis),
          child: Container(color: AppColors.ink, height: AppSizes.borderTipis),
        ),
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
