import 'package:flutter/material.dart';

// halaman sementara, nanti diisi Dafa di ISSUE-03 tanpa perlu nyentuh router
class HalamanDetailTransaksi extends StatelessWidget {
  final int id;

  const HalamanDetailTransaksi({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Segera hadir: detail transaksi #$id'),
      ),
    );
  }
}
