import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/network/gemini_client.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/pindai/domain/entities/hasil_pindai_entity.dart';
import 'package:insap/features/pindai/domain/repositories/pindai_repository.dart';
import 'package:insap/features/pindai/domain/usecases/ambil_kuota_pindai.dart';
import 'package:insap/features/pindai/domain/usecases/pindai_struk.dart';
import 'package:insap/features/pindai/presentation/cubit/pindai_cubit.dart';
import 'package:insap/features/pindai/presentation/cubit/pindai_state.dart';
import 'package:insap/features/pindai/presentation/pages/halaman_pindai.dart';
import 'package:insap/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:insap/features/transaksi/domain/repositories/transaksi_repository.dart';
import 'package:insap/features/transaksi/domain/usecases/ambil_ringkasan_pekan.dart';
import 'package:insap/features/transaksi/domain/usecases/tambah_transaksi.dart';

class _FakeKategoriRepository implements KategoriRepository {
  @override
  Future<List<KategoriEntity>> ambilSemua() async => const [
    KategoriEntity(
      id: 1,
      nama: 'Makan',
      ikon: 'restaurant',
      warna: '#E8734A',
      kelompokKakeibo: 'esensial',
      bawaan: 1,
      urutan: 1,
    ),
  ];
}

class _FakeTransaksiRepository implements TransaksiRepository {
  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> hapus(int id) async => 1;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async => const [];

  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;
}

class _FakePindaiRepository implements PindaiRepository {
  int sisaKuota = 8;
  Exception? errorToThrow;
  Completer<HasilPindaiEntity>? completer;

  @override
  Future<HasilPindaiEntity> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
    CancelToken? cancelToken,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    if (completer != null) {
      return completer!.future;
    }
    return const HasilPindaiEntity(adalahStruk: true, keyakinan: 0.9);
  }

  @override
  Future<int> ambilSisaKuota() async => sisaKuota;

  @override
  Future<void> potongKuota() async {
    if (sisaKuota > 0) sisaKuota--;
  }
}

void main() {
  late _FakeKategoriRepository fakeKatRepo;
  late _FakeTransaksiRepository fakeTransRepo;
  late _FakePindaiRepository fakePindaiRepo;
  late KategoriCubit kategoriCubit;
  late PindaiCubit pindaiCubit;
  late BerandaCubit berandaCubit;

  setUp(() {
    GetIt.instance.reset();
    fakeKatRepo = _FakeKategoriRepository();
    fakeTransRepo = _FakeTransaksiRepository();
    fakePindaiRepo = _FakePindaiRepository();

    kategoriCubit = KategoriCubit(ambilKategori: AmbilKategori(fakeKatRepo));
    pindaiCubit = PindaiCubit(
      pindaiStruk: PindaiStruk(fakePindaiRepo),
      ambilKuotaPindai: AmbilKuotaPindai(fakePindaiRepo),
      tambahTransaksi: TambahTransaksi(fakeTransRepo),
    );
    berandaCubit = BerandaCubit(
      ambilRingkasanPekan: AmbilRingkasanPekan(fakeTransRepo),
    );
  });

  tearDown(() {
    kategoriCubit.close();
    pindaiCubit.close();
    berandaCubit.close();
    GetIt.instance.reset();
  });

  Widget bangunAplikasiUji({
    Future<List<String>?> Function()? onScanDocument,
    Future<bool> Function()? onCheckConnection,
  }) {
    final router = GoRouter(
      initialLocation: '/pindai',
      routes: [
        GoRoute(
          path: '/pindai',
          builder: (context, state) => HalamanPindai(
            onScanDocument: onScanDocument,
            // Default selalu terhubung jika tidak dispesifikasikan agar tes UI tidak terhambat
            onCheckConnection: onCheckConnection ?? () async => true,
          ),
        ),
        GoRoute(
          path: '/catat',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Halaman Catat Manual'))),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<KategoriCubit>.value(value: kategoriCubit..muat()),
        BlocProvider<PindaiCubit>.value(value: pindaiCubit),
        BlocProvider<BerandaCubit>.value(value: berandaCubit),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  group('HalamanPindai', () {
    testWidgets('menampilkan panduan dan informasi sisa kuota', (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(bangunAplikasiUji());
      await tester.pumpAndSettle();

      expect(find.text('Pindai Struk'), findsOneWidget);
      expect(find.text('Kuota Pindai Pekan Ini'), findsOneWidget);
      expect(find.text('8 dari 10 tersisa'), findsOneWidget);
      expect(find.text('Panduan Pemindaian'), findsOneWidget);
      expect(find.text('Buka Pemindai Struk'), findsOneWidget);
    });

    testWidgets('pembatalan scanner oleh pengguna tidak mengubah kuota', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool scannerDibuka = false;

      await tester.pumpWidget(
        bangunAplikasiUji(
          onScanDocument: () async {
            scannerDibuka = true;
            return null; // Pengguna membatalkan scanner
          },
        ),
      );
      await tester.pumpAndSettle();

      final tombolScan = find.text('Buka Pemindai Struk');
      await tester.tap(tombolScan);
      await tester.pumpAndSettle();

      expect(scannerDibuka, isTrue);
      expect(pindaiCubit.state.status, PindaiStatus.awal);
      expect(pindaiCubit.state.sisaKuota, 8);
    });

    testWidgets(
      'No 3: pembatalan via PlatformException (tekan X) kembali diam-diam tanpa SnackBar galat',
      (tester) async {
        tester.view.physicalSize = const Size(460, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          bangunAplikasiUji(
            onScanDocument: () async {
              throw PlatformException(
                code: 'CANCELED',
                message: 'User canceled document scan',
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        final tombolScan = find.text('Buka Pemindai Struk');
        await tester.tap(tombolScan);
        await tester.pumpAndSettle();

        expect(find.text('Gagal membuka pemindai dokumen'), findsNothing);
        expect(pindaiCubit.state.status, PindaiStatus.awal);
        expect(pindaiCubit.state.sisaKuota, 8);
      },
    );

    testWidgets(
      'No 11: menampilkan tampilan memuat dan kalimat privasi tetap saat sedang menganalisis struk',
      (tester) async {
        tester.view.physicalSize = const Size(460, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePindaiRepo.completer = Completer<HasilPindaiEntity>();

        await tester.pumpWidget(bangunAplikasiUji());
        await tester.pumpAndSettle();

        final futurePindai = pindaiCubit.prosesPindai(
          imagePath: '/test/struk.png',
          daftarKategori: ['makan'],
        );
        await Future.microtask(() {});
        await tester.pump();

        expect(find.text('Menganalisis Struk dengan AI...'), findsOneWidget);
        // No 11: Verifikasi kalimat privasi tetap
        expect(
          find.text(
            'Foto struk dikirim ke layanan Google Gemini untuk dibaca. Insap tidak menyimpan fotonya.',
          ),
          findsOneWidget,
        );
        expect(find.text('Batalkan'), findsOneWidget);

        fakePindaiRepo.completer!.complete(
          const HasilPindaiEntity(adalahStruk: true, keyakinan: 0.9),
        );
        await futurePindai;
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'No 5 & No 38: menekan tombol Batalkan saat memuat membatalkan proses dan kembali ke status awal',
      (tester) async {
        tester.view.physicalSize = const Size(460, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePindaiRepo.completer = Completer<HasilPindaiEntity>();

        await tester.pumpWidget(bangunAplikasiUji());
        await tester.pumpAndSettle();

        unawaited(
          pindaiCubit.prosesPindai(
            imagePath: '/test/struk.png',
            daftarKategori: ['makan'],
          ),
        );
        await Future.microtask(() {});
        await tester.pump();

        expect(find.text('Batalkan'), findsOneWidget);
        await tester.tap(find.text('Batalkan'));
        await tester.pumpAndSettle();

        expect(pindaiCubit.state.status, PindaiStatus.awal);
        expect(pindaiCubit.state.sisaKuota, 8); // Kuota tidak berkurang
      },
    );

    testWidgets(
      'menampilkan galat dan tombol catat manual saat timeout 15 detik (No 6)',
      (tester) async {
        tester.view.physicalSize = const Size(460, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePindaiRepo.errorToThrow = const GeminiException(
          'Waktu tunggu pemindaian habis (melebihi 15 detik)',
          408,
        );

        await tester.pumpWidget(bangunAplikasiUji());
        await tester.pumpAndSettle();

        await pindaiCubit.prosesPindai(
          imagePath: '/test/struk.png',
          daftarKategori: ['makan'],
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Waktu tunggu pemindaian habis (melebihi 15 detik)'),
          findsOneWidget,
        );
        expect(find.text('Catat Manual Saja'), findsOneWidget);
        expect(find.text('Coba Pindai Ulang'), findsOneWidget);
      },
    );

    testWidgets(
      'No 12: kuota habis langsung menampilkan pemberitahuan dan navigasi ke /catat tanpa membuka pemindai',
      (tester) async {
        tester.view.physicalSize = const Size(460, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePindaiRepo.sisaKuota = 0;
        bool scannerDipanggil = false;

        await tester.pumpWidget(
          bangunAplikasiUji(
            onScanDocument: () async {
              scannerDipanggil = true;
              return null;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi teks kuota 0 dari 10 tersisa
        expect(find.text('0 dari 10 tersisa'), findsOneWidget);

        final tombolScan = find.text('Buka Pemindai Struk');
        await tester.tap(tombolScan);
        await tester.pumpAndSettle();

        expect(scannerDipanggil, isFalse);
        expect(find.text('Kuota pemindaian pekan ini sudah habis'), findsOneWidget);
        expect(find.text('Halaman Catat Manual'), findsOneWidget);
      },
    );

    testWidgets(
      'No 13: tidak ada koneksi internet sebelum pemindai dibuka langsung mengarahkan ke /catat dan kuota utuh',
      (tester) async {
        tester.view.physicalSize = const Size(460, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool scannerDipanggil = false;

        await tester.pumpWidget(
          bangunAplikasiUji(
            onCheckConnection: () async => false, // Simulasi offline / mode pesawat
            onScanDocument: () async {
              scannerDipanggil = true;
              return null;
            },
          ),
        );
        await tester.pumpAndSettle();

        final tombolScan = find.text('Buka Pemindai Struk');
        await tester.tap(tombolScan);
        await tester.pumpAndSettle();

        expect(scannerDipanggil, isFalse);
        expect(
          find.text('Tidak ada koneksi internet. Mengarahkan ke catat manual...'),
          findsOneWidget,
        );
        expect(find.text('Halaman Catat Manual'), findsOneWidget);
        expect(fakePindaiRepo.sisaKuota, 8); // Kuota tidak berkurang
      },
    );
  });
}
