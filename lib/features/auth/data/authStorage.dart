import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _deviceIdKey = 'deviceId';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<String?> readAccessToken() async {
    return getAccessToken();
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);

    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final deviceId = _generateDeviceId();
    await _storage.write(key: _deviceIdKey, value: deviceId);
    return deviceId;
  }

  Future<void> resetDeviceId() async {
    await _storage.delete(key: _deviceIdKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);

    final randomPart = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();

    return 'jetkiz-$timestamp-$randomPart';
  }
}