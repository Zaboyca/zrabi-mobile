class ApiConfig {
  static const String origin = 'https://zrabi.by';
  static const String baseUrl = '$origin/api/v1';
  static const String deviceName = 'zrabi-mobile';
  static const String oauthCallbackScheme = 'zrabi';
  static const String homeHeroImageUrl = '$origin/images/hero-main.webp';
  // Same night skyline as web CTA (parallax) — National Library on the right.
  static const String homeMarketplaceCtaImageUrl =
      '$origin/images/home-marketplace-parallax.webp';
  static String socialRedirectUrl(String provider) {
    final q = Uri(queryParameters: {
      'client': 'mobile',
      'device_name': deviceName,
    }).query;
    return '$origin/auth/$provider/redirect?$q';
  }
}
