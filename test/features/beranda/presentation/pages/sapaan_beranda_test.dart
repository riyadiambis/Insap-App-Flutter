import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/theme.dart';
import 'package:insap/features/akun/domain/entities/pengguna_entity.dart';
import 'package:insap/features/beranda/presentation/cubit/beranda_cubit.dart';
import 'package:insap/features/beranda/presentation/pages/halaman_beranda.dart';
import 'package:insap/features/kategori/domain/entities/kategori_entity.dart';
import 'package:insap/features/kategori/domain/repositories/kategori_repository.dart';
import 'package:insap/features/kategori/domain/usecases/ambil_kategori.dart';
import 'package:insap/features/kategori/presentation/cubit/kategori_cubit.dart';
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
  ];
}

class _FakeTransaksiRepository implements TransaksiRepository {
  @override
  Future<List<TransaksiEntity>> ambilTerakhir(int batas) async => const [];

  @override
  Future<int> totalMingguIni(String a, String b) async => 0;

  @override
  Future<int> totalRentang(String a, String b) async => 0;

  @override
  Future<int> ambilKuotaPindai() async => 10;

  @override
  Future<List<TransaksiEntity>> ambilDaftar({
    String? tanggalMulai,
    String? tanggalAkhir,
    int? kategoriId,
  }) async => const [];

  @override
  Future<TransaksiEntity?> ambilSatu(int id) async => null;

  @override
  Future<int> simpan(TransaksiEntity transaksi) async => 1;

  @override
  Future<int> hapus(int id) async => 0;
}

Future<void> _muatFont(String keluarga, List<String> berkas) async {
  final loader = FontLoader(keluarga);
  for (final b in berkas) {
    loader.addFont(rootBundle.load('assets/fonts/$b'));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _muatFont('Nunito', [
      'Nunito-Regular.ttf',
      'Nunito-SemiBold.ttf',
      'Nunito-Bold.ttf',
      'Nunito-ExtraBold.ttf',
    ]);
    await _muatFont('Baloo2', [
      'Baloo2-SemiBold.ttf',
      'Baloo2-Bold.ttf',
      'Baloo2-ExtraBold.ttf',
    ]);
  });

  group('HalamanBeranda.ambilNamaDepan', () {
    test('mengembalikan Kawan bila namaTampilan null', () {
      expect(HalamanBeranda.ambilNamaDepan(null), 'Kawan');
    });

    test('mengembalikan Kawan bila namaTampilan kosong atau whitespace', () {
      expect(HalamanBeranda.ambilNamaDepan(''), 'Kawan');
      expect(HalamanBeranda.ambilNamaDepan('   '), 'Kawan');
    });

    test('mengambil kata pertama untuk nama tunggal maupun majemuk', () {
      expect(HalamanBeranda.ambilNamaDepan('Rahmat'), 'Rahmat');
      expect(HalamanBeranda.ambilNamaDepan('Rahmat Riyadi'), 'Rahmat');
      expect(HalamanBeranda.ambilNamaDepan('  Muhammad   Iqbal  '), 'Muhammad');
    });
  });

  group('Widget Sapaan Beranda', () {
    Widget buatApp(Widget child) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => KategoriCubit(
              ambilKategori: AmbilKategori(_FakeKategoriRepository()),
            )..muat(),
          ),
          BlocProvider(
            create: (_) => BerandaCubit(
              ambilRingkasanPekan: AmbilRingkasanPekan(
                _FakeTransaksiRepository(),
              ),
            )..muatRingkasan(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.lightTheme, home: child),
      );
    }

    testWidgets(
      'menyapa Halo, {nama depan}! jika login dan punya namaTampilan',
      (tester) async {
        tester.view.physicalSize = const Size(460, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const pengguna = PenggunaEntity(
          uid: 'uid-1',
          email: 'rahmat@example.com',
          namaTampilan: 'Rahmat Riyadi',
          fotoUrl: 'https://example.com/avatar.jpg',
        );

        await tester.pumpWidget(
          buatApp(const HalamanBeranda(penggunaAwal: pengguna)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Halo, Rahmat!'), findsOneWidget);
        expect(find.text('Halo, Kawan!'), findsNothing);
      },
    );

    testWidgets('menyapa Halo, Kawan! jika belum login', (tester) async {
      tester.view.physicalSize = const Size(460, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buatApp(const HalamanBeranda(penggunaAwal: null)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halo, Kawan!'), findsOneWidget);
    });

    testWidgets('menyapa Halo, Kawan! jika login tapi namaTampilan null', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(460, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const pengguna = PenggunaEntity(
        uid: 'uid-2',
        email: 'anon@example.com',
        namaTampilan: null,
      );

      await tester.pumpWidget(
        buatApp(const HalamanBeranda(penggunaAwal: pengguna)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halo, Kawan!'), findsOneWidget);
    });
  });
}
