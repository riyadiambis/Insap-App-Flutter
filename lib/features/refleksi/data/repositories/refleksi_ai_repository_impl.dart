import '../../../pengaturan/domain/repositories/pengaturan_repository.dart';
import '../../domain/entities/refleksi_ai_entity.dart';
import '../../domain/repositories/refleksi_ai_repository.dart';
import '../datasources/refleksi_ai_remote_datasource.dart';
import '../models/hasil_refleksi_ai_model.dart';

class RefleksiAiRepositoryImpl implements RefleksiAiRepository {
  static const String prefixKunciCache = 'refleksi_ai_';

  final RefleksiAiRemoteDataSource remoteDataSource;
  final PengaturanRepository pengaturanRepository;

  RefleksiAiRepositoryImpl({
    required this.remoteDataSource,
    required this.pengaturanRepository,
  });

  static String kunciCacheUntukSenin(String tanggalSeninIso) =>
      '$prefixKunciCache$tanggalSeninIso';

  @override
  Future<List<SaranRefleksiAi>> ambilAtauMintaSaran(
    RingkasanRefleksiAiInput input,
  ) async {
    final kunci = kunciCacheUntukSenin(input.tanggalSeninIso);
    final daftarNama = input.daftarKategori.map((k) => k.nama).toList();

    final tersimpan = await pengaturanRepository.bacaPengaturan(kunci);
    if (tersimpan != null && tersimpan.trim().isNotEmpty) {
      try {
        final model = HasilRefleksiAiModel.fromRawText(
          tersimpan,
          daftarKategori: daftarNama,
        );
        return model.saran;
      } catch (_) {
        // Cache rusak, lanjutkan memanggil AI dan timpa saat berhasil.
      }
    }

    final saran = await remoteDataSource.mintaSaran(input);
    final jsonUntukSimpan = HasilRefleksiAiModel(saran: saran).toJsonString();
    await pengaturanRepository.simpanPengaturan(kunci, jsonUntukSimpan);
    return saran;
  }
}
