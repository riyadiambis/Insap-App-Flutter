import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../cubit/akun_cubit.dart';
import '../cubit/akun_state.dart';
import 'halaman_akun.dart';
import 'halaman_masuk.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AkunCubit>(),
      child: BlocBuilder<AkunCubit, AkunState>(
        builder: (context, state) {
          if (state is AkunMasuk) {
            return HalamanAkun(pengguna: state.pengguna);
          }
          return const HalamanMasuk();
        },
      ),
    );
  }
}
