import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/paper_background.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/kartu_buku_tulis.dart';
import '../../../../core/widgets/tombol_stabilo.dart';
import '../../../beranda/presentation/cubit/beranda_cubit.dart';
import '../../../kategori/presentation/cubit/kategori_cubit.dart';
import '../../../kategori/presentation/cubit/kategori_state.dart';
import '../../../transaksi/presentation/riwayat/cubit/riwayat_cubit.dart';
import '../../domain/entities/hasil_pindai_entity.dart';
import '../cubit/pindai_cubit.dart';

/// Layar konfirmasi draf transaksi hasil pemindaian Gemini AI (F-10, P04-Form).
/// Pengguna dapat meninjau, menyunting nominal, nama toko, tanggal, dan kategori sebelum disimpan.
class HalamanKonfirmasiDraf extends StatefulWidget {
  final HasilPindaiEntity hasilPindai;

  const HalamanKonfirmasiDraf({super.key, required this.hasilPindai});

  @override
  State<HalamanKonfirmasiDraf> createState() => _HalamanKonfirmasiDrafState();
}

class _HalamanKonfirmasiDrafState extends State<HalamanKonfirmasiDraf> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nominalController;
  late final TextEditingController _namaTokoController;
  late final TextEditingController _tanggalController;
  late final TextEditingController _catatanController;
  final FocusNode _nominalFocusNode = FocusNode();

  int? _kategoriIdTerpilih;
  bool _sedangMenyimpan = false;

  @override
  void initState() {
    super.initState();
    final h = widget.hasilPindai;
    _nominalController = TextEditingController(
      text: h.total != null ? h.total.toString() : '',
    );
    _namaTokoController = TextEditingController(text: h.namaToko ?? '');
    _tanggalController = TextEditingController(
      text: h.tanggal ?? _tanggalHariIniIso(),
    );
    _catatanController = TextEditingController();

    // Jika total null (misal struk robek), fokuskan otomatis ke kolom nominal
    if (h.total == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nominalFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _namaTokoController.dispose();
    _tanggalController.dispose();
    _catatanController.dispose();
    _nominalFocusNode.dispose();
    super.dispose();
  }

  String _tanggalHariIniIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pilihTanggal() async {
    final sekarang = DateTime.now();
    DateTime awal = sekarang;
    final parsed = DateTime.tryParse(_tanggalController.text);
    if (parsed != null && !parsed.isAfter(sekarang)) {
      awal = parsed;
    }

    final hasil = await showDatePicker(
      context: context,
      initialDate: awal,
      firstDate: DateTime(2020),
      lastDate: sekarang,
      helpText: 'PILIH TANGGAL TRANSAKSI',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
    );

    if (hasil != null) {
      setState(() {
        _tanggalController.text =
            '${hasil.year.toString().padLeft(4, '0')}-'
            '${hasil.month.toString().padLeft(2, '0')}-'
            '${hasil.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kategoriIdTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori transaksi')),
      );
      return;
    }

    final nominal = int.tryParse(
      _nominalController.text.replaceAll(RegExp(r'[^\d]'), ''),
    );
    if (nominal == null || nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih besar dari 0')),
      );
      return;
    }

    setState(() => _sedangMenyimpan = true);

    final cubit = context.read<PindaiCubit>();
    final sukses = await cubit.simpanTransaksi(
      jumlah: nominal,
      kategoriId: _kategoriIdTerpilih!,
      tanggal: _tanggalController.text.trim(),
      namaToko: _namaTokoController.text.trim().isNotEmpty
          ? _namaTokoController.text.trim()
          : null,
      catatan: _catatanController.text.trim().isNotEmpty
          ? _catatanController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _sedangMenyimpan = false);

    if (sukses) {
      // 1. Segarkan ringkasan Beranda dan sisa kuota (ISSUE-10)
      try {
        context.read<BerandaCubit>().muatRingkasan();
      } catch (_) {}

      // 2. Segarkan daftar di tab Riwayat (ISSUE-16)
      try {
        context.read<RiwayatCubit>().muatRiwayat();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi struk berhasil disimpan')),
      );

      // Kembali ke beranda
      try {
        context.go('/');
      } catch (_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyakinanRendah = widget.hasilPindai.keyakinan < 0.5;

    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.batasLebarKonten,
            ),
            child: Column(
              children: [
                // Header Navigasi Atas
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.besar,
                    top: AppSpacing.besar,
                    right: AppSpacing.besar,
                    bottom: AppSpacing.sedang,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            try {
                              context.pop();
                            } catch (_) {}
                          }
                        },
                        child: Container(
                          width: AppSizes.kotakIkonAksi,
                          height: AppSizes.kotakIkonAksi,
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            border: Border.all(
                              color: AppColors.ink,
                              width: AppSizes.border,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusKotakIkonAksi,
                            ),
                            boxShadow: const [AppTheme.bayanganKecilGelap],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.ink,
                            size: AppSizes.ikonAksi,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sedang),
                      Expanded(
                        child: Text(
                          'Konfirmasi Draf Struk',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.besar),
                      children: [
                        // Peringatan jika keyakinan rendah (< 0.5)
                        if (keyakinanRendah) ...[
                          KartuBukuTulis(
                            backgroundColor: AppColors.stabilo,
                            padding: const EdgeInsets.all(AppSpacing.sedang),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.ink,
                                  size: 28,
                                ),
                                const SizedBox(width: AppSpacing.sedang),
                                Expanded(
                                  child: Text(
                                    'Hasil bacaan kurang yakin (${(widget.hasilPindai.keyakinan * 100).toInt()}%). '
                                    'Mohon periksa kembali kolom nominal dan data lainnya.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.besar),
                        ],

                        // Kotak Form Draf
                        KartuBukuTulis(
                          backgroundColor: AppColors.paper,
                          padding: const EdgeInsets.all(AppSpacing.besar),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rincian Transaksi',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sedang),

                              // Nominal
                              Text(
                                'TOTAL NOMINAL *',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.inkSoft,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.mini),
                              TextFormField(
                                controller: _nominalController,
                                focusNode: _nominalFocusNode,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixText: 'Rp ',
                                  hintText: '0',
                                  filled: true,
                                  fillColor: AppColors.paper,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusBadge,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusBadge,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Nominal tidak boleh kosong';
                                  }
                                  final numVal = int.tryParse(
                                    val.replaceAll(RegExp(r'[^\d]'), ''),
                                  );
                                  if (numVal == null || numVal <= 0) {
                                    return 'Nominal harus lebih dari 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.sedang),

                              // Nama Toko / Merchant
                              Text(
                                'NAMA TOKO / MERCHANT',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.inkSoft,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.mini),
                              TextFormField(
                                controller: _namaTokoController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Contoh: Indomaret, SPBU, Kopi Kenangan',
                                  filled: true,
                                  fillColor: AppColors.paper,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusBadge,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusBadge,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sedang),

                              // Tanggal
                              Text(
                                'TANGGAL *',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.inkSoft,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.mini),
                              InkWell(
                                onTap: _pilihTanggal,
                                child: IgnorePointer(
                                  child: TextFormField(
                                    controller: _tanggalController,
                                    decoration: InputDecoration(
                                      suffixIcon: const Icon(
                                        Icons.calendar_month_outlined,
                                        color: AppColors.ink,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.paper,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusBadge,
                                        ),
                                        borderSide: const BorderSide(
                                          color: AppColors.ink,
                                          width: AppSizes.border,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusBadge,
                                        ),
                                        borderSide: const BorderSide(
                                          color: AppColors.ink,
                                          width: AppSizes.border,
                                        ),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Tanggal tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sedang),

                              // Pilihan Kategori
                              Text(
                                'KATEGORI *',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.inkSoft,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.mini),
                              BlocBuilder<KategoriCubit, KategoriState>(
                                builder: (context, state) {
                                  if (state is KategoriLoaded) {
                                    // Cari kategori yang cocok dengan kategori_usulan Gemini
                                    if (_kategoriIdTerpilih == null &&
                                        state.kategoriList.isNotEmpty) {
                                      final usulan = widget
                                          .hasilPindai
                                          .kategoriUsulan
                                          ?.toLowerCase();
                                      final cocok = state.kategoriList
                                          .firstWhere(
                                            (k) =>
                                                k.nama.toLowerCase() ==
                                                    usulan ||
                                                k.nama.toLowerCase().contains(
                                                  usulan ?? '',
                                                ),
                                            orElse: () =>
                                                state.kategoriList.first,
                                          );
                                      _kategoriIdTerpilih = cocok.id;
                                    }

                                    return DropdownButtonFormField<int>(
                                      initialValue: _kategoriIdTerpilih,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AppColors.paper,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusBadge,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.ink,
                                            width: AppSizes.border,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusBadge,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.ink,
                                            width: AppSizes.border,
                                          ),
                                        ),
                                      ),
                                      items: state.kategoriList.map((k) {
                                        return DropdownMenuItem<int>(
                                          value: k.id,
                                          child: Text(
                                            k.nama,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (id) {
                                        setState(
                                          () => _kategoriIdTerpilih = id,
                                        );
                                      },
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.sedang),

                              // Catatan Tambahan
                              Text(
                                'CATATAN TAMBAHAN (OPSIONAL)',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.inkSoft,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.mini),
                              TextFormField(
                                controller: _catatanController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: 'Tambahkan catatan jika perlu...',
                                  filled: true,
                                  fillColor: AppColors.paper,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusBadge,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusBadge,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.ink,
                                      width: AppSizes.border,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.besar),

                        // Tombol Aksi
                        TombolStabilo(
                          teks: 'Simpan ke Transaksi',
                          ikon: Icons.check_circle_outline,
                          isLoading: _sedangMenyimpan,
                          onPressed: _simpan,
                        ),
                        const SizedBox(height: AppSpacing.sedang),
                        Center(
                          child: TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              'Batal & Buang Draf',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkSoft,
                                  ),
                            ),
                          ),
                        ),
                      ],
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
