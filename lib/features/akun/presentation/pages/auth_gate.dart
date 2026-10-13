import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/pengguna_entity.dart';
import '../../domain/repositories/akun_repository.dart';
import '../cubit/akun_cubit.dart';
import 'halaman_akun.dart';
import 'halaman_masuk.dart';

class AuthGate extends StatelessWidget {
  final Stream<PenggunaEntity?>? streamPengguna;

  const AuthGate({super.key, this.streamPengguna});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AkunCubit>(),
      child: StreamBuilder<PenggunaEntity?>(
        stream: streamPengguna ?? sl<AkunRepository>().pantauPengguna(),
        builder: (context, snapshot) {
          final pengguna = snapshot.data;
          if (pengguna != null) {
            return HalamanAkun(pengguna: pengguna);
          }
          return const HalamanMasuk();
        },
      ),
    );
  }
}
