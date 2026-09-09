import 'dart:async';

import 'package:flutter/services.dart';

class PaymentReturnSessionRegistry {
  PaymentReturnSessionRegistry._();

  static bool hostedCheckoutActive = false;
}

class PaymentReturnBridge {
  PaymentReturnBridge._();

  static const MethodChannel _channel =
      MethodChannel('kz.jetkiz.app/payment-return');

  static bool _started = false;
  static String? _lastUri;
  static DateTime? _lastHandledAt;

  static Future<void> start(
    Future<void> Function(Uri uri) onPaymentReturn,
  ) async {
    if (_started) return;
    _started = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'paymentReturn') return;
      final raw = call.arguments?.toString() ?? '';
      await _dispatch(raw, onPaymentReturn);
    });

    try {
      final initial =
          await _channel.invokeMethod<String>('getInitialPaymentReturn');
      await _dispatch(initial ?? '', onPaymentReturn);
    } on MissingPluginException {
      // Unsupported platforms/tests must continue without the native bridge.
    } on PlatformException {
      // A bridge error must never block normal application startup.
    }
  }

  static Future<void> _dispatch(
    String raw,
    Future<void> Function(Uri uri) onPaymentReturn,
  ) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !isPaymentReturnUri(uri)) return;

    final now = DateTime.now();
    if (_lastUri == uri.toString() &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 2)) {
      return;
    }

    _lastUri = uri.toString();
    _lastHandledAt = now;
    await onPaymentReturn(uri);
  }

  static bool isPaymentReturnUri(Uri uri) {
    return uri.scheme.toLowerCase() == 'jetkiz' &&
        uri.host.toLowerCase() == 'payment' &&
        uri.path == '/return';
  }
}
