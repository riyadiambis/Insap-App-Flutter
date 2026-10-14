import 'package:flutter/material.dart';

import '../../features/akun/domain/entities/pengguna_entity.dart';
import '../../features/akun/domain/repositories/akun_repository.dart';
import '../../features/beranda/presentation/pages/halaman_tentang.dart';
import '../di/injection_container.dart';
import '../theme.dart';
import 'avatar_profil.dart';

/// Header aplikasi bersama sesuai mockup layar 1 dan 2.
///
/// Menampilkan:
/// - Kiri: Kotak logo kuning stabilo dengan ikon dompet, teks "Insap",
///   dan subjudul [namaLayar] kapital ("BERANDA" / "CATAT").
/// - Kanan: Tombol lonceng notifikasi dan avatar profil yang masing-masing
///   memunculkan SnackBar "Segera hadir" atau membuka HalamanTentang.
class HeaderAplikasi extends StatelessWidget implements PreferredSizeWidget {
  final String namaLayar;
  final PenggunaEntity? pengguna;
  final Stream<PenggunaEntity?>? streamPengguna;

  const HeaderAplikasi({
    super.key,
    required this.namaLayar,
    this.pengguna,
    this.streamPengguna,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.tinggiHeader);

  Stream<PenggunaEntity?>? _dapatkanStreamPengguna() {
    if (streamPengguna != null) return streamPengguna;
    if (sl.isRegistered<AkunRepository>()) {
      try {
        return sl<AkunRepository>().pantauPengguna();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _tampilkanPesanSegeraHadir(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Segera hadir')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(
          bottom: BorderSide(color: AppColors.ink, width: AppSizes.border),
        ),
        boxShadow: [AppTheme.bayanganBawah],
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.batasLebarKonten,
            ),
            height: AppSizes.tinggiHeader,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.besar),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSizes.kotakIkonAksi,
                      height: AppSizes.kotakIkonAksi,
                      decoration: BoxDecoration(
                        color: AppColors.stabilo,
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppSizes.border,
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: const [AppTheme.bayanganKecilGelap],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: AppSizes.ikonAksi,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sedang),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Insap', style: AppTheme.judulHeaderLogo),
                        Text(
                          namaLayar.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _tampilkanPesanSegeraHadir(context),
                      child: Container(
                        width: 38.0,
                        height: 38.0,
                        decoration: BoxDecoration(
                          color: AppColors.kartu,
                          border: Border.all(
                            color: AppColors.ink,
                            width: AppSizes.border,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: const [AppTheme.bayanganKecilGelap],
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: AppSizes.ikonAksi,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.kecil),
                    GestureDetector(
                      key: const Key('tombol_profil_header'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HalamanTentang(),
                        ),
                      ),
                      child: StreamBuilder<PenggunaEntity?>(
                        initialData: pengguna,
                        stream: _dapatkanStreamPengguna(),
                        builder: (context, snapshot) {
                          final p = snapshot.hasError
                              ? pengguna
                              : (snapshot.data ?? pengguna);
                          return AvatarProfil(
                            fotoUrl: p?.fotoUrl,
                            ukuran: 34.0,
                            ukuranIkon: 18.0,
                            warnaLatar: AppColors.ink,
                            warnaIkon: AppColors.kartu,
                            bayangan: const [AppTheme.bayanganKecilGelap],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
