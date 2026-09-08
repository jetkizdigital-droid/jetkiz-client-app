import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';

/// Provider-agnostic payment checkout contract.
///
/// Flutter talks only to the JETKIZ backend. PayLink credentials, provider
/// tokens, webhook data and card PAN/CVV must never be placed in the app.
class PaymentCheckoutApi {
  PaymentCheckoutApi(this._apiClient);

  final ApiClient _apiClient;

  Future<PaymentCheckoutSession> createCheckout({
    required String orderId,
    String? savedPaymentMethodId,
    bool saveCard = false,
  }) async {
    final normalizedOrderId = orderId.trim();
    final normalizedSavedMethodId = savedPaymentMethodId?.trim() ?? '';

    if (normalizedOrderId.isEmpty) {
      throw const PaymentCheckoutException(
        message: 'Некорректный заказ для оплаты',
      );
    }

    try {
      final response = await _apiClient.dio.post(
        '/payments',
        data: <String, dynamic>{
          'orderId': normalizedOrderId,
          if (normalizedSavedMethodId.isNotEmpty)
            'savedPaymentMethodId': normalizedSavedMethodId,
          if (normalizedSavedMethodId.isEmpty && saveCard) 'saveCard': true,
        },
      );

      if (response.data is! Map) {
        throw const FormatException('Invalid payment checkout payload');
      }

      return PaymentCheckoutSession.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on PaymentCheckoutException {
      rethrow;
    } on DioException catch (error) {
      throw PaymentCheckoutException(
        statusCode: error.response?.statusCode,
        message: _messageFor(error),
      );
    } catch (_) {
      throw const PaymentCheckoutException(
        message: 'Не удалось открыть оплату. Попробуйте ещё раз.',
      );
    }
  }

  Future<PaymentOrderState> getOrderPaymentState(String orderId) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      throw const PaymentCheckoutException(
        message: 'Некорректный заказ для проверки оплаты',
      );
    }

    try {
      final response = await _apiClient.dio.get(
        '/payments/orders/$normalizedOrderId',
      );
      if (response.data is! Map) {
        throw const FormatException('Invalid payment state payload');
      }

      return PaymentOrderState.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on PaymentCheckoutException {
      rethrow;
    } on DioException catch (error) {
      throw PaymentCheckoutException(
        statusCode: error.response?.statusCode,
        message: _messageFor(error),
      );
    } catch (_) {
      throw const PaymentCheckoutException(
        message: 'Не удалось проверить оплату. Проверьте интернет.',
      );
    }
  }

  static String _messageFor(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401) return 'Нужно снова войти в аккаунт';
    if (status == 404) return 'Заказ или платёж не найден';
    if (status == 409) {
      return 'Этот платёж уже обрабатывается. Проверьте его статус.';
    }
    if (status == 429) {
      return 'Слишком много попыток. Подождите немного и повторите.';
    }
    if (status != null && status >= 500) {
      return 'Платёжный сервис временно недоступен. Попробуйте позже.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Нет устойчивого соединения с сервером. Проверьте интернет.';
      case DioExceptionType.badCertificate:
        return 'Ошибка безопасного соединения';
      case DioExceptionType.cancel:
        return 'Запрос оплаты отменён';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return 'Не удалось выполнить операцию оплаты';
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
    this.tokenizationRequested = false,
    this.savedPaymentMethodId,
  });

  final String paymentId;
  final String orderId;
  final String status;
  final String checkoutUrl;
  final String? provider;
  final String? providerPaymentId;
  final int? amount;
  final String? currency;
  final bool tokenizationRequested;
  final String? savedPaymentMethodId;

  factory PaymentCheckoutSession.fromJson(Map<String, dynamic> json) {
    final paymentId = json['paymentId']?.toString().trim() ?? '';
    final orderId = json['orderId']?.toString().trim() ?? '';
    final status = json['status']?.toString().trim() ?? '';
    final checkoutUrl = json['checkoutUrl']?.toString().trim() ?? '';

    if (paymentId.isEmpty || orderId.isEmpty || status.isEmpty) {
      throw const FormatException('Invalid payment checkout payload');
    }

    return PaymentCheckoutSession(
      paymentId: paymentId,
      orderId: orderId,
      status: status,
      checkoutUrl: checkoutUrl,
      provider: _nullableString(json['provider']),
      providerPaymentId: _nullableString(json['providerPaymentId']),
      amount: _asInt(json['amount']),
      currency: _nullableString(json['currency']),
      tokenizationRequested: json['tokenizationRequested'] == true,
      savedPaymentMethodId: _nullableString(json['savedPaymentMethodId']),
    );
  }

  Uri? get secureCheckoutUri {
    final parsed = Uri.tryParse(checkoutUrl);
    if (parsed == null ||
        parsed.scheme.toLowerCase() != 'https' ||
        parsed.host.trim().isEmpty ||
        parsed.userInfo.isNotEmpty) {
      return null;
    }
    return parsed;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class PaymentOrderState {
  const PaymentOrderState({
    required this.orderId,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentRecordStatus,
    required this.fundsSecured,
    required this.captured,
    this.provider,
    this.providerPaymentId,
    this.checkoutUrl,
  });

  final String orderId;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentRecordStatus;
  final String? provider;
  final String? providerPaymentId;
  final String? checkoutUrl;
  final bool fundsSecured;
  final bool captured;

  factory PaymentOrderState.fromJson(Map<String, dynamic> json) {
    final orderId = json['orderId']?.toString().trim() ?? '';
    if (orderId.isEmpty) {
      throw const FormatException('Invalid payment state payload');
    }

    return PaymentOrderState(
      orderId: orderId,
      paymentMethod: json['paymentMethod']?.toString().trim() ?? '',
      paymentStatus: json['paymentStatus']?.toString().trim() ?? '',
      paymentRecordStatus: _nullableString(json['paymentRecordStatus']),
      provider: _nullableString(json['provider']),
      providerPaymentId: _nullableString(json['providerPaymentId']),
      checkoutUrl: _nullableString(json['checkoutUrl']),
      fundsSecured: json['fundsSecured'] == true,
      captured: json['captured'] == true,
    );
  }

  /// Defense in depth: a malformed/inconsistent backend response must never
  /// make Flutter treat a non-card or non-secured state as a successful order.
  bool get isSecuredCardPayment {
    final method = paymentMethod.toUpperCase();
    final status = paymentStatus.toUpperCase();
    return method == 'CARD' &&
        fundsSecured &&
        (status == 'AUTHORIZED' || status == 'PAID');
  }

  Uri? get secureCheckoutUri {
    final raw = checkoutUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    final parsed = Uri.tryParse(raw);
    if (parsed == null ||
        parsed.scheme.toLowerCase() != 'https' ||
        parsed.host.trim().isEmpty ||
        parsed.userInfo.isNotEmpty) {
      return null;
    }
    return parsed;
  }

  bool get isFailed {
    final status = paymentStatus.toUpperCase();
    final record = paymentRecordStatus?.toUpperCase();
    return status == 'FAILED' || record == 'FAILED' || record == 'CANCELED';
  }

  bool get isTerminalWithoutSuccess {
    final status = paymentStatus.toUpperCase();
    final record = paymentRecordStatus?.toUpperCase();
    return status == 'VOIDED' ||
        status == 'REFUNDED' ||
        record == 'VOIDED' ||
        record == 'REFUNDED';
  }
}

String? _nullableString(dynamic value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty || normalized.toLowerCase() == 'null'
      ? null
      : normalized;
}

class PaymentCheckoutException implements Exception {
  const PaymentCheckoutException({
    this.statusCode,
    this.message = 'Не удалось выполнить операцию оплаты',
  });

  final int? statusCode;
  final String message;
}
