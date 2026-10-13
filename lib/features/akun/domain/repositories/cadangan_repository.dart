import '../entities/cadangan_info.dart';

abstract class CadanganRepository {
  Future<void> cadangkanData(String uid);
  Future<CadanganInfo> pulihkanData(String uid);
  Stream<CadanganInfo?> pantauCadanganTerakhir(String uid);
  Future<CadanganInfo?> ambilCadanganTerakhir(String uid);
}
