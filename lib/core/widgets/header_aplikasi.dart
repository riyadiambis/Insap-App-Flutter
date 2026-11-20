import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/akun/domain/entities/pengguna_entity.dart';
import '../../features/akun/domain/repositories/akun_repository.dart';
import '../di/injection_container.dart';
import '../theme.dart';
import 'avatar_profil.dart';

/// Header aplikasi bersama sesuai desain Insap 2.0.
///
/// Mode utama menampilkan:
/// - Kiri: Logo Insap, teks "Insap", dan subjudul [namaLayar].
/// - Kanan: Avatar profil bulat 44 dp yang membuka alur akun (/akun).
///
/// Mode kembali menampilkan tombol kembali dan judul [namaLayar].
class HeaderAplikasi extends StatelessWidget implements PreferredSizeWidget {
  final String namaLayar;
  final PenggunaEntity? pengguna;
  final Stream<PenggunaEntity?>? streamPengguna;
  final bool modeKembali;
  final VoidCallback? onKembali;

  /// Kunci avatar untuk disorot petunjuk (ISSUE-37). Hanya diisi AppShell.
  final Key? kunciAvatar;

  const HeaderAplikasi({
    super.key,
    required this.namaLayar,
    this.pengguna,
    this.streamPengguna,
    this.modeKembali = false,
    this.onKembali,
    this.kunciAvatar,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(
          bottom: BorderSide(color: AppColors.ink, width: AppSizes.border),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.batasLebarKonten,
            ),
            height: AppSizes.tinggiHeader - AppSizes.border,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.besar),
            child: modeKembali
                ? Row(
                    children: [
                      Semantics(
                        label: 'Kembali',
                        button: true,
                        child: GestureDetector(
                          onTap: onKembali ?? () => context.pop(),
                          behavior: HitTestBehavior.opaque,
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: Icon(
                                Icons.chevron_left_rounded,
                                size: 28.0,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.agakKecil),
                      Expanded(
                        child: Text(
                          namaLayar,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 21.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ExcludeSemantics(
                            child: Image.asset(
                              'assets/images/logo_insap.png',
                              width: AppSizes.ukuranLogoHeader,
                              height: AppSizes.ukuranLogoHeader,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Insap',
                                style: AppTheme.judulHeaderLogo,
                              ),
                              Text(
                                namaLayar.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.inkSoft,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      fontSize: 12.0,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Semantics(
                        label: 'Akun dan cadangan',
                        button: true,
                        child: GestureDetector(
                          key: const Key('tombol_profil_header'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push('/akun'),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: StreamBuilder<PenggunaEntity?>(
                                initialData: pengguna,
                                stream: _dapatkanStreamPengguna(),
                                builder: (context, snapshot) {
                                  final p = snapshot.hasError
                                      ? pengguna
                                      : (snapshot.data ?? pengguna);
                                  return AvatarProfil(
                                    key: kunciAvatar,
                                    fotoUrl: p?.fotoUrl,
                                    ukuran: AppSizes.ukuranAvatarHeader,
                                    ukuranIkon: AppSizes.ikonAvatarHeader,
                                    warnaLatar: AppColors.daun,
                                    warnaIkon: AppColors.kartu,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
