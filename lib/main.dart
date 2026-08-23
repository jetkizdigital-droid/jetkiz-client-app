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

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:jetkiz_mobile/app/app.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/core/push/pushNotificationService.dart';
import 'package:jetkiz_mobile/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  await apiClient.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationService(apiClient).init();
  } catch (error) {
    debugPrint('Push initialization skipped: $error');
  }

  runApp(const JetkizApp());
}
