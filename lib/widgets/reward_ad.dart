import 'package:google_mobile_ads/google_mobile_ads.dart';

typedef OnUserEarnedRewardCallback =
    void Function(RewardedAd ad, RewardItem reward);

class RewardAdManager {
  RewardedAd? _rewardedAd;
  Function? onRewardCallback; // Ödül fonksiyonu için bir callback

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId:
          'ca-app-pub-7637212047055272/8198529574', // 'ca-app-pub-3940256099942544/5224354917', // Test anahtarı
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  void showRewardedAd(Function onReward) {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          ad.dispose();
          loadRewardedAd(); // Yeni reklam yükle
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          ad.dispose();
          onReward();
        },
      );
      _rewardedAd?.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
          onReward();
        },
      );
    } else {
      print('Rewarded ad is not ready yet.');
    }
  }
}
