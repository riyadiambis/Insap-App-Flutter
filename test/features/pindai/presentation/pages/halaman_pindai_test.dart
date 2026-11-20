import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insap/core/iklan/layanan_iklan.dart';
import 'package:insap/core/network/gemini_client.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/langganan/presentation/pages/halaman_langganan.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
import 'package:insap/features/pindai/domain/entities/hasil_pindai_entity.dart';
import 'package:insap/features/pindai/domain/repositories/pindai_repository.dart';
import 'package:insap/features/pindai/domain/usecases/ambil_kuota_pindai.dart';
import 'package:insap/features/pindai/domain/usecases/ambil_sisa_bonus_iklan.dart';
import 'package:insap/features/pindai/domain/usecases/klaim_bonus_iklan.dart';
import 'package:insap/features/pindai/domain/usecases/pindai_struk.dart';
import 'package:insap/features/pindai/domain/usecases/simpan_transaksi_pindai.dart';
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

  @override
  Future<List<int>> simpanBanyak(List<TransaksiEntity> daftarTransaksi) async =>
      List.generate(daftarTransaksi.length, (i) => i + 1);
}

class _FakePindaiRepository implements PindaiRepository {
  int sisaKuota = 8;
  int sisaBonus = 10;
  Exception? errorToThrow;
  Completer<HasilPindaiEntity>? completer;

  @override
  Future<HasilPindaiEntity> pindaiStruk({
    required String imagePath,
    required List<String> daftarKategori,
    Map<String, int>? petaKategoriId,
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

  @override
  Future<int> ambilSisaBonusIklan() async => sisaBonus;

  @override
  Future<bool> klaimBonusIklan() async {
    if (sisaBonus <= 0) return false;
    sisaBonus--;
    sisaKuota++;
    return true;
  }
}

class _FakeLayananIklan implements LayananIklan {
  bool hasilTonton = true;
  Completer<bool>? completer;
  int jumlahDipanggil = 0;
  final ValueNotifier<bool> _perluTombolPrivasi = ValueNotifier<bool>(false);

  @override
  bool get bolehMintaIklan => true;

  @override
  bool get perluTombolPrivasi => _perluTombolPrivasi.value;

  @override
  ValueListenable<bool> get perluTombolPrivasiListenable => _perluTombolPrivasi;

  @override
  Future<void> siapkan() async {}

  @override
  Future<void> tampilkanOpsiPrivasi() async {}

  @override
  Future<bool> tontonIklanBonus() async {
    jumlahDipanggil++;
    if (completer != null) {
      return completer!.future;
    }
    return hasilTonton;
  }
}

void main() {
  late _FakeKategoriRepository fakeKatRepo;
  late _FakeTransaksiRepository fakeTransRepo;
  late _FakePindaiRepository fakePindaiRepo;
  late _FakeLayananIklan fakeLayananIklan;
  late KategoriCubit kategoriCubit;
  late PindaiCubit pindaiCubit;
  late BerandaCubit berandaCubit;

  setUp(() async {
    await GetIt.instance.reset();
    fakeKatRepo = _FakeKategoriRepository();
    fakeTransRepo = _FakeTransaksiRepository();
    fakePindaiRepo = _FakePindaiRepository();
    fakeLayananIklan = _FakeLayananIklan();

    GetIt.instance.registerSingleton<SimpanTransaksiPindai>(
      SimpanTransaksiPindai(fakeTransRepo),
    );

    kategoriCubit = KategoriCubit(ambilKategori: AmbilKategori(fakeKatRepo));
    pindaiCubit = PindaiCubit(
      pindaiStruk: PindaiStruk(fakePindaiRepo),
      ambilKuotaPindai: AmbilKuotaPindai(fakePindaiRepo),
      tambahTransaksi: TambahTransaksi(fakeTransRepo),
      ambilSisaBonusIklan: AmbilSisaBonusIklan(fakePindaiRepo),
      klaimBonusIklanUseCase: KlaimBonusIklan(fakePindaiRepo),
      layananIklan: fakeLayananIklan,
    );
    berandaCubit = BerandaCubit(
      ambilRingkasanPekan: AmbilRingkasanPekan(fakeTransRepo),
    );
  });

  tearDown(() async {
    kategoriCubit.close();
    pindaiCubit.close();
    berandaCubit.close();
    await GetIt.instance.reset();
  });

  Widget bangunAplikasiUji({
    bool mulaiLangsung = false,
    Future<List<String>?> Function()? onScanDocument,
    Future<bool> Function()? onCheckConnection,
    bool Function()? onCheckApiKey,
  }) {
    final router = GoRouter(
      initialLocation: '/pindai',
      routes: [
        GoRoute(
          path: '/pindai',
          builder: (context, state) => HalamanPindai(
            mulaiLangsung: mulaiLangsung,
            onScanDocument: onScanDocument,
            // Default selalu terhubung jika tidak dispesifikasikan agar tes UI tidak terhambat
            onCheckConnection: onCheckConnection ?? () async => true,
            onCheckApiKey: onCheckApiKey ?? () => true,
          ),
        ),
        GoRoute(
          path: '/catat',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Halaman Catat Manual'))),
        ),
        GoRoute(
          path: '/langganan',
          builder: (context, state) => const HalamanLangganan(),
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
    testWidgets('menampilkan tombol panduan dan informasi sisa kuota', (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(bangunAplikasiUji());
      await tester.pumpAndSettle();

      expect(find.text('Pindai Struk'), findsOneWidget);
      expect(find.text('Kuota Pindai Pekan Ini'), findsOneWidget);
      expect(find.text('8 dari 5 tersisa'), findsOneWidget);
      expect(find.text('Lihat panduan'), findsOneWidget);
      expect(find.text('Buka Pemindai Struk'), findsOneWidget);
    });

    testWidgets('No 33: Kunci Gemini kosong menampilkan snackbar dan arahkan ke catat', (tester) async {
      tester.view.physicalSize = const Size(460, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        bangunAplikasiUji(
          onCheckApiKey: () => false,
        ),
      );
      await tester.pumpAndSettle();

      final tombolScan = find.text('Buka Pemindai Struk');
      await tester.tap(tombolScan);
      await tester.pumpAndSettle();

      expect(find.text('Pindai struk belum aktif di versi ini'), findsOneWidget);
      expect(find.text('Halaman Catat Manual'), findsOneWidget);
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
      'K2 (ISSUE-32): teks di layar memuat berubah bertahap pada detik ke-15 dan ke-45, kalimat privasi dan batalkan tetap tampil',
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

        // Sebelum 15 detik: teks awal
        expect(find.text('Menganalisis Struk dengan AI...'), findsOneWidget);
        expect(
          find.text(
            'Foto struk dikirim ke layanan Google Gemini untuk dibaca. Insap tidak menyimpan fotonya.',
          ),
          findsOneWidget,
        );
        expect(find.text('Batalkan'), findsOneWidget);

        // Sesudah 15 detik: teks kedua
        await tester.pump(const Duration(seconds: 15));
        expect(
          find.text('Struknya agak panjang, masih dibaca...'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Foto struk dikirim ke layanan Google Gemini untuk dibaca. Insap tidak menyimpan fotonya.',
          ),
          findsOneWidget,
        );
        expect(find.text('Batalkan'), findsOneWidget);

        // Sesudah 45 detik: teks ketiga
        await tester.pump(const Duration(seconds: 30));
        expect(
          find.text(
            'Masih menunggu jawaban. Kalau terlalu lama, ketuk Batalkan lalu catat manual.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Foto struk dikirim ke layanan Google Gemini untuk dibaca. Insap tidak menyimpan fotonya.',
          ),
          findsOneWidget,
        );
        expect(find.text('Batalkan'), findsOneWidget);

        // Mengetuk Batalkan tetap berfungsi dan membatalkan proses
        await tester.tap(find.text('Batalkan'));
        await tester.pumpAndSettle();

        expect(pindaiCubit.state.status, PindaiStatus.awal);
        expect(pindaiCubit.state.sisaKuota, 8);
      },
    );

    testWidgets(
      'menampilkan galat dan tombol catat manual saat timeout 90 detik (No 6)',
      (tester) async {
        tester.view.physicalSize = const Size(460, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePindaiRepo.errorToThrow = const GeminiException(
          'Waktu tunggu pemindaian habis (melebihi 90 detik)',
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
          find.text('Waktu tunggu pemindaian habis (melebihi 90 detik)'),
          findsOneWidget,
        );
        expect(find.text('Catat Manual Saja'), findsOneWidget);
        expect(find.text('Coba Pindai Ulang'), findsOneWidget);
      },
    );

    testWidgets(
      'No 12: kuota habis menampilkan tampilan kuota habis, kartu langganan, dan tombol catat manual tanpa membuka pemindai',
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

        expect(find.text('Jatah pindai pekan ini habis'), findsOneWidget);
        expect(find.text('Butuh lebih banyak?'), findsOneWidget);
        expect(
          find.text('Plus 50 pindai, Pro 100 pindai per pekan'),
          findsOneWidget,
        );
        expect(find.text('Buka Pemindai Struk'), findsNothing);
        expect(scannerDipanggil, isFalse);

        // Ketuk kartu langganan membuka /langganan
        await tester.tap(find.text('Butuh lebih banyak?'));
        await tester.pumpAndSettle();
        expect(find.byType(HalamanLangganan), findsOneWidget);
        expect(find.text('Pilih paket Insap'), findsOneWidget);
        expect(find.text('Rp29 rb'), findsOneWidget);
        expect(
          find.text(
            'Pembayaran langganan belum aktif. Kami kabari begitu siap.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Tanya Struki'), findsNothing);

        // Ketuk kartu Gratis: CTA menjadi status nonaktif dan tidak membuka dialog
        await tester.ensureVisible(
          find.byKey(const Key('kartu_paket_gratis')),
        );
        await tester.tap(find.byKey(const Key('kartu_paket_gratis')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('tombol_langganan_cta')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dialog_fitur_dikembangkan')), findsNothing);

        // Pilih Pro lalu ketuk CTA: membuka dialog "Langganan sedang disiapkan"
        await tester.ensureVisible(find.byKey(const Key('kartu_paket_pro')));
        await tester.tap(find.byKey(const Key('kartu_paket_pro')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('tombol_langganan_cta')));
        await tester.pumpAndSettle();
        expect(find.text('Langganan sedang disiapkan'), findsOneWidget);
        await tester.tap(
          find.byKey(const Key('tombol_tutup_dialog_dikembangkan')),
        );
        await tester.pumpAndSettle();

        // Kembali ke halaman Pindai lalu ketuk Catat manual mengarahkan ke /catat
        Navigator.of(tester.element(find.byType(HalamanLangganan))).pop();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Catat manual'));
        await tester.pumpAndSettle();
        expect(find.text('Halaman Catat Manual'), findsOneWidget);
      },
    );

    testWidgets(
      'kuota habis dengan mulaiLangsung true tetap menampilkan tampilan kuota habis tanpa pindah ke /catat',
      (tester) async {
        tester.view.physicalSize = const Size(460, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePindaiRepo.sisaKuota = 0;
        bool scannerDipanggil = false;

        await tester.pumpWidget(
          bangunAplikasiUji(
            mulaiLangsung: true,
            onScanDocument: () async {
              scannerDipanggil = true;
              return null;
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jatah pindai pekan ini habis'), findsOneWidget);
        expect(find.text('Halaman Catat Manual'), findsNothing);
        expect(scannerDipanggil, isFalse);
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

    testWidgets(
      'ISSUE-40: tampilan kuota habis menampilkan tombol iklan bonus dan sisa bonus pekan ini',
      (tester) async {
        tester.view.physicalSize = const Size(411, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePindaiRepo.sisaKuota = 0;
        fakePindaiRepo.sisaBonus = 7;

        await tester.pumpWidget(bangunAplikasiUji());
        await tester.pumpAndSettle();

        final tombolBonus = find.byKey(const Key('tombol_bonus_iklan'));
        expect(tombolBonus, findsOneWidget);
        expect(find.text('Tonton iklan, dapat +1 pindai'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.text('Sisa bonus pekan ini: 7 dari 10'), findsOneWidget);
        expect(tester.getSize(tombolBonus).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ISSUE-40: tombol bonus nonaktif dengan teks habis saat sisaBonusIklan 0',
      (tester) async {
        tester.view.physicalSize = const Size(411, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePindaiRepo.sisaKuota = 0;
        fakePindaiRepo.sisaBonus = 0;

        await tester.pumpWidget(bangunAplikasiUji());
        await tester.pumpAndSettle();

        expect(find.text('Bonus iklan pekan ini sudah habis'), findsOneWidget);
        expect(find.text('Sisa bonus pekan ini: 0 dari 10'), findsOneWidget);

        await tester.tap(find.byKey(const Key('tombol_bonus_iklan')));
        await tester.pumpAndSettle();
        expect(fakeLayananIklan.jumlahDipanggil, 0);
      },
    );

    testWidgets(
      'ISSUE-40: menonton iklan berhasil menampilkan SnackBar Yay dan kembali ke siap pindai',
      (tester) async {
        tester.view.physicalSize = const Size(411, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePindaiRepo.sisaKuota = 0;
        fakePindaiRepo.sisaBonus = 10;
        fakeLayananIklan.hasilTonton = true;

        await tester.pumpWidget(bangunAplikasiUji());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('tombol_bonus_iklan')));
        await tester.pumpAndSettle();

        expect(find.text('Yay, +1 pindai!'), findsOneWidget);
        expect(find.text('Buka Pemindai Struk'), findsOneWidget);
        expect(pindaiCubit.state.sisaKuota, 1);
      },
    );

    testWidgets(
      'ISSUE-40: iklan gagal atau ditutup sebelum selesai menampilkan SnackBar galat dan kuota tetap 0',
      (tester) async {
        tester.view.physicalSize = const Size(411, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePindaiRepo.sisaKuota = 0;
        fakePindaiRepo.sisaBonus = 10;
        fakeLayananIklan.completer = Completer<bool>();

        await tester.pumpWidget(bangunAplikasiUji());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('tombol_bonus_iklan')));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        fakeLayananIklan.completer!.complete(false);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Iklan belum tersedia atau belum selesai ditonton. Coba lagi sebentar lagi.',
          ),
          findsOneWidget,
        );
        expect(find.text('Jatah pindai pekan ini habis'), findsOneWidget);
        expect(pindaiCubit.state.sisaKuota, 0);
      },
    );
  });
}
