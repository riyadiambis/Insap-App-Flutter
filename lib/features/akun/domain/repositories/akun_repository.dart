import '../entities/pengguna_entity.dart';

abstract class AkunRepository {
  Stream<PenggunaEntity?> pantauPengguna();
  Future<PenggunaEntity?> ambilPenggunaSaatIni();
  Future<PenggunaEntity> daftarDenganEmail({
    required String email,
    required String kataSandi,
  });
  Future<PenggunaEntity> masukDenganEmail({
    required String email,
    required String kataSandi,
  });
  Future<void> keluar();
  Future<void> kirimResetKataSandi(String email);
  Future<PenggunaEntity?> masukDenganGoogle();
}
