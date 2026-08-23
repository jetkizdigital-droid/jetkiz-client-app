/*
  Центральная конфигурация приложения Jetkiz.

  Важно для будущих сессий:
  - разработка идёт на физическом Android устройстве
  - не использовать адрес эмулятора 10.0.2.2
  - backend доступен через adb reverse и 127.0.0.1:3000
*/

class AppConfig {
  static const String appName = 'Jetkiz';
  static const String productionBaseUrl = 'https://api.jetkiz.asia';
  static const String _definedBaseUrl = String.fromEnvironment(
    'JETKIZ_API_BASE_URL',
    defaultValue: productionBaseUrl,
  );
  static const bool _isReleaseBuild = bool.fromEnvironment('dart.vm.product');
  static const String supportWhatsAppNumber = String.fromEnvironment(
    'JETKIZ_SUPPORT_WHATSAPP',
    defaultValue: '',
  );

  static String get baseUrl {
    final normalized = _definedBaseUrl.trim();

    if (_isReleaseBuild && _isUnsafeReleaseBaseUrl(normalized)) {
      throw StateError(
        'Release build cannot use insecure or local JETKIZ_API_BASE_URL: '
        '$normalized',
      );
    }

    return normalized;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static bool _isUnsafeReleaseBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    final host = uri?.host.toLowerCase() ?? '';

    return uri == null ||
        uri.scheme != 'https' ||
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '10.0.2.2' ||
        host.endsWith('.local');
  }
}
