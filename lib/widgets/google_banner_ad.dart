import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleBannerAd extends StatefulWidget {
  final String adType;
  final String? adUnitId;
  
  const GoogleBannerAd({
    super.key,
    this.adType = 'normal',
    this.adUnitId,
  });

  @override
  State<GoogleBannerAd> createState() => _GoogleBannerAdState();
}

class _GoogleBannerAdState extends State<GoogleBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    String targetAdUnitId;
    final AdSize adSize;
    final String adType = widget.adType;

    print('배너 광고 로드 시작 (Type: $adType)');

    if (Platform.isIOS) {
      print('iOS 플랫폼 감지됨. 테스트 광고 ID를 사용합니다. (Type: $adType)');
      targetAdUnitId = 'ca-app-pub-5031305118839759/8411193669'; 
      adSize = adType == 'large' ? AdSize.mediumRectangle : AdSize.banner;
    } else {
      print('iOS 외 플랫폼 감지됨. 라이브 광고 ID를 사용합니다. (Type: $adType)');
      targetAdUnitId = widget.adUnitId ?? 'ca-app-pub-5031305118839759/4468276310'; 
      adSize = adType == 'large' ? AdSize.mediumRectangle : AdSize.banner;
    }

    _bannerAd = BannerAd(
      adUnitId: targetAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('배너 광고 로드 성공 (Type: $adType, ID: $targetAdUnitId)');
          if (mounted) { 
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('배너 광고 로드 실패 (Type: $adType, ID: $targetAdUnitId): \x1B[31m${error.message}\x1B[0m');
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null || !_isAdLoaded) {
      return Container(
        height: widget.adType == 'large' ? 250 : 60,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('광고 로딩 중...', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
