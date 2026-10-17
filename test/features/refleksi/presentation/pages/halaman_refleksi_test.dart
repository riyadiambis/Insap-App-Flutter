import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/refleksi/domain/entities/refleksi_mingguan_entity.dart';
import 'package:insap/features/refleksi/domain/repositories/refleksi_repository.dart';
import 'package:insap/features/refleksi/domain/usecases/ambil_refleksi_pekan.dart';
import 'package:insap/features/refleksi/domain/usecases/simpan_refleksi.dart';
import 'package:insap/features/refleksi/presentation/cubit/refleksi_cubit.dart';
import 'package:insap/features/refleksi/presentation/pages/halaman_refleksi.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';

class _FakeKategoriRepository implements KategoriRepository {
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
      id: 5,
      nama: 'jajan daring',
      ikon: 'shopping_bag',
      warna: '#8B5FBF',
      kelompokKakeibo: 'opsional',
      bawaan: 1,
      urutan: 5,
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
    KategoriEntity(
      id: 8,
      nama: 'darurat',
      ikon: 'medical_services',
      warna: '#1F9254',
      kelompokKakeibo: 'ekstra',
      bawaan: 1,
      urutan: 8,
    ),
  ];
}

class _FakeTransaksiRepository implements TransaksiRepository {
  List<TransaksiEntity> daftarPekanIni = const [];
  List<TransaksiEntity> daftarPekanLalu = const [];

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async {
    if (tanggalMulai == '2026-10-12') {
      return daftarPekanIni;
    }
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
}

class _FakeRefleksiRepository implements RefleksiRepository {
  RefleksiMingguanEntity? refleksiTersimpan;
  int? targetPekanDepan;

  @override
  Future<RefleksiMingguanEntity?> ambilPerMinggu(
    int tahun,
    int mingguKe,
  ) async => refleksiTersimpan;

  @override
  Future<int> simpanRefleksi(RefleksiMingguanEntity refleksi) async {
    refleksiTersimpan = refleksi.copyWith(id: 1);
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
  late _FakeTransaksiRepository fakeTransaksiRepo;
  late _FakeRefleksiRepository fakeRefleksiRepo;
  late RefleksiCubit cubit;
  final tanggalAcuan = DateTime(2026, 10, 18);

  setUp(() {
    fakeTransaksiRepo = _FakeTransaksiRepository();
    fakeRefleksiRepo = _FakeRefleksiRepository();
    final ambilUseCase = AmbilRefleksiPekan(
      refleksiRepository: fakeRefleksiRepo,
      transaksiRepository: fakeTransaksiRepo,
      kategoriRepository: _FakeKategoriRepository(),
      sekarang: () => tanggalAcuan,
    );
    final simpanUseCase = SimpanRefleksi(
      fakeRefleksiRepo,
      sekarang: () => tanggalAcuan,
    );
    cubit = RefleksiCubit(
      ambilRefleksiPekan: ambilUseCase,
      simpanRefleksi: simpanUseCase,
    );
  });

  tearDown(() => cubit.close());

  Widget buatWidgetUji({BerandaCubit? berandaCubit}) {
    final child = BlocProvider<RefleksiCubit>.value(
      value: cubit,
      child: const HalamanRefleksi(),
    );
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: berandaCubit != null
          ? BlocProvider<BerandaCubit>.value(value: berandaCubit, child: child)
          : child,
    );
  }

  testWidgets(
    'menampilkan kartu agregat 4 kelompok Kakeibo, perbandingan pekan lalu, dan renungan pengen',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeRefleksiRepo.targetPekanDepan = 350000;
      fakeTransaksiRepo.daftarPekanIni = const [
        TransaksiEntity(
          id: 1,
          jumlah: 120000,
          kategoriId: 1, // esensial
          tanggal: '2026-10-13',
          dibuatPada: '2026-10-13T10:00:00',
        ),
        TransaksiEntity(
          id: 2,
          jumlah: 80000,
          kategoriId: 6, // hiburan
          tanggal: '2026-10-15',
          tipeKebutuhan: 'pengen',
          dibuatPada: '2026-10-15T20:00:00',
        ),
      ];
      fakeTransaksiRepo.daftarPekanLalu = const [
        TransaksiEntity(
          id: 3,
          jumlah: 150000,
          kategoriId: 1,
          tanggal: '2026-10-07',
          dibuatPada: '2026-10-07T10:00:00',
        ),
      ];

      await cubit.muatRefleksi(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji());
      await tester.pumpAndSettle();

      expect(find.text('4 Kelompok Kakeibo'), findsOneWidget);
      expect(find.text('Esensial (60%)'), findsOneWidget);
      expect(find.text('Hiburan (40%)'), findsOneWidget);
      expect(find.text('Rp200.000'), findsOneWidget);
      expect(find.text('Target: Rp350.000'), findsOneWidget);
      expect(find.textContaining('Pekan lalu: Rp150.000'), findsOneWidget);
      expect(find.text('40% Pengen'), findsOneWidget);
      expect(
        find.textContaining('Pekan ini 40% pengeluaranmu ditandai pengen'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'menampilkan validasi form saat tombol simpan ditekan dengan catatan kosong',
    (tester) async {
      tester.view.physicalSize = const Size(460, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await cubit.muatRefleksi(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji());
      await tester.pumpAndSettle();

      final tombolSimpan = find.byKey(const Key('tombol_simpan_refleksi'));
      await tester.ensureVisible(tombolSimpan);
      await tester.pumpAndSettle();
      await tester.tap(tombolSimpan);
      await tester.pumpAndSettle();

      expect(
        find.text('Tuliskan satu hal yang ingin diperbaiki pekan depan.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pekan tanpa transaksi tetap menampilkan Rp0, belum ada target, dan pesan ramah',
    (tester) async {
      tester.view.physicalSize = const Size(460, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await cubit.muatRefleksi(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji());
      await tester.pumpAndSettle();

      expect(find.text('Target: belum ada target'), findsOneWidget);
      expect(
        find.textContaining('Belum ada pengeluaran tercatat pekan ini'),
        findsOneWidget,
      );
      expect(find.text('0% Pengen'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('input_catatan_refleksi')),
        'Mulai catat pengeluaran harian minggu depan',
      );
      await tester.enterText(
        find.byKey(const Key('input_target_pekan_depan')),
        '300000',
      );
      final tombolSimpan = find.byKey(const Key('tombol_simpan_refleksi'));
      await tester.ensureVisible(tombolSimpan);
      await tester.pumpAndSettle();
      await tester.tap(tombolSimpan);
      await tester.pumpAndSettle();

      expect(fakeRefleksiRepo.refleksiTersimpan, isNotNull);
      expect(
        fakeRefleksiRepo.refleksiTersimpan?.catatanRefleksi,
        'Mulai catat pengeluaran harian minggu depan',
      );
      expect(fakeRefleksiRepo.targetPekanDepan, 300000);
    },
  );

  testWidgets(
    'otomatis memuat ulang pengeluaran sepekan saat BerandaCubit memancarkan BerandaLoaded setelah transaksi baru ditambahkan',
    (tester) async {
      tester.view.physicalSize = const Size(460, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final berandaCubit = BerandaCubit(
        ambilRingkasanPekan: AmbilRingkasanPekan(
          fakeTransaksiRepo,
          sekarang: () => tanggalAcuan,
        ),
      );
      addTearDown(berandaCubit.close);

      fakeTransaksiRepo.daftarPekanIni = const [
        TransaksiEntity(
          id: 1,
          jumlah: 50000,
          kategoriId: 1,
          tanggal: '2026-10-13',
          dibuatPada: '2026-10-13T10:00:00',
        ),
      ];

      await cubit.muatRefleksi(tanggalAcuan);
      await tester.pumpWidget(buatWidgetUji(berandaCubit: berandaCubit));
      await tester.pumpAndSettle();

      expect(find.text('Rp50.000'), findsAtLeastNWidgets(1));

      // simulasi pengguna menambah transaksi baru hari ini lalu BerandaCubit dimuat ulang
      fakeTransaksiRepo.daftarPekanIni = const [
        TransaksiEntity(
          id: 1,
          jumlah: 50000,
          kategoriId: 1,
          tanggal: '2026-10-13',
          dibuatPada: '2026-10-13T10:00:00',
        ),
        TransaksiEntity(
          id: 2,
          jumlah: 35000,
          kategoriId: 6,
          tanggal: '2026-10-18',
          tipeKebutuhan: 'pengen',
          dibuatPada: '2026-10-18T12:00:00',
        ),
      ];

      await berandaCubit.muatRingkasan();
      await tester.pumpAndSettle();

      expect(find.text('Rp85.000'), findsOneWidget);
      expect(find.text('Rp35.000'), findsAtLeastNWidgets(1));
    },
  );
}
