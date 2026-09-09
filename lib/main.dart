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
import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/app/app.dart';
import 'package:jetkiz_mobile/core/navigation/appNavigator.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/core/push/pushNotificationService.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentReturnBridge.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentReturnRecoveryPage.dart';
import 'package:jetkiz_mobile/firebase_options.dart';

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

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // The native bridge is intentionally independent from Firebase. PayLink
    // return-to-app must keep working even when push infrastructure is down.
    unawaited(PaymentReturnBridge.start(_handlePaymentReturn));

    if (firebaseAvailable) {
      // Initialize notification taps after Navigator exists and keep network
      // token registration off the critical startup path.
      unawaited(_initializePush(apiClient));
    }
  });

  if (firebaseAvailable) {
    // AppLifecycleListener registers itself with WidgetsBinding, which retains
    // the observer until dispose. Keeping a separate unused field is not
    // necessary. On resume, a permission granted from Android Settings can
    // therefore restore the production FCM token immediately.
    AppLifecycleListener(
      onResume: () {
        unawaited(_restorePushAfterResume(apiClient));
      },
    );
  }
}

Future<void> _handlePaymentReturn(Uri uri) async {
  // While the hosted checkout page is alive, its lifecycle observer performs
  // the authoritative backend check. Do not stack a second recovery route.
  if (PaymentReturnSessionRegistry.hostedCheckoutActive) return;

  NavigatorState? navigator;
  for (var attempt = 0; attempt < 10; attempt++) {
    navigator = AppNavigator.navigatorKey.currentState;
    if (navigator != null) break;
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  if (navigator == null) return;

  final providerResult = uri.queryParameters['result']?.trim();
  await navigator.push(
    MaterialPageRoute(
      builder: (_) => PaymentReturnRecoveryPage(
        providerResult: providerResult?.isEmpty == true ? null : providerResult,
      ),
    ),
  );
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
