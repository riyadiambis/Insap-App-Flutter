import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

/// BlocObserver sederhana (P06-Cubit). Dipasang di `main.dart` pada
/// Tahap 9, lewat `Bloc.observer = AppBlocObserver();`. Berguna untuk
/// melihat transisi state seluruh Cubit di satu tempat saat debugging,
/// tanpa menaruh `print` di masing-masing Cubit.
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} error: $error');
    super.onError(bloc, error, stackTrace);
  }
}
