import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/notifications/domain/notificationItem.dart';

class NotificationsApi {
  NotificationsApi(this.apiClient);

  final ApiClient apiClient;

  Future<NotificationsPageData> getNotifications({
    int page = 1,
    int limit = 30,
  }) async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final json = response.data ?? const <String, dynamic>{};
    return NotificationsPageData.fromJson(json);
  }

  Future<void> markAsRead(String notificationId) async {
    await apiClient.dio.post(
      '/notifications/$notificationId/read',
    );
  }

  Future<void> markAllAsRead() async {
    await apiClient.dio.post(
      '/notifications/read-all',
    );
  }
}