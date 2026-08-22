import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jetkiz_mobile/core/config/appConfig.dart';

class SupportLauncher {
  const SupportLauncher._();

  static Future<void> openWhatsApp(BuildContext context) async {
    final number = AppConfig.supportWhatsAppNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (number.isEmpty) {
      _showMessage(context, 'Номер WhatsApp поддержки скоро будет добавлен');
      return;
    }

    final uri = Uri.https('wa.me', '/$number', {
      'text': 'Здравствуйте! Нужна помощь в приложении JETKIZ.',
    });

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showMessage(context, 'Не удалось открыть WhatsApp');
    }
  }

  static void _showMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
