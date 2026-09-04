import 'package:flutter/foundation.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/core/push/pushNotificationService.dart';

class AuthPostLoginService {
  AuthPostLoginService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> syncAfterLogin({
    String? pushToken,
  }) async {
    if (kDebugMode) {
      debugPrint('AuthPostLoginService: syncAfterLogin started');
    }

    await Future.wait(
      [
        _safeRegisterClientDevice(),
        _safeRegisterFcmToken(),
        _safeSendAppOpenEvent(),
      ],
      eagerError: false,
    );
  }

  Future<void> _safeRegisterClientDevice() async {
    try {
      final deviceId = await _apiClient.getDeviceId();

      await _apiClient.dio.post(
        '/client-sessions/devices',
        data: {
          'deviceId': deviceId,
          'platform': _backendPlatformName(),
          'appVersion': '1.0.0',
        },
      );

      if (kDebugMode) {
        debugPrint('AuthPostLoginService: client device registered');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AuthPostLoginService: device sync failed: $error');
      }
    }
  }

  Future<void> _safeRegisterFcmToken() async {
    try {
      final registered = await PushNotificationService(_apiClient)
          .registerCurrentToken(requestPermissionIfNeeded: true);

      if (kDebugMode) {
        debugPrint(
          'AuthPostLoginService: FCM token sync success=$registered',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AuthPostLoginService: FCM token sync failed: $error');
      }
    }
  }

  Future<void> _safeSendAppOpenEvent() async {
    try {
      final deviceId = await _apiClient.getDeviceId();

      await _apiClient.dio.post(
        '/client-events',
        data: {
          'eventName': 'app_open',
          'deviceId': deviceId,
          'platform': _backendPlatformName(),
          'appVersion': '1.0.0',
          'metadata': {
            'source': 'after_login',
            'deviceId': deviceId,
            'platform': _clientPlatformName(),
            'app': 'client',
            'appVersion': '1.0.0',
            'locale': 'ru',
            'timezone': 'Asia/Almaty',
          },
        },
      );

      if (kDebugMode) {
        debugPrint('AuthPostLoginService: app_open event sent');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AuthPostLoginService: app_open event failed: $error');
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
