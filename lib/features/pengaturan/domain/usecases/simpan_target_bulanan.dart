import '../repositories/pengaturan_repository.dart';

class SimpanTargetBulanan {
  final PengaturanRepository repository;

  SimpanTargetBulanan(this.repository);

  Future<void> call(int target) async {
    return repository.simpanTargetBulanan(target);
  }
}
