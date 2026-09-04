/*
  JETKIZ MOBILE

  Новый Flutter-клиент Jetkiz создаётся с нуля.
  Старый мобильный код удалён и больше не используется.

  Backend:
  - локально на компьютере разработчика
  - базовый адрес для mobile: http://127.0.0.1:3000
  - Android устройство подключается через:
    adb reverse tcp:3000 tcp:3000

  Важно:
  - backend-first подход
  - нельзя придумывать endpoint и JSON
  - каждый экран строится только после проверки реального backend ответа
*/

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:jetkiz_mobile/app/app.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/core/push/pushNotificationService.dart';
import 'package:jetkiz_mobile/firebase_options.dart';

AppLifecycleListener? _pushLifecycleListener;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  await apiClient.init();

  var firebaseAvailable = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    firebaseAvailable = true;
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  if (firebaseAvailable) {
    try {
      await _configureCrashReporting();
    } catch (error, stackTrace) {
      // Crash reporting is optional infrastructure. It must never prevent FCM
      // token registration or normal application startup.
      debugPrint('Crashlytics initialization failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  runApp(const JetkizApp());

  if (firebaseAvailable) {
    // If the user grants notification permission from Android Settings while
    // the app is backgrounded, restore the token as soon as the app resumes.
    // This closes the gap where OS permission is ON but production DB still
    // has no active FCM token until a full app restart.
    _pushLifecycleListener = AppLifecycleListener(
      onResume: () {
        unawaited(_restorePushAfterResume(apiClient));
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize notification taps after Navigator exists and keep network
      // token registration off the critical startup path.
      unawaited(_initializePush(apiClient));
    });
  }
}

Future<void> _initializePush(ApiClient apiClient) async {
  try {
    await PushNotificationService(apiClient).init();
  } catch (error, stackTrace) {
    debugPrint('Push initialization failed: $error');
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

Future<void> _restorePushAfterResume(ApiClient apiClient) async {
  try {
    if (!await PushNotificationService.isEnabled()) return;

    await PushNotificationService(apiClient).registerCurrentToken(
      requestPermissionIfNeeded: false,
    );
  } catch (error, stackTrace) {
    debugPrint('Push resume registration failed: $error');
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

Future<void> _configureCrashReporting() async {
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);

  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    crashlytics.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}
