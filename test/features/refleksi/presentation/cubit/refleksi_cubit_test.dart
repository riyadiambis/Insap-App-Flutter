import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/refleksi/domain/entities/refleksi_mingguan_entity.dart';
import 'package:insap/features/refleksi/domain/repositories/refleksi_repository.dart';
import 'package:insap/features/refleksi/domain/usecases/ambil_refleksi_pekan.dart';
import 'package:insap/features/refleksi/domain/usecases/simpan_refleksi.dart';
import 'package:insap/features/refleksi/presentation/cubit/refleksi_cubit.dart';
import 'package:insap/features/refleksi/presentation/cubit/refleksi_state.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';

class _FakeKategoriRepo implements KategoriRepository {
  @override
  Future<List<KategoriEntity>> ambilSemua() async => const [
    KategoriEntity(
      id: 1,
      nama: 'makan',
      ikon: 'restaurant',
      warna: '#E8734A',
      kelompokKakeibo: 'esensial',
      bawaan: 1,
      urutan: 1,
    ),
    KategoriEntity(
      id: 6,
      nama: 'nongkrong',
      ikon: 'local_cafe',
      warna: '#FFB020',
      kelompokKakeibo: 'hiburan',
      bawaan: 1,
      urutan: 6,
    ),
  ];
}

class _FakeTransaksiRepo implements TransaksiRepository {
  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    if (tanggalMulai == '2026-10-12') {
      return const [
        TransaksiEntity(
          id: 1,
          jumlah: 60000,
          kategoriId: 1,
          tanggal: '2026-10-14',
          dibuatPada: '2026-10-14T10:00:00',
        ),
        TransaksiEntity(
          id: 2,
          jumlah: 40000,
          kategoriId: 6,
          tanggal: '2026-10-15',
          tipeKebutuhan: 'pengen',
          dibuatPada: '2026-10-15T19:00:00',
        ),
      ];
    }
    return const [];
  }

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 0;

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async =>
      List.generate(daftarTransaksi.length, (i) => i + 1);
}

class _FakeRefleksiRepo implements RefleksiRepository {
  RefleksiMingguanEntity? tersimpan;
  int? targetPekanDepan = 150000;

  @override
  Future<RefleksiMingguanEntity?> ambilPerMinggu(
    int tahun,
    int mingguKe,
  ) async => tersimpan;

  @override
  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi) async {
    tersimpan = refleksi.copyWith(id: 1);
    return 1;
  }

  @override
  Future<int?> bacaTargetPekanDepan() async => targetPekanDepan;

  @override
  Future<void> simpanTargetPekanDepan(int? target) async {
    targetPekanDepan = target;
  }
}

void main() {
  late _FakeRefleksiRepo refleksiRepo;
  late RefleksiCubit cubit;
  final tanggalAcuan = DateTime(2026, 10, 18);

  setUp(() {
    refleksiRepo = _FakeRefleksiRepo();
    final ambilUseCase = AmbilRefleksiPekan(
      refleksiRepository: refleksiRepo,
      transaksiRepository: _FakeTransaksiRepo(),
      kategoriRepository: _FakeKategoriRepo(),
      sekarang: () => tanggalAcuan,
    );
    final simpanUseCase = SimpanRefleksi(
      refleksiRepo,
      sekarang: () => tanggalAcuan,
    );
    cubit = RefleksiCubit(
      ambilRefleksiPekan: ambilUseCase,
      simpanRefleksi: simpanUseCase,
    );
  });

  tearDown(() => cubit.close());

  test('muatRefleksi memuat data agregat dan target pekan ini', () async {
    expect(cubit.state.status, RefleksiStatus.initial);

    await cubit.muatRefleksi(tanggalAcuan);

    expect(cubit.state.status, RefleksiStatus.success);
    expect(cubit.state.data, isNotNull);
    expect(cubit.state.data!.agregat.totalPekanIni, 100000);
    expect(cubit.state.data!.agregat.persentasePengen, 40);
    expect(cubit.state.data!.targetPekanIni, 150000);
  });

  test(
    'simpan memperbarui state menjadi saved dan memuat data terbaru',
    () async {
      await cubit.muatRefleksi(tanggalAcuan);
      await cubit.simpan(
        catatanRefleksi: 'Kurangi nongkrong malam minggu',
        targetPekanDepan: 120000,
        tanggalAcuan: tanggalAcuan,
      );

      expect(cubit.state.status, RefleksiStatus.saved);
      expect(
        cubit.state.data?.refleksiTersimpan?.catatanRefleksi,
        'Kurangi nongkrong malam minggu',
      );
      expect(cubit.state.data?.targetPekanIni, 150000);
      expect(cubit.state.data?.targetPekanDepan, 120000);
    },
  );
}
