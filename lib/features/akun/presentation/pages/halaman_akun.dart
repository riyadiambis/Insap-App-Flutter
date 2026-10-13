import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../domain/entities/pengguna_entity.dart';
import '../cubit/akun_cubit.dart';
import '../cubit/akun_state.dart';

class HalamanAkun extends StatelessWidget {
  final PenggunaEntity pengguna;

  const HalamanAkun({super.key, required this.pengguna});

  void _konfirmasiKeluar(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.kartu,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
            side: const BorderSide(
              color: AppColors.ink,
              width: AppSizes.border,
            ),
          ),
          title: Text(
            'Keluar dari Akun?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Data transaksi lokal di perangkat ini tidak akan dihapus. Anda dapat masuk kembali kapan saja.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AkunCubit>().keluar();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salahLatar,
                foregroundColor: AppColors.salah,
                elevation: 0,
                side: const BorderSide(
                  color: AppColors.salah,
                  width: AppSizes.borderTipis,
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Akun & Cadangan',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kartu Info Pengguna
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.besar),
                    decoration: BoxDecoration(
                      color: AppColors.kartu,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppSizes.border,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusKartu),
                      boxShadow: const [AppTheme.bayanganDefault],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.stabilo,
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: AppSizes.border,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusBadge,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.ink,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sedang),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pengguna.email ?? 'Pengguna Anonim',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.agakKecil,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.benarLatar,
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusLabel,
                                      ),
                                      border: Border.all(
                                        color: AppColors.benar,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'Akun Terhubung',
                                      style: TextStyle(
                                        color: AppColors.benar,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.besar),
                        const Divider(color: AppColors.garis, thickness: 1),
                        const SizedBox(height: AppSpacing.agakKecil),
                        Text(
                          'ID Pengguna:',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          pengguna.uid,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.besar),
                  // Tombol Keluar
                  BlocBuilder<AkunCubit, AkunState>(
                    builder: (context, state) {
                      final sedangMemuat = state is AkunMemuat;
                      return OutlinedButton.icon(
                        onPressed: sedangMemuat
                            ? null
                            : () => _konfirmasiKeluar(context),
                        icon: const Icon(
                          Icons.logout,
                          color: AppColors.salah,
                          size: 20,
                        ),
                        label: Text(
                          sedangMemuat ? 'Memproses...' : 'Keluar dari Akun',
                          style: const TextStyle(
                            color: AppColors.salah,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sedang,
                          ),
                          side: const BorderSide(
                            color: AppColors.salah,
                            width: AppSizes.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusTombol,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
