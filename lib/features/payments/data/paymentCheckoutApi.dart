import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';

/// Provider-agnostic payment checkout contract.
///
/// Flutter only talks to the JETKIZ backend. Provider credentials, webhook
/// secrets and card data must never be placed in the mobile application.
class PaymentCheckoutApi {
  PaymentCheckoutApi(this._apiClient);

  final ApiClient _apiClient;

  Future<PaymentCheckoutSession> createCheckout({
    required String orderId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/payments',
        data: {'orderId': orderId},
      );
      return PaymentCheckoutSession.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw PaymentCheckoutException(
        statusCode: error.response?.statusCode,
      );
    } catch (_) {
      throw const PaymentCheckoutException();
    }
  }
}

class PaymentCheckoutSession {
  const PaymentCheckoutSession({
    required this.paymentId,
    required this.orderId,
    required this.status,
    required this.checkoutUrl,
    this.provider,
    this.providerPaymentId,
    this.amount,
    this.currency,
  });

  final String paymentId;
  final String orderId;
  final String status;
  final String checkoutUrl;
  final String? provider;
  final String? providerPaymentId;
  final int? amount;
  final String? currency;

  factory PaymentCheckoutSession.fromJson(Map<String, dynamic> json) {
    return PaymentCheckoutSession(
      paymentId: json['paymentId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      checkoutUrl: json['checkoutUrl']?.toString() ?? '',
      provider: json['provider']?.toString(),
      providerPaymentId: json['providerPaymentId']?.toString(),
      amount: _asInt(json['amount']),
      currency: json['currency']?.toString(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class PaymentCheckoutException implements Exception {
  const PaymentCheckoutException({this.statusCode});

  final int? statusCode;
}
