import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HalamanBeranda extends StatelessWidget {
  const HalamanBeranda({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Segera hadir: HalamanBeranda'),
            if (kDebugMode)
              // tombol ini bersifat sementara, dihapus di Tahap 9
              TextButton(
                onPressed: () => context.push('/uji'),
                child: const Text('Buka halaman uji'),
              ),
          ],
        ),
      ),
    );
  }
}
