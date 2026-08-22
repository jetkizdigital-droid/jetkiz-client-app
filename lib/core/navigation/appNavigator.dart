import 'dart:async';

import 'package:flutter/material.dart';

typedef PushNavigationHandler = Future<void> Function(
  Map<String, String> data,
);

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static PushNavigationHandler? _pushNavigationHandler;
  static final List<Map<String, String>> _pendingPushPayloads = [];

  static bool _flushScheduled = false;

  static void registerPushNavigationHandler(
    PushNavigationHandler handler,
  ) {
    _pushNavigationHandler = handler;
    _scheduleFlush();
  }

  static void clearPushNavigationHandler() {
    _pushNavigationHandler = null;
  }

  static Future<void> handlePushData(Map<String, String> data) async {
    if (data.isEmpty) return;

    _pendingPushPayloads.add(Map<String, String>.from(data));
    await _flushPendingPayloads();
  }

  static Future<void> _flushPendingPayloads() async {
    final handler = _pushNavigationHandler;
    final navigator = navigatorKey.currentState;

    if (handler == null || navigator == null) {
      _scheduleFlush();
      return;
    }

    while (_pendingPushPayloads.isNotEmpty) {
      final payload = _pendingPushPayloads.removeAt(0);
      await handler(payload);
    }
  }

  static void _scheduleFlush() {
    if (_flushScheduled || _pendingPushPayloads.isEmpty) return;

    _flushScheduled = true;

    Future<void>.delayed(const Duration(milliseconds: 300), () async {
      _flushScheduled = false;
      await _flushPendingPayloads();
    });
  }
}
