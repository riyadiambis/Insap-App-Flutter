import '../entities/cadangan_info.dart';
import '../entities/rencana_cadangan.dart';

abstract class CadanganRepository {
  Future<RencanaCadangan> siapkanCadangan(String uid);
  Future<void> cadangkanData(String uid);
  Future<CadanganInfo> pulihkanData(String uid);
  Stream<CadanganInfo?> pantauCadanganTerakhir(String uid);
  Future<CadanganInfo?> ambilCadanganTerakhir(String uid);
}
