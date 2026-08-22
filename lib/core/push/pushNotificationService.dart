import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jetkiz_mobile/core/navigation/appNavigator.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId}');
  }
}

class PushNotificationService {
  PushNotificationService(this._apiClient);

  final ApiClient _apiClient;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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

  Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _listenTokenRefresh();
    await _listenForegroundMessages();
    await _listenNotificationOpen();
    await registerCurrentToken();
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: getToken failed: $error');
      }
      return null;
    }
  }

  Future<void> registerCurrentToken() async {
    final accessToken = await _apiClient.getAccessToken();

    if (accessToken == null || accessToken.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'PushNotificationService: skip token registration, user is not authorized',
        );
      }
      return;
    }

    final token = await getToken();

    if (token == null || token.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: FCM token is empty');
      }
      return;
    }

    await _sendTokenToBackend(token);
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        debugPrint(
          'PushNotificationService: permission=${settings.authorizationStatus}',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: permission failed: $error');
      }
    }
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
      unawaited(_sendTokenToBackend(token));
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final accessToken = await _apiClient.getAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        return;
      }

      final deviceId = await _apiClient.getDeviceId();

      await _apiClient.dio.post(
        '/notification-devices/register',
        data: {
          'token': token.trim(),
          'platform': _backendPlatformName(),
          'deviceId': deviceId,
          'appVersion': '1.0.0',
        },
      );

      if (kDebugMode) {
        debugPrint('PushNotificationService: FCM token registered');
      }
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'PushNotificationService: register failed: ${error.response?.statusCode} ${error.response?.data}',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: register failed: $error');
      }
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
      if (kDebugMode) {
        debugPrint('PushNotificationService: empty local notification payload');
      }
      return;
    }

    await _processOpenedNotificationData(data, source: source);
  }

  Future<void> _handleNotificationOpen(
    RemoteMessage message, {
    required String source,
  }) async {
    final data = _normalizeData(message.data);

    if (kDebugMode) {
      debugPrint(
        'PushNotificationService: opened source=$source data=$data',
      );
    }

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

      if (kDebugMode) {
        debugPrint('PushNotificationService: notification_open sent');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'PushNotificationService: notification_open failed: $error',
        );
      }
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

      if (kDebugMode) {
        debugPrint(
          'PushNotificationService: notification marked as read $notificationId',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'PushNotificationService: mark notification read failed: $error',
        );
      }
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
      if (kDebugMode) {
        debugPrint('PushNotificationService: payload decode failed: $error');
      }
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
}