import '../repositories/pindai_repository.dart';

/// Use case untuk mengklaim +1 bonus kuota pindai setelah menonton iklan rewarded.
class KlaimBonusIklan {
  final PindaiRepository repository;

  KlaimBonusIklan(this.repository);

  Future<bool> call() {
    return repository.klaimBonusIklan();
  }
}
