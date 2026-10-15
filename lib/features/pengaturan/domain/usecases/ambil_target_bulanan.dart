import '../repositories/pengaturan_repository.dart';

class AmbilTargetBulanan {
  final PengaturanRepository repository;

  AmbilTargetBulanan(this.repository);

  Future<int?> call() async {
    return repository.bacaTargetBulanan();
  }
}
