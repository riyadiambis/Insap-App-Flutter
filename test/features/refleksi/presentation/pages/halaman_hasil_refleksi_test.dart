import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/network/gemini_client.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/core/widgets/maskot_struki.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/pengaturan/domain/repositories/pengaturan_repository.dart';
import 'package:insap/features/pengaturan/domain/usecases/ambil_target_bulanan.dart';
import 'package:insap/features/refleksi/domain/entities/refleksi_ai_entity.dart';
import 'package:insap/features/refleksi/domain/repositories/refleksi_ai_repository.dart';
import 'package:insap/features/refleksi/domain/usecases/minta_refleksi_ai.dart';
import 'package:insap/features/refleksi/presentation/cubit/hasil_refleksi_cubit.dart';
import 'package:insap/features/refleksi/presentation/pages/halaman_hasil_refleksi.dart';
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
  List<TransaksiEntity> daftarPekanIni = const [];
  List<TransaksiEntity> daftarPekanLalu = const [];

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    if (tanggalMulai == '2026-11-16') return daftarPekanIni;
    return daftarPekanLalu;
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
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftar) async =>
      List.generate(daftar.length, (i) => i + 1);
}

class _FakePengaturanRepo implements PengaturanRepository {
  int? targetBulanan;

  @override
  Future<String?> bacaPengaturan(String kunci) async => null;

  @override
  Future<void> simpanPengaturan(String kunci, String nilai) async {}

  @override
  Future<bool> bacaStatusOnboarding() async => true;

  @override
  Future<void> simpanStatusOnboarding(bool selesai) async {}

  @override
  Future<int?> bacaTargetBulanan() async => targetBulanan;

  @override
  Future<void> simpanTargetBulanan(int target) async {
    targetBulanan = target;
  }
}

class _FakeRefleksiAiRepository implements RefleksiAiRepository {
  Future<List<SaranRefleksiAi>> Function()? handler;

  @override
  Future<List<SaranRefleksiAi>> ambilAtauMintaSaran(
    RingkasanRefleksiAiInput input,
  ) {
    if (handler != null) return handler!();
    return Future.value(const [
      SaranRefleksiAi(
        kategori: 'makan',
        teks: 'Makan turun 18%. Bekal dari rumah kelihatan hasilnya.',
      ),
      SaranRefleksiAi(
        kategori: 'nongkrong',
        teks: 'Nongkrong cuma 2 kali, lebih sedikit dari biasanya.',
      ),
      SaranRefleksiAi(
        kategori: 'umum',
        teks: 'Sisa Rp 87.500 bisa langsung dipindah ke tabungan.',
      ),
    ]);
  }
}

void main() {
  final tanggalAcuan = DateTime(2026, 11, 20);
  late _FakeTransaksiRepo transaksiRepo;
  late _FakePengaturanRepo pengaturanRepo;
  late _FakeRefleksiAiRepository aiRepo;
  late HasilRefleksiCubit cubit;

  setUp(() {
    transaksiRepo = _FakeTransaksiRepo();
    pengaturanRepo = _FakePengaturanRepo();
    aiRepo = _FakeRefleksiAiRepository();
    final useCase = MintaRefleksiAi(
      refleksiAiRepository: aiRepo,
      transaksiRepository: transaksiRepo,
      kategoriRepository: _FakeKategoriRepo(),
      ambilTargetBulanan: AmbilTargetBulanan(pengaturanRepo),
      sekarang: () => tanggalAcuan,
    );
    cubit = HasilRefleksiCubit(mintaRefleksiAi: useCase);
  });

  tearDown(() => cubit.close());

  Widget buatWidgetUji() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider<HasilRefleksiCubit>.value(
        value: cubit,
        child: const HalamanHasilRefleksi(),
      ),
    );
  }

  testWidgets('saat memuat menampilkan maskot detektif dan teks memuat', (
    tester,
  ) async {
    final completer = Completer<List<SaranRefleksiAi>>();
    aiRepo.handler = () => completer.future;

    unawaited(cubit.muat(tanggalAcuan));
    await tester.pumpWidget(buatWidgetUji());
    await tester.pump();

    expect(find.text('Refleksi pekan ini'), findsOneWidget);
    final maskot = tester.widget<MaskotStruki>(
      find.byKey(const Key('maskot_memuat_refleksi')),
    );
    expect(maskot.pose, PoseMaskot.detektif);
    expect(find.text('Struki sedang merangkum pekanmu...'), findsOneWidget);

    completer.complete(const [
      SaranRefleksiAi(kategori: 'makan', teks: 'Saran 1'),
      SaranRefleksiAi(kategori: 'nongkrong', teks: 'Saran 2'),
      SaranRefleksiAi(kategori: 'umum', teks: 'Saran 3'),
    ]);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'hasil hemat menampilkan kartu hijau muda, maskot hemat, dan 3 saran Kata Struki',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      pengaturanRepo.targetBulanan = 2000000; // target pekanan 500.000
      transaksiRepo.daftarPekanIni = const [
        TransaksiEntity(
          id: 1,
          jumlah: 412500,
          kategoriId: 1,
          tanggal: '2026-11-18',
          dibuatPada: '2026-11-18T10:00:00',
        ),
      ];

      await cubit.muat(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji());
      await tester.pumpAndSettle();

      expect(find.text('Hemat dan happy!'), findsOneWidget);
      expect(
        find.textContaining('Rp87.500 di bawah target', findRichText: true),
        findsOneWidget,
      );

      final maskot = tester.widget<MaskotStruki>(
        find.byKey(const Key('maskot_hasil_refleksi')),
      );
      expect(maskot.pose, PoseMaskot.hemat);

      expect(find.text('Kata Struki'), findsOneWidget);
      expect(
        find.text('Makan turun 18%. Bekal dari rumah kelihatan hasilnya.'),
        findsOneWidget,
      );
      expect(
        find.text('Nongkrong cuma 2 kali, lebih sedikit dari biasanya.'),
        findsOneWidget,
      );
      expect(
        find.text('Sisa Rp 87.500 bisa langsung dipindah ke tabungan.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.local_cafe), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'hasil boncos menampilkan kartu merah muda, maskot boncos, dan teks lewat target',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      pengaturanRepo.targetBulanan = 2000000; // target pekanan 500.000
      transaksiRepo.daftarPekanIni = const [
        TransaksiEntity(
          id: 1,
          jumlah: 564000,
          kategoriId: 6,
          tanggal: '2026-11-18',
          dibuatPada: '2026-11-18T10:00:00',
        ),
      ];

      await cubit.muat(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji());
      await tester.pumpAndSettle();

      expect(find.text('Astaga, lewat sedikit'), findsOneWidget);
      expect(
        find.textContaining('Rp64.000 di atas target', findRichText: true),
        findsOneWidget,
      );

      final maskot = tester.widget<MaskotStruki>(
        find.byKey(const Key('maskot_hasil_refleksi')),
      );
      expect(maskot.pose, PoseMaskot.boncos);
    },
  );

  testWidgets(
    'hasil tanpa target menyesuaikan teks dibanding pekan lalu',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      pengaturanRepo.targetBulanan = null;
      transaksiRepo.daftarPekanIni = const [
        TransaksiEntity(
          id: 1,
          jumlah: 150000,
          kategoriId: 1,
          tanggal: '2026-11-18',
          dibuatPada: '2026-11-18T10:00:00',
        ),
      ];
      transaksiRepo.daftarPekanLalu = const [
        TransaksiEntity(
          id: 2,
          jumlah: 200000,
          kategoriId: 1,
          tanggal: '2026-11-11',
          dibuatPada: '2026-11-11T10:00:00',
        ),
      ];

      await cubit.muat(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji());
      await tester.pumpAndSettle();

      expect(find.text('Hemat dan happy!'), findsOneWidget);
      expect(
        find.textContaining('dibanding pekan lalu', findRichText: true),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'keadaan galat menampilkan maskot puyeng, pesan ramah, dan tombol Coba lagi yang memanggil ulang AI',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int percobaan = 0;
      aiRepo.handler = () async {
        percobaan++;
        if (percobaan == 1) {
          throw const GeminiException('Tidak ada koneksi internet', 503);
        }
        return const [
          SaranRefleksiAi(kategori: 'makan', teks: 'Saran 1 berhasil'),
          SaranRefleksiAi(kategori: 'nongkrong', teks: 'Saran 2 berhasil'),
          SaranRefleksiAi(kategori: 'umum', teks: 'Saran 3 berhasil'),
        ];
      };

      await cubit.muat(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji());
      await tester.pumpAndSettle();

      final maskot = tester.widget<MaskotStruki>(
        find.byKey(const Key('maskot_galat_refleksi')),
      );
      expect(maskot.pose, PoseMaskot.puyeng);
      expect(
        find.text(
          'Struki belum bisa merangkum sekarang. Coba lagi sebentar lagi.',
        ),
        findsOneWidget,
      );

      final tombolCobaLagi = find.byKey(const Key('tombol_coba_lagi_refleksi'));
      expect(tombolCobaLagi, findsOneWidget);
      expect(tester.getSize(tombolCobaLagi).height, greaterThanOrEqualTo(48));

      await tester.tap(tombolCobaLagi);
      await tester.pumpAndSettle();

      expect(percobaan, 2);
      expect(find.text('Saran 1 berhasil'), findsOneWidget);
    },
  );
}
