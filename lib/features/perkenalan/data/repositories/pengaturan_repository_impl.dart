import '../../domain/repositories/pengaturan_repository.dart';
import '../datasources/pengaturan_local_datasource.dart';

class PengaturanRepositoryImpl implements PengaturanRepository {
  final PengaturanLocalDataSource _dataSource;

  PengaturanRepositoryImpl({PengaturanLocalDataSource? dataSource})
      : _dataSource = dataSource ?? PengaturanLocalDataSource();

  static const String _kunciOnboardingSelesai = 'onboarding_selesai';
  static const String _kunciTargetBulanan = 'target_bulanan';

  @override
  Future<bool> bacaStatusOnboarding() async {
    final nilai = await _dataSource.baca(_kunciOnboardingSelesai);
    return nilai == '1';
  }

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {
    await _dataSource.simpan(_kunciOnboardingSelesai, selesai ? '1' : '0');
  }

  @override
  Future<int?> bacaTargetBulanan() async {
    final nilai = await _dataSource.baca(_kunciTargetBulanan);
    if (nilai == null || nilai.trim().isEmpty) return null;
    return int.tryParse(nilai);
  }

  @override
  Future<void> simpanTargetBulanan(int target) async {
    await _dataSource.simpan(_kunciTargetBulanan, target.toString());
  }

  @override
  Future<String?> bacaPengaturan(String kunci) {
    return _dataSource.baca(kunci);
  }

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) {
    return _dataSource.simpan(kunci, nilai);
  }
}
