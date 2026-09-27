import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/paper_background.dart';
import '../../data/database_helper.dart';
import '../../data/models/kategori.dart';

class UjiDataPage extends StatefulWidget {
  const UjiDataPage({super.key});

  @override
  State<UjiDataPage> createState() => _UjiDataPageState();
}

class _UjiDataPageState extends State<UjiDataPage> {
  List<Kategori> _kategoriList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbHelper = DatabaseHelper();
    final list = await dbHelper.getKategoriBawaan();
    setState(() {
      _kategoriList = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uji Fondasi Data'),
        backgroundColor: AppColors.stabilo,
        foregroundColor: AppColors.ink,
      ),
      body: PaperBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    'Uji Format Rupiah (F-06)',
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.kartuDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('15000 -> ${formatRupiah(15000)}'),
                        Text('1000000 -> ${formatRupiah(1000000)}'),
                        Text('0 -> ${formatRupiah(0)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Uji Kategori Tersimpan (${_kategoriList.length})',
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ..._kategoriList.map((k) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.kartuDecoration(radius: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, color: AppColors.inkSoft),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  k.nama,
                                  style: AppTheme.lightTheme.textTheme.titleMedium,
                                ),
                                Text(
                                  'Kelompok: ${k.kelompokKakeibo} | Bawaan: ${k.bawaan}',
                                  style: AppTheme.lightTheme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(int.parse(k.warna.replaceAll('#', '0xFF'))),
                              shape: BoxShape.circle,
                            ),
                          )
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
