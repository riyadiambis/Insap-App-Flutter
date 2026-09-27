import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/bloc/app_bloc_observer.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme.dart';
import 'features/beranda/presentation/cubit/beranda_cubit.dart';
import 'features/kategori/presentation/cubit/kategori_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  setupInjectionContainer();
  Bloc.observer = AppBlocObserver();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<KategoriCubit>()..muat()),
        BlocProvider(create: (_) => sl<BerandaCubit>()..muatRingkasan()),
      ],
      child: MaterialApp.router(
        title: 'Insap: Yuk Sadar Boncos',
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
