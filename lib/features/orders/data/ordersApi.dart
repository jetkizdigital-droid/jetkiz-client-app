import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderDetailsData.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderHistoryItem.dart';

class OrdersApi {
  OrdersApi(this.apiClient);

  final ApiClient apiClient;

  /// Client orders list.
  ///
  /// Backend contract:
  /// GET /orders/my?page=1&limit=20
  ///
  /// Important:
  /// - Use /orders/my for Flutter client.
  /// - /orders also works for client, but /orders/my is clearer and safer.
  /// - List response is compact: full address/items are loaded through details.
  Future<OrdersHistoryPageData> getMyOrders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final safePage = page < 1 ? 1 : page;
      final safeLimit = limit < 1 ? 20 : limit;

      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/orders/my',
        queryParameters: {
          'page': safePage,
          'limit': safeLimit,
        },
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

  /// Full order details.
  ///
  /// Backend contract:
  /// GET /orders/:id
  Future<OrderDetailsData> getOrderById(String orderId) async {
    final normalizedOrderId = orderId.trim();

    if (normalizedOrderId.isEmpty) {
      throw const OrdersApiException(
        message: 'Некорректный ID заказа',
      );
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

    if (statusCode == 401) {
      return 'Нужно войти в аккаунт';
    }

    if (statusCode == 403) {
      return 'Нет доступа к заказу';
    }

    if (statusCode == 404) {
      return 'Заказ не найден';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'Ошибка сервера. Попробуйте позже';
    }

    return 'Не удалось загрузить заказы';
  }
}

class OrdersApiException implements Exception {
  const OrdersApiException({
    required this.message,
    this.statusCode,
    this.raw,
  });

  final String message;
  final int? statusCode;
  final dynamic raw;

  @override
  String toString() {
    return message;
  }
}
