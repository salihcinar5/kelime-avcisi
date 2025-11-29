import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      // Test reklam ID'si
      adUnitId:
          'ca-app-pub-7637212047055272/6680152512', //'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner reklam yüklendi');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner reklam yüklenemedi: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    // Windows'ta placeholder göster
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: const Center(
          child: Text('Reklam alanı (sadece mobil cihazlarda görünür)'),
        ),
      );
    }

    return Container(
      height: 60,
      color: Colors.grey[200],
      width: double.infinity,
      child:
          _isLoaded && _bannerAd != null
              ? AdWidget(ad: _bannerAd!)
              : const Center(child: Text('Reklam yükleniyor...')),
    );
  }
}
