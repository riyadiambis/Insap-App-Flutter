import '../entities/refleksi_ai_entity.dart';

abstract class RefleksiAiRepository {
  Future<List<SaranRefleksiAi>> ambilAtauMintaSaran(
    RingkasanRefleksiAiInput input,
  );
}
