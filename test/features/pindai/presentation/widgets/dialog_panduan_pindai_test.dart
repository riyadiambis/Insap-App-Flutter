import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';
import 'package:insap/features/pengaturan/domain/usecases/baca_status_panduan_pindai.dart';
import 'package:insap/features/pengaturan/domain/usecases/simpan_status_panduan_pindai.dart';
import 'package:insap/features/pindai/presentation/widgets/dialog_panduan_pindai.dart';

class _FakePengaturanRepository implements PengaturanRepository {
  final Map<String, String> _data = {};

  @override
  Future<bool> bacaStatusOnboarding() async => false;

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {}

  @override
  Future<int?> bacaTargetBulanan() async => null;

  @override
  Future<void> simpanTargetBulanan(int target) async {}

  @override
  Future<String?> bacaPengaturan(String kunci) async => _data[kunci];

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {
    _data[kunci] = nilai;
  }
}

void main() {
  final sl = GetIt.instance;
  late _FakePengaturanRepository fakeRepo;

  setUp(() async {
    await sl.reset();
    fakeRepo = _FakePengaturanRepository();
    sl.registerSingleton<PengaturanRepository>(fakeRepo);
    sl.registerSingleton(BacaStatusPanduanPindai(fakeRepo));
    sl.registerSingleton(SimpanStatusPanduanPindai(fakeRepo));
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('Dialog panduan menampilkan informasi dan centang jangan tampilkan lagi',
      (tester) async {
    bool lanjutDipanggil = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              tampilkanDialogPanduanPindai(
                context,
                simpanStatusPanduanPindai: SimpanStatusPanduanPindai(fakeRepo),
                onLanjut: () => lanjutDipanggil = true,
              );
            },
            child: const Text('Buka'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    expect(find.text('Panduan Pindai Struk'), findsOneWidget);
    expect(
      find.textContaining('AI membaca tiap barang dan mengelompokkannya per kategori'),
      findsOneWidget,
    );
    expect(find.text('Jangan tampilkan lagi'), findsOneWidget);
    expect(find.text('Nanti'), findsOneWidget);
    expect(find.text('Lanjut pindai'), findsOneWidget);

    // Centang "Jangan tampilkan lagi"
    await tester.tap(find.text('Jangan tampilkan lagi'));
    await tester.pumpAndSettle();

    // Tekan "Lanjut pindai"
    await tester.tap(find.text('Lanjut pindai'));
    await tester.pumpAndSettle();

    expect(lanjutDipanggil, isTrue);
    expect(await fakeRepo.bacaPengaturan('panduan_pindai_disembunyikan'), '1');
    expect(await sl<BacaStatusPanduanPindai>().call(), isTrue);
  });
}
