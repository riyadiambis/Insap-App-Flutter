import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/refleksi/domain/entities/refleksi_mingguan_entity.dart';
import 'package:insap/features/refleksi/domain/repositories/refleksi_repository.dart';
import 'package:insap/features/refleksi/domain/usecases/simpan_refleksi.dart';

class _InMemoryRefleksiRepository implements RefleksiRepository {
  final Map<String, RefleksiMingguanEntity> _rows = {};
  int? targetPekanDepan;
  int _nextId = 1;

  int get jumlahBaris => _rows.length;

  @override
  Future<RefleksiMingguanEntity?> ambilPerMinggu(
    int tahun,
    int mingguKe,
  ) async {
    return _rows['$tahun-$mingguKe'];
  }

  @override
  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi) async {
    final key = '${refleksi.tahun}-${refleksi.mingguKe}';
    final existing = _rows[key];
    final id = existing?.id ?? refleksi.id ?? _nextId++;
    _rows[key] = refleksi.copyWith(id: id);
    return id;
  }

  @override
  Future<int?> bacaTargetPekanDepan() async => targetPekanDepan;

  @override
  Future<void> simpanTargetPekanDepan(int? target) async {
    targetPekanDepan = target;
  }
}

void main() {
  late _InMemoryRefleksiRepository repo;
  late SimpanRefleksi useCase;
  final tanggalAcuan = DateTime(2026, 10, 18); // pekan ke-42 tahun 2026

  setUp(() {
    repo = _InMemoryRefleksiRepository();
    useCase = SimpanRefleksi(repo, sekarang: () => tanggalAcuan);
  });

  test('menyimpan catatan refleksi baru, menyalin target pekan ini dari pengaturan, dan memperbarui target_pekan_depan', () async {
    // target yang ditetapkan pekan sebelumnya di tabel pengaturan
    repo.targetPekanDepan = 350000;

    final tersimpan = await useCase(
      catatanRefleksi: 'Kurangi beli kopi kekinian saat nugas',
      realisasi: 320000,
      targetPekanDepan: 300000,
    );

    expect(tersimpan.tahun, 2026);
    expect(tersimpan.mingguKe, 42);
    expect(tersimpan.targetPengeluaran, 350000);
    expect(tersimpan.realisasi, 320000);
    expect(tersimpan.catatanRefleksi, 'Kurangi beli kopi kekinian saat nugas');
    expect(repo.targetPekanDepan, 300000);
    expect(repo.jumlahBaris, 1);
  });

  test('penyuntingan pada pekan berjalan memperbarui baris yang sama tanpa membuat entri ganda', () async {
    repo.targetPekanDepan = 350000;

    final pertama = await useCase(
      catatanRefleksi: 'Catatan awal',
      realisasi: 250000,
      targetPekanDepan: 300000,
    );

    final kedua = await useCase(
      catatanRefleksi: 'Catatan diperbarui akhir pekan',
      realisasi: 275000,
      targetPekanDepan: 280000,
    );

    expect(repo.jumlahBaris, 1);
    expect(kedua.id, pertama.id);
    expect(kedua.targetPengeluaran, 350000);
    expect(kedua.realisasi, 275000);
    expect(kedua.catatanRefleksi, 'Catatan diperbarui akhir pekan');
    expect(repo.targetPekanDepan, 280000);
  });

  test('menolak catatan refleksi kosong', () async {
    expect(
      () => useCase(catatanRefleksi: '   ', realisasi: 100000),
      throwsArgumentError,
    );
  });
}
