import '../repositories/pindai_repository.dart';

/// Use case untuk mengambil sisa jatah bonus kuota pindai dari iklan pekan berjalan.
class AmbilSisaBonusIklan {
  final PindaiRepository repository;

  AmbilSisaBonusIklan(this.repository);

  Future<int> call() {
    return repository.ambilSisaBonusIklan();
  }
}
