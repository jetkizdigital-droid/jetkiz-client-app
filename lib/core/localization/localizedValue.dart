import 'package:jetkiz_mobile/core/localization/appLanguage.dart';

/// Central selector for dynamic RU/KK values received from backend.
///
/// Static UI strings continue to use AppStrings/LocalizedText. This helper is
/// only for data that already has separate language fields such as titleRu and
/// titleKk. Russian is the product default and is also the safe fallback when a
/// Kazakh value is missing.
class LocalizedValue {
  LocalizedValue._();

  static AppLanguage _language = AppLanguage.ru;

  static AppLanguage get language => _language;

  static void setLanguage(AppLanguage language) {
    _language = language;
  }

  static String select({
    String? ru,
    String? kk,
    String fallback = '',
  }) {
    final ruValue = _normalize(ru);
    final kkValue = _normalize(kk);

    if (_language == AppLanguage.kk) {
      if (kkValue.isNotEmpty) return kkValue;
      if (ruValue.isNotEmpty) return ruValue;
    } else {
      if (ruValue.isNotEmpty) return ruValue;
      if (kkValue.isNotEmpty) return kkValue;
    }

    return fallback;
  }

  static String _normalize(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') {
      return '';
    }
    return normalized;
  }
}
