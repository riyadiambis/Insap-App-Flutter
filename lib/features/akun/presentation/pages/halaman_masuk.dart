import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/header_aplikasi.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/kartu_tentang_aplikasi.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../cubit/akun_cubit.dart';
import '../cubit/akun_state.dart';

class HalamanMasuk extends StatefulWidget {
  const HalamanMasuk({super.key});

  @override
  State<HalamanMasuk> createState() => _HalamanMasukState();
}

class _HalamanMasukState extends State<HalamanMasuk> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _sandiController = TextEditingController();

  bool _tampilkanFormEmail = false;
  bool _modeDaftar = false;
  bool _sembunyikanSandi = true;

  @override
  void dispose() {
    _emailController.dispose();
    _sandiController.dispose();
    super.dispose();
  }

  void _kirimForm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final sandi = _sandiController.text;

    final cubit = context.read<AkunCubit>();
    if (_modeDaftar) {
      cubit.daftarDenganEmail(email: email, kataSandi: sandi);
    } else {
      cubit.masukDenganEmail(email: email, kataSandi: sandi);
    }
  }

  void _tampilkanDialogLupaSandi() {
    final resetController = TextEditingController(text: _emailController.text);
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
            'Lupa Kata Sandi?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan surel akun Anda untuk menerima tautan atur ulang kata sandi.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sedang),
              TextFormField(
                controller: resetController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Surel (Email)',
                  hintText: 'nama@domain.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
                    borderSide: const BorderSide(
                      color: AppColors.ink,
                      width: AppSizes.border,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final email = resetController.text.trim();
                if (email.isNotEmpty) {
                  Navigator.pop(dialogContext);
                  context.read<AkunCubit>().kirimResetKataSandi(email);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.stabilo,
                foregroundColor: AppColors.ink,
                elevation: 0,
                side: const BorderSide(
                  color: AppColors.ink,
                  width: AppSizes.border,
                ),
              ),
              child: const Text(
                'Kirim Tautan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _dekorasiInput({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
      borderSide: const BorderSide(
        color: AppColors.ink,
        width: AppSizes.border,
      ),
    );
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.ink),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.paper,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderAplikasi(
        namaLayar: 'Masuk',
        modeKembali: true,
      ),
      body: PaperBackground(
        child: BlocConsumer<AkunCubit, AkunState>(
          listener: (context, state) {
            if (state is AkunGalat) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.pesan),
                  backgroundColor: AppColors.salah,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is AkunPesanSukses) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.pesan),
                  backgroundColor: AppColors.benar,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final sedangMemuat = state is AkunMemuat;
            final teks = Theme.of(context).textTheme;

            return SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.batasLebarKonten,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.besar),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/logo_insap.png',
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'CADANGAN AWAN',
                                    style: teks.labelSmall?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Simpan catatan di awan',
                                style: teks.headlineMedium?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Masuk supaya catatanmu aman saat ganti HP. Tanpa akun pun Insap tetap jalan, data tersimpan di HP ini.',
                                style: teks.bodyMedium?.copyWith(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 14),
                              KartuBukuTulis(
                                shadow: AppTheme.bayanganGelap,
                                pressedShadow: AppTheme.bayanganGelapTertekan,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _BarisManfaatMasuk(
                                      ikon: Icons.cloud_outlined,
                                      teks: 'Cadangan transaksi ke awan',
                                    ),
                                    SizedBox(height: 10),
                                    _BarisManfaatMasuk(
                                      ikon: Icons.category_outlined,
                                      teks:
                                          'Kategori dan refleksi ikut tersimpan',
                                    ),
                                    SizedBox(height: 10),
                                    _BarisManfaatMasuk(
                                      ikon: Icons.delete_outline_rounded,
                                      teks: 'Bisa dihapus kapan saja',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Center(
                                child: TextButton(
                                  key: const Key('tombol_toggle_form_email'),
                                  onPressed: () {
                                    setState(() {
                                      _tampilkanFormEmail =
                                          !_tampilkanFormEmail;
                                    });
                                  },
                                  child: Text(
                                    _tampilkanFormEmail
                                        ? 'Sembunyikan masuk dengan surel'
                                        : 'Masuk atau daftar dengan surel',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkSoft,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              if (_tampilkanFormEmail) ...[
                                const SizedBox(height: 8),
                                KartuBukuTulis(
                                  shadow: AppTheme.bayanganGelap,
                                  pressedShadow: AppTheme.bayanganGelapTertekan,
                                  padding: const EdgeInsets.all(
                                    AppSpacing.besar,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'ALAMAT SUREL',
                                          style: teks.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.agakKecil,
                                        ),
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          enabled: !sedangMemuat,
                                          decoration: _dekorasiInput(
                                            hintText: 'nama@domain.com',
                                            prefixIcon: Icons.email_outlined,
                                          ),
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return 'Surel tidak boleh kosong';
                                            }
                                            if (!val.contains('@') ||
                                                !val.contains('.')) {
                                              return 'Format surel tidak valid';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.sedang,
                                        ),
                                        Text(
                                          'KATA SANDI',
                                          style: teks.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.agakKecil,
                                        ),
                                        TextFormField(
                                          controller: _sandiController,
                                          obscureText: _sembunyikanSandi,
                                          enabled: !sedangMemuat,
                                          decoration: _dekorasiInput(
                                            hintText: 'Minimal 6 karakter',
                                            prefixIcon: Icons.key_outlined,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _sembunyikanSandi
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                          .visibility_off_outlined,
                                                color: AppColors.ink,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _sembunyikanSandi =
                                                      !_sembunyikanSandi;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (val) {
                                            if (val == null || val.isEmpty) {
                                              return 'Kata sandi tidak boleh kosong';
                                            }
                                            if (val.length < 6) {
                                              return 'Kata sandi minimal 6 karakter';
                                            }
                                            return null;
                                          },
                                        ),
                                        if (!_modeDaftar) ...[
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: sedangMemuat
                                                  ? null
                                                  : _tampilkanDialogLupaSandi,
                                              child: const Text(
                                                'Lupa kata sandi?',
                                                style: TextStyle(
                                                  color: AppColors.inkSoft,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ] else
                                          const SizedBox(
                                            height: AppSpacing.besar,
                                          ),
                                        TombolStabilo(
                                          teks: _modeDaftar
                                              ? 'Daftar Sekarang'
                                              : 'Masuk ke Akun',
                                          isLoading: sedangMemuat,
                                          onPressed: sedangMemuat
                                              ? null
                                              : _kirimForm,
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.sedang,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _modeDaftar
                                                  ? 'Sudah punya akun?'
                                                  : 'Belum punya akun?',
                                              style: teks.bodySmall,
                                            ),
                                            TextButton(
                                              onPressed: sedangMemuat
                                                  ? null
                                                  : () {
                                                      setState(() {
                                                        _modeDaftar =
                                                            !_modeDaftar;
                                                        _formKey.currentState
                                                            ?.reset();
                                                      });
                                                    },
                                              child: Text(
                                                _modeDaftar
                                                    ? 'Masuk di sini'
                                                    : 'Daftar baru',
                                                style: const TextStyle(
                                                  color: AppColors.ink,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              const TombolTentangAplikasi(),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.besar,
                          AppSpacing.kecil,
                          AppSpacing.besar,
                          AppSpacing.besar,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TombolGoogleMasuk(
                              key: const Key('tombol_masuk_google'),
                              onPressed: sedangMemuat
                                  ? null
                                  : () => context
                                        .read<AkunCubit>()
                                        .masukDenganGoogle(),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              key: const Key('tombol_lanjut_tanpa_akun'),
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              child: const Text(
                                'Lanjut tanpa akun',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BarisManfaatMasuk extends StatelessWidget {
  final IconData ikon;
  final String teks;

  const _BarisManfaatMasuk({required this.ikon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.hijauMuda,
            border: Border.all(color: AppColors.ink, width: AppSizes.border),
            borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
          ),
          child: Icon(ikon, size: 18, color: AppColors.ink),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            teks,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.4,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _TombolGoogleMasuk extends StatelessWidget {
  final VoidCallback? onPressed;

  const _TombolGoogleMasuk({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Masuk dengan Google',
      enabled: onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.kartu,
              border: Border.all(color: AppColors.ink, width: AppSizes.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
              boxShadow: const [AppTheme.bayanganTombolGelap],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.g_mobiledata_rounded,
                  size: 26,
                  color: AppColors.ink,
                ),
                const SizedBox(width: AppSpacing.kecil),
                Text(
                  'Masuk dengan Google',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
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
