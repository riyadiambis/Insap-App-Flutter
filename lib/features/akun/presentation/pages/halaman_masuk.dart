import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
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
                    borderRadius: BorderRadius.circular(AppSizes.radiusLabel),
                    borderSide: const BorderSide(
                      color: AppColors.ink,
                      width: AppSizes.borderTipis,
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
                  width: AppSizes.borderTipis,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _modeDaftar ? 'Daftar Akun' : 'Masuk Akun',
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.besar),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.batasLebarKonten,
                  ),
                  child: Container(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.stabilo,
                                  border: Border.all(
                                    color: AppColors.ink,
                                    width: AppSizes.border,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusKotakIkonAksi,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sedang),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _modeDaftar
                                          ? 'Buat Akun Insap'
                                          : 'Selamat Datang!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    Text(
                                      _modeDaftar
                                          ? 'Daftar untuk mencadangkan catatan'
                                          : 'Masuk untuk sinkronisasi awan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.besar),
                          // Kolom surel
                          Text(
                            'Alamat Surel',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.agakKecil),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !sedangMemuat,
                            decoration: InputDecoration(
                              hintText: 'nama@domain.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: AppColors.paper,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLabel,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.ink,
                                  width: AppSizes.borderTipis,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLabel,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.ink,
                                  width: AppSizes.borderTipis,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLabel,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.ink,
                                  width: AppSizes.border,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Surel tidak boleh kosong';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Format surel tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sedang),
                          // Kolom kata sandi
                          Text(
                            'Kata Sandi',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.agakKecil),
                          TextFormField(
                            controller: _sandiController,
                            obscureText: _sembunyikanSandi,
                            enabled: !sedangMemuat,
                            decoration: InputDecoration(
                              hintText: 'Minimal 6 karakter',
                              prefixIcon: const Icon(Icons.key_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _sembunyikanSandi
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _sembunyikanSandi = !_sembunyikanSandi;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: AppColors.paper,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLabel,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.ink,
                                  width: AppSizes.borderTipis,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLabel,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.ink,
                                  width: AppSizes.borderTipis,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLabel,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.ink,
                                  width: AppSizes.border,
                                ),
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
                                child: Text(
                                  'Lupa kata sandi?',
                                  style: TextStyle(
                                    color: AppColors.inkSoft,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ] else
                            const SizedBox(height: AppSpacing.besar),
                          // Tombol Utama (Masuk / Daftar)
                          ElevatedButton(
                            onPressed: sedangMemuat ? null : _kirimForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.stabilo,
                              foregroundColor: AppColors.ink,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sedang,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusTombol,
                                ),
                                side: const BorderSide(
                                  color: AppColors.ink,
                                  width: AppSizes.border,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: sedangMemuat
                                ? const SizedBox(
                                    width: AppSizes.indikatorMuat,
                                    height: AppSizes.indikatorMuat,
                                    child: CircularProgressIndicator(
                                      strokeWidth: AppSizes.tebalIndikatorMuat,
                                      color: AppColors.ink,
                                    ),
                                  )
                                : Text(
                                    _modeDaftar
                                        ? 'Daftar Sekarang'
                                        : 'Masuk ke Akun',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.sedang),
                          // Tombol Google
                          OutlinedButton.icon(
                            key: const Key('tombol_masuk_google'),
                            onPressed: sedangMemuat
                                ? null
                                : () => context
                                      .read<AkunCubit>()
                                      .masukDenganGoogle(),
                            icon: const Icon(Icons.g_mobiledata, size: 24),
                            label: const Text(
                              'Masuk dengan Google',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sedang,
                              ),
                              side: const BorderSide(
                                color: AppColors.ink,
                                width: AppSizes.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusTombol,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.besar),
                          // Beralih Mode Masuk / Daftar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _modeDaftar
                                    ? 'Sudah punya akun?'
                                    : 'Belum punya akun?',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              TextButton(
                                onPressed: sedangMemuat
                                    ? null
                                    : () {
                                        setState(() {
                                          _modeDaftar = !_modeDaftar;
                                          _formKey.currentState?.reset();
                                        });
                                      },
                                child: Text(
                                  _modeDaftar ? 'Masuk di sini' : 'Daftar baru',
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
