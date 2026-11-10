import 'api_config.dart';

/// Public legal pages on zrabi.by (same texts as the website).
abstract final class LegalUrls {
  static const privacy = '${ApiConfig.origin}/privacy';
  static const terms = '${ApiConfig.origin}/terms';
  static const rules = '${ApiConfig.origin}/rules';
  static const cookies = '${ApiConfig.origin}/cookies';
}
