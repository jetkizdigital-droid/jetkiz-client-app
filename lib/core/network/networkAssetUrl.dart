import 'package:jetkiz_mobile/core/config/appConfig.dart';

String? normalizeNetworkAssetUrl(dynamic value) {
  final raw = value?.toString().trim() ?? '';

  if (raw.isEmpty || raw.toLowerCase() == 'null') {
    return null;
  }

  if (raw.startsWith('//')) {
    return 'https:$raw';
  }

  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return raw;
    }

    return null;
  }

  final baseUrl = AppConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');

  if (raw.startsWith('/')) {
    return '$baseUrl$raw';
  }

  return '$baseUrl/$raw';
}
