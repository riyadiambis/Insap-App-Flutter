import 'package:equatable/equatable.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

class OnboardingSuccess extends OnboardingState {
  final bool selesai;
  final int? targetBulanan;

  const OnboardingSuccess({required this.selesai, this.targetBulanan});

  @override
  List<Object?> get props => [selesai, targetBulanan];
}

class OnboardingError extends OnboardingState {
  final String pesan;

  const OnboardingError(this.pesan);

  @override
  List<Object?> get props => [pesan];
}
