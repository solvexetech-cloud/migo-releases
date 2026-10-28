class CoinSettingsModel {
  final int claimReward;
  final int reviewReward;
  final int referralReward;
  final int signupReward;
  final int dailyLimit;
  final int monthlyLimit;
  final int expiryDays;
  final Map<String, double> countryRates; // ഉദാ: {'QA': 1.0, 'IN': 10.0}

  CoinSettingsModel({
    required this.claimReward,
    required this.reviewReward,
    required this.referralReward,
    required this.signupReward,
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.expiryDays,
    required this.countryRates,
  });

  factory CoinSettingsModel.fromMap(Map<String, dynamic> map) {
    final rewards = map['rewards'] as Map<String, dynamic>? ?? {};
    final caps = map['caps'] as Map<String, dynamic>? ?? {};
    final rawRates = map['countryRates'] as Map<String, dynamic>? ?? {};

    return CoinSettingsModel(
      claimReward: (rewards['claim'] as num?)?.toInt() ?? 10,
      reviewReward: (rewards['review'] as num?)?.toInt() ?? 5,
      referralReward: (rewards['referral'] as num?)?.toInt() ?? 50,
      signupReward: (rewards['signup'] as num?)?.toInt() ?? 20,
      dailyLimit: (caps['daily'] as num?)?.toInt() ?? 50,
      monthlyLimit: (caps['monthly'] as num?)?.toInt() ?? 500,
      expiryDays: (map['expiryDays'] as num?)?.toInt() ?? 60,
      countryRates: rawRates.map((key, value) => MapEntry(key, (value as num).toDouble())),
    );
  }

  // ഒരു നിശ്ചിത രാജ്യത്തിന് 100 കോയിന്റെ മൂല്യം എത്രയെന്ന് കണ്ടെത്താൻ
  double getValueFor100Coins(String countryCode) {
    return countryRates[countryCode] ?? 1.0; // ഡിഫോൾട്ട് ആയി 1.0
  }
}