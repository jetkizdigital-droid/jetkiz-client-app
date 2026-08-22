import 'package:jetkiz_mobile/core/network/apiClient.dart';

class FinanceConfigApi {
  FinanceConfigApi(this._apiClient);

  final ApiClient _apiClient;

  Future<FinanceConfigData> getFinanceConfig() async {
    final response = await _apiClient.dio.get(
      '/restaurants/public/finance-config',
    );

    final rawData = response.data;

    final data = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};

    return FinanceConfigData.fromJson(data);
  }
}

class FinanceConfigData {
  const FinanceConfigData({
    required this.currency,
    required this.deliveryFee,
    required this.deliveryBaseFee,
    required this.baseDeliveryFee,
    required this.freeDeliveryThreshold,
    required this.minOrderAmount,

    /// Backward-compatible fields for existing Flutter UI.
    required this.clientDeliveryFeeDefault,
    required this.clientDeliveryFeeWeather,
    required this.courierPayoutDefault,
    required this.courierPayoutWeather,
    required this.weatherEnabled,
  });

  /// Public client contract.
  final String currency;
  final int deliveryFee;
  final int deliveryBaseFee;
  final int baseDeliveryFee;
  final int? freeDeliveryThreshold;
  final int? minOrderAmount;

  /// Legacy fields kept so existing UI does not break.
  final int clientDeliveryFeeDefault;
  final int clientDeliveryFeeWeather;
  final int courierPayoutDefault;
  final int courierPayoutWeather;
  final bool weatherEnabled;

  int get activeDeliveryFee => deliveryFee;

  bool get hasDeliveryFee => deliveryFee > 0;

  String get formattedDeliveryFee {
    if (deliveryFee <= 0) {
      return 'Бесплатно';
    }

    return '$deliveryFee ₸';
  }

  factory FinanceConfigData.fromJson(Map<String, dynamic> json) {
    final deliveryFee = _asInt(
      json['deliveryFee'] ??
          json['clientDeliveryFeeWeather'] ??
          json['clientDeliveryFeeDefault'],
    );

    final deliveryBaseFee = _asInt(
      json['deliveryBaseFee'] ??
          json['clientDeliveryFeeWeather'] ??
          json['clientDeliveryFeeDefault'] ??
          deliveryFee,
    );

    final baseDeliveryFee = _asInt(
      json['baseDeliveryFee'] ??
          json['clientDeliveryFeeDefault'] ??
          json['deliveryBaseFee'] ??
          deliveryFee,
    );

    final clientDeliveryFeeDefault = _asInt(
      json['clientDeliveryFeeDefault'] ?? baseDeliveryFee,
    );

    final clientDeliveryFeeWeather = _asInt(
      json['clientDeliveryFeeWeather'] ?? deliveryFee,
    );

    return FinanceConfigData(
      currency: _asString(json['currency'], fallback: 'KZT'),
      deliveryFee: deliveryFee,
      deliveryBaseFee: deliveryBaseFee,
      baseDeliveryFee: baseDeliveryFee,
      freeDeliveryThreshold: _asNullableInt(json['freeDeliveryThreshold']),
      minOrderAmount: _asNullableInt(json['minOrderAmount']),

      /// Backward-compatible values.
      clientDeliveryFeeDefault: clientDeliveryFeeDefault,
      clientDeliveryFeeWeather: clientDeliveryFeeWeather,
      courierPayoutDefault: _asInt(json['courierPayoutDefault']),
      courierPayoutWeather: _asInt(json['courierPayoutWeather']),
      weatherEnabled: json['weatherEnabled'] == true,
    );
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();

    final text = value.toString().trim();
    if (text.isEmpty) return 0;

    return int.tryParse(text) ?? double.tryParse(text)?.round() ?? 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return int.tryParse(text) ?? double.tryParse(text)?.round();
  }

  static String _asString(dynamic value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
