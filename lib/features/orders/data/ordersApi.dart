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
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/orders',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final json = response.data ?? const <String, dynamic>{};
    return OrdersHistoryPageData.fromJson(json);
  }

  Future<OrderDetailsData> getOrderById(String orderId) async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/orders/$orderId',
    );

    final json = response.data ?? const <String, dynamic>{};
    return OrderDetailsData.fromJson(json);
  }
}