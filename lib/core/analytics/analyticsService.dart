import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';

class AnalyticsService {
  AnalyticsService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> trackScreenView({
    required String screen,
    String? title,
    String? source,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendEvent(
      eventName: 'screen_view',
      entityType: entityType ?? 'screen',
      entityId: entityId ?? screen,
      source: source,
      metadata: {
        'screen': screen,
        if (title != null) 'title': title,
        if (metadata != null) ...metadata,
      },
    );
  }

  Future<void> trackRestaurantView({
    required String restaurantId,
    String? restaurantName,
    String? source,
  }) async {
    await _sendEvent(
      eventName: 'restaurant_view',
      entityType: 'restaurant',
      entityId: restaurantId,
      source: source,
      metadata: {
        if (restaurantName != null) 'restaurantName': restaurantName,
      },
    );
  }

  Future<void> trackProductView({
    required String productId,
    String? productName,
    String? restaurantId,
    String? source,
  }) async {
    await _sendEvent(
      eventName: 'product_view',
      entityType: 'product',
      entityId: productId,
      source: source,
      metadata: {
        if (productName != null) 'productName': productName,
        if (restaurantId != null) 'restaurantId': restaurantId,
      },
    );
  }

  Future<void> trackSearchOpen({
    String source = 'unknown',
  }) async {
    await trackScreenView(
      screen: 'search',
      title: 'Поиск',
      source: source,
    );
  }

  Future<void> trackBannerShown({
    required String bannerId,
    String? title,
    String? source,
  }) async {
    await _sendEvent(
      eventName: 'banner_shown',
      entityType: 'banner',
      entityId: bannerId,
      source: source,
      metadata: {
        if (title != null) 'title': title,
      },
    );
  }

  Future<void> trackBannerClicked({
    required String bannerId,
    String? title,
    String? source,
  }) async {
    await _sendEvent(
      eventName: 'banner_clicked',
      entityType: 'banner',
      entityId: bannerId,
      source: source,
      metadata: {
        if (title != null) 'title': title,
      },
    );
  }

  Future<void> trackNotificationOpen({
    String? notificationId,
    String? orderId,
    int? orderNumber,
    String? source,
  }) async {
    await _sendEvent(
      eventName: 'notification_open',
      entityType: notificationId == null ? 'notification' : 'notification',
      entityId: notificationId,
      source: source,
      metadata: {
        if (orderId != null) 'orderId': orderId,
        if (orderNumber != null) 'orderNumber': orderNumber,
      },
    );
  }

  Future<void> _sendEvent({
    required String eventName,
    String? entityType,
    String? entityId,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final accessToken = await _apiClient.getAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        if (kDebugMode) {
          debugPrint('AnalyticsService: skip $eventName, user is not authorized');
        }
        return;
      }

      final deviceId = await _apiClient.getDeviceId();

      await _apiClient.dio.post(
        '/client-events',
        data: {
          'eventName': eventName,
          'deviceId': deviceId,
          'platform': _backendPlatformName(),
          'appVersion': '1.0.0',
          if (entityType != null) 'entityType': entityType,
          if (entityId != null) 'entityId': entityId,
          if (source != null) 'source': source,
          'metadata': {
            'deviceId': deviceId,
            'platform': _clientPlatformName(),
            'app': 'client',
            'appVersion': '1.0.0',
            'locale': 'ru',
            'timezone': 'Asia/Almaty',
            if (metadata != null) ...metadata,
          },
        },
      );
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'AnalyticsService: $eventName failed: ${error.response?.statusCode} ${error.response?.data}',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: $eventName failed: $error');
      }
    }
  }

  String _backendPlatformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'WEB';
    }
  }

  String _clientPlatformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}