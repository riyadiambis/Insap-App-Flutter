import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Kontrak layanan iklan rewarded dan persetujuan privasi (UMP) untuk Insap.
abstract class LayananIklan {
  /// Menyiapkan UMP consent dan menginisialisasi SDK iklan bila diizinkan.
  Future<void> siapkan();

  /// Apakah SDK sudah mendapat izin untuk meminta iklan.
  bool get bolehMintaIklan;

  /// Apakah tombol pengaturan opsi privasi iklan wajib ditampilkan di Akun.
  bool get perluTombolPrivasi;

  /// Notifier reaktif apakah tombol pengaturan opsi privasi iklan wajib ditampilkan.
  ValueListenable<bool> get perluTombolPrivasiListenable;

  /// Membuka formulir pengaturan opsi privasi iklan (UMP).
  Future<void> tampilkanOpsiPrivasi();

  /// Memuat dan menampilkan iklan rewarded bonus pindai struk.
  /// Mengembalikan `true` hanya jika pengguna menonton sampai mendapat hadiah.
  Future<bool> tontonIklanBonus();
}

/// Implementasi [LayananIklan] menggunakan Google Mobile Ads & UMP SDK.
class LayananIklanAdMob implements LayananIklan {
  static const String _idUnitRewardedRilis =
      'ca-app-pub-1696141223616686/2847831558';
  static const String _idUnitRewardedUji =
      'ca-app-pub-3940256099942544/5224354917';
  static const Duration _batasWaktuMuat = Duration(seconds: 15);
  static const Duration _batasWaktuTampil = Duration(minutes: 2);
  static const Duration _batasWaktuPersetujuan = Duration(seconds: 20);

  final ValueNotifier<bool> _perluTombolPrivasiNotifier =
      ValueNotifier<bool>(false);
  bool _bolehMintaIklan = false;
  bool _sdkSudahInisialisasi = false;
  bool _sedangMemintaIklan = false;
  Future<void>? _sedangMenyiapkan;

  String get _idUnitRewarded =>
      (kDebugMode || kProfileMode) ? _idUnitRewardedUji : _idUnitRewardedRilis;

  @override
  bool get bolehMintaIklan => _bolehMintaIklan;

  @override
  bool get perluTombolPrivasi => _perluTombolPrivasiNotifier.value;

  @override
  ValueListenable<bool> get perluTombolPrivasiListenable =>
      _perluTombolPrivasiNotifier;

  @override
  Future<void> siapkan() {
    return _sedangMenyiapkan ??= _lakukanSiapkan().whenComplete(() {
      _sedangMenyiapkan = null;
    });
  }

  Future<void> _lakukanSiapkan() async {
    try {
      await _perbaruiInfoPersetujuan();
      if (_bolehMintaIklan && !_sdkSudahInisialisasi) {
        await _inisialisasiSdkSekali();
      }
    } catch (e) {
      debugPrint('[LayananIklan] Galat saat menyiapkan iklan: $e');
    }
  }

  Future<void> _perbaruiInfoPersetujuan() async {
    final completer = Completer<void>();

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
              if (formError != null) {
                debugPrint(
                  '[LayananIklan] Galat formulir persetujuan: '
                  '${formError.errorCode} - ${formError.message}',
                );
              }
            });
          } catch (e) {
            debugPrint('[LayananIklan] Galat menampilkan formulir UMP: $e');
          } finally {
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        },
        (formError) {
          debugPrint(
            '[LayananIklan] Gagal memperbarui info persetujuan: '
            '${formError.errorCode} - ${formError.message}',
          );
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      await completer.future.timeout(
        _batasWaktuPersetujuan,
        onTimeout: () {
          debugPrint(
            '[LayananIklan] Batas waktu pembaruan info persetujuan 20 detik habis',
          );
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
    } catch (e) {
      debugPrint('[LayananIklan] Galat memperbarui info persetujuan: $e');
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    await _segarkanStatusPersetujuan();
  }

  Future<void> _segarkanStatusPersetujuan() async {
    try {
      _bolehMintaIklan = await ConsentInformation.instance.canRequestAds();
      final statusPrivasi = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      _perluTombolPrivasiNotifier.value =
          statusPrivasi == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('[LayananIklan] Galat membaca status UMP: $e');
    }
  }

  Future<void> _inisialisasiSdkSekali() async {
    if (_sdkSudahInisialisasi) return;
    try {
      await MobileAds.instance.initialize();
      _sdkSudahInisialisasi = true;
    } catch (e) {
      debugPrint('[LayananIklan] Gagal menginisialisasi MobileAds SDK: $e');
    }
  }

  @override
  Future<void> tampilkanOpsiPrivasi() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          debugPrint(
            '[LayananIklan] Galat formulir opsi privasi: '
            '${formError.errorCode} - ${formError.message}',
          );
        }
      });
      await _segarkanStatusPersetujuan();
      if (_bolehMintaIklan && !_sdkSudahInisialisasi) {
        await _inisialisasiSdkSekali();
      }
    } catch (e) {
      debugPrint('[LayananIklan] Galat membuka opsi privasi: $e');
    }
  }

  @override
  Future<bool> tontonIklanBonus() async {
    // Persiapan saat aplikasi dibuka bisa gagal (mis. tanpa internet): coba lagi sekali.
    if (!_bolehMintaIklan && !_sedangMemintaIklan) {
      await siapkan();
    }
    if (!_bolehMintaIklan || _sedangMemintaIklan) {
      return false;
    }

    _sedangMemintaIklan = true;
    RewardedAd? iklanDimuat;
    bool sudahDispose = false;

    Future<void> disposeAman(RewardedAd? target) async {
      if (target != null && !sudahDispose) {
        sudahDispose = true;
        try {
          await target.dispose();
        } catch (e) {
          debugPrint('[LayananIklan] Galat dispose iklan: $e');
        }
      }
    }

    try {
      if (!_sdkSudahInisialisasi) {
        await _inisialisasiSdkSekali();
        if (!_sdkSudahInisialisasi) {
          return false;
        }
      }

      final loadCompleter = Completer<RewardedAd?>();

      unawaited(
        RewardedAd.load(
          adUnitId: _idUnitRewarded,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              if (!loadCompleter.isCompleted) {
                loadCompleter.complete(ad);
              } else {
                unawaited(ad.dispose());
              }
            },
            onAdFailedToLoad: (error) {
              debugPrint(
                '[LayananIklan] Gagal memuat rewarded ad: '
                '${error.code} - ${error.message}',
              );
              if (!loadCompleter.isCompleted) {
                loadCompleter.complete(null);
              }
            },
          ),
        ).catchError((Object e) {
          debugPrint('[LayananIklan] Pengecualian saat memuat rewarded ad: $e');
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(null);
          }
        }),
      );

      iklanDimuat = await loadCompleter.future.timeout(
        _batasWaktuMuat,
        onTimeout: () {
          debugPrint('[LayananIklan] Batas waktu muat iklan 15 detik habis');
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(null);
          }
          return null;
        },
      );

      if (iklanDimuat == null) {
        return false;
      }

      bool dapatHadiah = false;
      final tampilCompleter = Completer<bool>();

      iklanDimuat.fullScreenContentCallback =
          FullScreenContentCallback<RewardedAd>(
        onAdDismissedFullScreenContent: (ad) async {
          await disposeAman(ad);
          if (!tampilCompleter.isCompleted) {
            tampilCompleter.complete(dapatHadiah);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) async {
          debugPrint(
            '[LayananIklan] Gagal menampilkan rewarded ad: '
            '${error.code} - ${error.message}',
          );
          await disposeAman(ad);
          if (!tampilCompleter.isCompleted) {
            tampilCompleter.complete(false);
          }
        },
      );

      await iklanDimuat.show(
        onUserEarnedReward: (ad, reward) {
          dapatHadiah = true;
        },
      );

      return await tampilCompleter.future.timeout(
        _batasWaktuTampil,
        onTimeout: () async {
          debugPrint(
            '[LayananIklan] Batas waktu tampil iklan 2 menit habis',
          );
          await disposeAman(iklanDimuat);
          if (!tampilCompleter.isCompleted) {
            tampilCompleter.complete(dapatHadiah);
          }
          return dapatHadiah;
        },
      );
    } catch (e) {
      debugPrint('[LayananIklan] Galat menjalankan iklan rewarded: $e');
      await disposeAman(iklanDimuat);
      return false;
    } finally {
      _sedangMemintaIklan = false;
    }
  }
}
