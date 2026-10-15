import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/pengaturan_repository.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final PengaturanRepository pengaturanRepository;

  OnboardingCubit({required this.pengaturanRepository})
      : super(const OnboardingInitial());

  Future<void> periksaStatus() async {
    emit(const OnboardingLoading());
    try {
      final selesai = await pengaturanRepository.bacaStatusOnboarding();
      final target = await pengaturanRepository.bacaTargetBulanan();
      if (isClosed) return;
      emit(OnboardingSuccess(selesai: selesai, targetBulanan: target));
    } catch (e) {
      if (isClosed) return;
      emit(OnboardingError(e.toString()));
    }
  }

  /// Menyimpan target bulanan dan menandai onboarding selesai ('1').
  Future<void> simpanTargetDanSelesai(int target) async {
    emit(const OnboardingLoading());
    try {
      await pengaturanRepository.simpanTargetBulanan(target);
      await pengaturanRepository.simpanStatusOnboarding(true);
      if (isClosed) return;
      emit(OnboardingSuccess(selesai: true, targetBulanan: target));
    } catch (e) {
      if (isClosed) return;
      emit(OnboardingError(e.toString()));
    }
  }

  /// Menandai onboarding selesai ('1') tanpa menyimpan target bulanan ("Nanti saja").
  Future<void> lewatiTargetDanSelesai() async {
    emit(const OnboardingLoading());
    try {
      await pengaturanRepository.simpanStatusOnboarding(true);
      final target = await pengaturanRepository.bacaTargetBulanan();
      if (isClosed) return;
      emit(OnboardingSuccess(selesai: true, targetBulanan: target));
    } catch (e) {
      if (isClosed) return;
      emit(OnboardingError(e.toString()));
    }
  }
}
