import '../repositories/pindai_repository.dart';

/// Use case untuk mengambil sisa kuota pindai mingguan pengguna (F-11, P07-Clean).
class AmbilKuotaPindai {
  final PindaiRepository repository;

  AmbilKuotaPindai(this.repository);

  Future<int> call() {
    return repository.ambilSisaKuota();
  }
}
