import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jetkiz_mobile/core/navigation/appNavigator.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  developer.log(
    '[PUSH] background message received id=${message.messageId ?? '<none>'}',
    name: 'jetkiz.client.push',
  );
}

class PushNotificationService {
  PushNotificationService(this._apiClient);

  final ApiClient _apiClient;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const preferenceKey = 'jetkiz.notifications.enabled';

  static Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(preferenceKey) ?? true;
  }

  static Future<void> _setLocalEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(preferenceKey, value);
  }

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'jetkiz_default_channel',
    'JETKIZ уведомления',
    description: 'Уведомления приложения JETKIZ',
    importance: Importance.high,
  );

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  /// Initializes message handling and restores push registration for an
  /// already authenticated user. Permission is never requested before login.
  Future<bool> init() async {
    if (!await isEnabled()) {
      _log('local preference disabled; automatic registration skipped');
      return false;
    }

    await _initLocalNotifications();
    await _listenTokenRefresh();
    await _listenForegroundMessages();
    await _listenNotificationOpen();

    final accessToken = await _apiClient.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      _log('user is not authorized; permission request deferred until login');
      return true;
    }

    return registerCurrentToken(requestPermissionIfNeeded: true);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      final normalized = token?.trim();
      return normalized == null || normalized.isEmpty ? null : normalized;
    } catch (error) {
      _log('FCM getToken failed: ${_safeError(error)}');
      return null;
    }
  }

  /// Restores a token for an authenticated user. If registration succeeds,
  /// backend pushEnabled is synchronized to true so legacy server state cannot
  /// silently suppress a device that is enabled in the app.
  Future<bool> registerCurrentToken({
    bool requestPermissionIfNeeded = false,
  }) async {
    if (!await isEnabled()) {
      _log('registration skipped because local preference is disabled');
      return false;
    }

    final accessToken = await _apiClient.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      _log('registration skipped because user is not authorized');
      return false;
    }

    final permissionGranted = await _ensurePermission(
      requestIfNeeded: requestPermissionIfNeeded,
    );
    if (!permissionGranted) {
      _log(
        'registration skipped because notification permission is not granted',
      );
      return false;
    }

    final token = await getToken();
    if (token == null) {
      _log('registration failed because FCM token is empty');
      return false;
    }

    final registered = await _sendTokenToBackend(token);
    if (!registered) return false;

    final preferenceSynced = await _setBackendPushEnabled(true);
    if (!preferenceSynced) {
      _log('token registered but backend push preference sync failed');
      return false;
    }

    _log('client push ready ${_maskToken(token)}');
    return true;
  }

  /// Explicit user action from Settings. Local preference is only committed
  /// after OS permission, FCM token registration and backend preference sync
  /// all succeed.
  Future<bool> enableNotifications() async {
    final permissionGranted = await _ensurePermission(requestIfNeeded: true);
    if (!permissionGranted) {
      await _setLocalEnabled(false);
      return false;
    }

    final accessToken = await _apiClient.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      _log('enable failed because user is not authorized');
      return false;
    }

    final token = await getToken();
    if (token == null) {
      _log('enable failed because FCM token is empty');
      return false;
    }

    if (!await _sendTokenToBackend(token)) return false;
    if (!await _setBackendPushEnabled(true)) return false;

    await _setLocalEnabled(true);

    // Settings can enable notifications after startup when automatic init was
    // skipped because the local preference was false. Attach listeners now.
    await _initLocalNotifications();
    await _listenTokenRefresh();
    await _listenForegroundMessages();
    await _listenNotificationOpen();

    _log('notifications enabled ${_maskToken(token)}');
    return true;
  }

  Future<bool> disableNotifications() async {
    final accessToken = await _apiClient.getAccessToken();
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      if (!await _setBackendPushEnabled(false)) {
        _log('disable aborted because backend preference sync failed');
        return false;
      }
    }

    await unregisterCurrentToken();
    await _setLocalEnabled(false);
    _log('notifications disabled');
    return true;
  }

  Future<bool?> getBackendPushEnabled() async {
    final accessToken = await _apiClient.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) return null;

    try {
      final response = await _apiClient.dio.get('/client-settings/me');
      final root = _asMap(response.data);
      final settings = _asMap(root['settings']);
      final value = settings['pushEnabled'];
      return value is bool ? value : null;
    } catch (error) {
      _log('backend preference read failed: ${_safeError(error)}');
      return null;
    }
  }

  Future<void> unregisterCurrentToken() async {
    final token = await getToken();
    if (token == null) return;

    try {
      final deviceId = await _apiClient.getDeviceId();
      await _apiClient.dio.post(
        '/notification-devices/unregister',
        data: {
          'token': token,
          'deviceId': deviceId,
        },
      );
      _log('FCM token unregistered ${_maskToken(token)}');
    } catch (error) {
      _log('unregister failed: ${_safeError(error)}');
    }
  }

  Future<bool> _ensurePermission({required bool requestIfNeeded}) async {
    try {
      var settings = await _messaging.getNotificationSettings();
      _log('permission=${settings.authorizationStatus.name}');

      if (_isGranted(settings.authorizationStatus)) return true;

      if (settings.authorizationStatus == AuthorizationStatus.notDetermined &&
          requestIfNeeded) {
        settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        _log('permission after request=${settings.authorizationStatus.name}');
        return _isGranted(settings.authorizationStatus);
      }

      return false;
    } catch (error) {
      _log('permission check failed: ${_safeError(error)}');
      return false;
    }
  }

  bool _isGranted(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        unawaited(
          _handleLocalNotificationTap(
            response.payload,
            source: 'foreground_local_tap',
          ),
        );
      },
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_androidChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _listenTokenRefresh() async {
    await _tokenRefreshSubscription?.cancel();

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_handleTokenRefresh(token));
    });
  }

  Future<void> _handleTokenRefresh(String token) async {
    if (!await isEnabled()) return;
    if (!await _ensurePermission(requestIfNeeded: false)) return;

    final registered = await _sendTokenToBackend(token);
    if (registered) {
      await _setBackendPushEnabled(true);
    }
  }

  Future<bool> _sendTokenToBackend(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return false;

    try {
      final accessToken = await _apiClient.getAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) return false;

      final deviceId = await _apiClient.getDeviceId();

      final response = await _apiClient.dio.post(
        '/notification-devices/register',
        data: {
          'app': 'client',
          'token': normalized,
          'platform': _backendPlatformName(),
          'deviceId': deviceId,
          'appVersion': '1.0.0',
        },
      );

      final payload = _asMap(response.data);
      final success =
          payload['success'] == true || payload['deviceToken'] is Map;
      if (success) {
        _log('FCM token registered ${_maskToken(normalized)}');
      } else {
        _log('FCM registration response did not confirm success');
      }
      return success;
    } on DioException catch (error) {
      _log(
        'FCM register failed status=${error.response?.statusCode ?? 0} '
        'body=${_safeResponse(error.response?.data)}',
      );
      return false;
    } catch (error) {
      _log('FCM register failed: ${_safeError(error)}');
      return false;
    }
  }

  Future<bool> _setBackendPushEnabled(bool enabled) async {
    try {
      final response = await _apiClient.dio.patch(
        '/client-settings/me',
        data: {'pushEnabled': enabled},
      );
      final root = _asMap(response.data);
      final settings = _asMap(root['settings']);
      final serverValue = settings['pushEnabled'];
      final success = serverValue is bool ? serverValue == enabled : true;
      _log('backend pushEnabled=$enabled synced success=$success');
      return success;
    } on DioException catch (error) {
      _log(
        'backend pushEnabled=$enabled failed status=${error.response?.statusCode ?? 0} '
        'body=${_safeResponse(error.response?.data)}',
      );
      return false;
    } catch (error) {
      _log('backend pushEnabled=$enabled failed: ${_safeError(error)}');
      return false;
    }
  }

  Future<void> _listenForegroundMessages() async {
    await _foregroundSubscription?.cancel();

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundNotification(message));
    });
  }

  Future<void> _listenNotificationOpen() async {
    await _openedAppSubscription?.cancel();

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      unawaited(
        _handleNotificationOpen(
          initialMessage,
          source: 'terminated',
        ),
      );
    }

    _openedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(
        _handleNotificationOpen(
          message,
          source: 'background',
        ),
      );
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;

    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if ((title == null || title.trim().isEmpty) &&
        (body == null || body.trim().isEmpty)) {
      return;
    }

    final data = _normalizeData(message.data);

    await _localNotifications.show(
      message.hashCode,
      title ?? 'JETKIZ',
      body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  Future<void> _handleLocalNotificationTap(
    String? payload, {
    required String source,
  }) async {
    final data = _decodePayload(payload);

    if (data.isEmpty) {
      _log('empty local notification payload');
      return;
    }

    await _processOpenedNotificationData(data, source: source);
  }

  Future<void> _handleNotificationOpen(
    RemoteMessage message, {
    required String source,
  }) async {
    final data = _normalizeData(message.data);
    _log('opened source=$source dataKeys=${data.keys.join(',')}');
    await _processOpenedNotificationData(data, source: source);
  }

  Future<void> _processOpenedNotificationData(
    Map<String, String> data, {
    required String source,
  }) async {
    if (data.isEmpty) return;

    await Future.wait(
      [
        _safeTrackNotificationOpen(data, source: source),
        _safeMarkNotificationAsRead(data),
      ],
      eagerError: false,
    );

    await AppNavigator.handlePushData(data);
  }

  Future<void> _safeTrackNotificationOpen(
    Map<String, String> data, {
    required String source,
  }) async {
    try {
      final accessToken = await _apiClient.getAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        return;
      }

      await _apiClient.dio.post(
        '/client-events',
        data: {
          'eventName': 'notification_open',
          'metadata': {
            ...data,
            'source': source,
            'openedAt': DateTime.now().toIso8601String(),
          },
        },
      );
      _log('notification_open sent');
    } catch (error) {
      _log('notification_open failed: ${_safeError(error)}');
    }
  }

  Future<void> _safeMarkNotificationAsRead(Map<String, String> data) async {
    final notificationId = (data['notificationId'] ?? '').trim();

    if (notificationId.isEmpty) {
      return;
    }

    try {
      final accessToken = await _apiClient.getAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        return;
      }

      await _apiClient.dio.post('/notifications/$notificationId/read');
      _log('notification marked as read');
    } catch (error) {
      _log('mark notification read failed: ${_safeError(error)}');
    }
  }

  Map<String, String> _normalizeData(Map<dynamic, dynamic> rawData) {
    final normalized = <String, String>{};

    for (final entry in rawData.entries) {
      final key = entry.key.toString().trim();

      if (key.isEmpty) continue;

      final value = entry.value;

      if (value == null) continue;

      normalized[key] = value.toString();
    }

    return normalized;
  }

  Map<String, String> _decodePayload(String? payload) {
    final rawPayload = payload?.trim();

    if (rawPayload == null || rawPayload.isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(rawPayload);

      if (decoded is! Map) {
        return const {};
      }

      return _normalizeData(decoded);
    } catch (error) {
      _log('payload decode failed: ${_safeError(error)}');
      return const {};
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

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String _maskToken(String token) {
    if (token.length <= 12) return '***';
    return '${token.substring(0, 6)}...${token.substring(token.length - 6)}';
  }

  static String _safeError(Object error) {
    final text = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length <= 220 ? text : '${text.substring(0, 220)}…';
  }

  static String _safeResponse(dynamic value) {
    final text = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length <= 180 ? text : '${text.substring(0, 180)}…';
  }

  static void _log(String message) {
    developer.log('[PUSH] $message', name: 'jetkiz.client.push');
  }
}
