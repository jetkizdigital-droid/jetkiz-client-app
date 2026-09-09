import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderDetailsData.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderHistoryItem.dart';

class OrdersApi {
  OrdersApi(this.apiClient);

  final ApiClient apiClient;

  Future<OrdersHistoryPageData> getMyOrders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final safePage = page < 1 ? 1 : page;
      final safeLimit = limit < 1 ? 20 : limit;

      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/orders/my',
        queryParameters: {'page': safePage, 'limit': safeLimit},
      );

      final json = response.data ?? const <String, dynamic>{};
      return OrdersHistoryPageData.fromJson(json);
    } on DioException catch (error) {
      throw OrdersApiException(
        message: _extractErrorMessage(error),
        statusCode: error.response?.statusCode,
        raw: error.response?.data,
      );
    }
  }

  Future<OrderDetailsData> getOrderById(String orderId) async {
    final normalizedOrderId = orderId.trim();

    if (normalizedOrderId.isEmpty) {
      throw const OrdersApiException(message: 'Некорректный ID заказа');
    }

    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/orders/$normalizedOrderId',
      );

      final json = response.data ?? const <String, dynamic>{};
      return OrderDetailsData.fromJson(json);
    } on DioException catch (error) {
      throw OrdersApiException(
        message: _extractErrorMessage(error),
        statusCode: error.response?.statusCode,
        raw: error.response?.data,
      );
    }
  }

  Future<OrderCancellationResult> cancelOrder(String orderId) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      throw const OrdersApiException(message: 'Некорректный ID заказа');
    }

    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/orders/$normalizedOrderId/cancel',
      );
      return OrderCancellationResult.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw OrdersApiException(
        message: _extractErrorMessage(error),
        statusCode: error.response?.statusCode,
        raw: error.response?.data,
      );
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final message = data['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      if (message is List && message.isNotEmpty) {
        return message.map((item) => item.toString()).join('\n');
      }

      final errorText = data['error'];
      if (errorText is String && errorText.trim().isNotEmpty) {
        return errorText.trim();
      }
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 401) return 'Нужно войти в аккаунт';
    if (statusCode == 403) return 'Нет доступа к заказу';
    if (statusCode == 404) return 'Заказ не найден';
    if (statusCode == 409) {
      return 'Заказ уже нельзя отменить. Обновите его статус.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Ошибка сервера. Попробуйте позже';
    }

    return 'Не удалось выполнить операцию с заказом';
  }
}

class OrderCancellationResult {
  const OrderCancellationResult({
    required this.canceled,
    required this.orderId,
    required this.refundStatus,
    this.orderNumber,
  });

  final bool canceled;
  final String orderId;
  final int? orderNumber;
  final String refundStatus;

  factory OrderCancellationResult.fromJson(Map<String, dynamic> json) {
    final orderId = json['orderId']?.toString().trim() ?? '';
    if (orderId.isEmpty || json['canceled'] != true) {
      throw const FormatException('Invalid cancellation response');
    }

    final rawNumber = json['orderNumber'];
    return OrderCancellationResult(
      canceled: true,
      orderId: orderId,
      orderNumber: rawNumber is num
          ? rawNumber.toInt()
          : int.tryParse(rawNumber?.toString() ?? ''),
      refundStatus: json['refundStatus']?.toString().trim() ?? 'PENDING',
    );
  }
}

class OrdersApiException implements Exception {
  const OrdersApiException({required this.message, this.statusCode, this.raw});

  final String message;
  final int? statusCode;
  final dynamic raw;

  @override
  String toString() => message;
}
