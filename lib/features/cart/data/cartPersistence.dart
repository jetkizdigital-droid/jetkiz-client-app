import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cartState.dart';

abstract class CartPersistence {
  Future<CartState?> load();

  Future<void> save(CartState state);

  Future<bool> loadPendingPriceUpdateNotification();

  Future<void> savePendingPriceUpdateNotification(bool value);

  Future<void> clear();
}

class SharedPreferencesCartPersistence implements CartPersistence {
  const SharedPreferencesCartPersistence();

  static const String _key = 'jetkiz.cart.state.v1';
  static const String _pendingPriceUpdateNotificationKey =
      'jetkiz.cart.pending_price_update_notification.v1';

  @override
  Future<CartState?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      return CartState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(CartState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(state.toJson()));
  }

  @override
  Future<bool> loadPendingPriceUpdateNotification() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_pendingPriceUpdateNotificationKey) ?? false;
  }

  @override
  Future<void> savePendingPriceUpdateNotification(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_pendingPriceUpdateNotificationKey, value);
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
    await preferences.remove(_pendingPriceUpdateNotificationKey);
  }
}
