import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/features/auth/data/authStorage.dart';
import 'package:jetkiz_mobile/features/auth/data/authSessionController.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _applyBaseHeaders(options);

          final skipRefresh = options.headers['x-skip-auth-refresh'] == 'true';

          if (skipRefresh) {
            options.headers.remove('Authorization');
          } else {
            final token = _accessToken ?? await _authStorage.getAccessToken();

            if (token != null && token.trim().isNotEmpty) {
              options.headers['Authorization'] = 'Bearer ${token.trim()}';
            } else {
              options.headers.remove('Authorization');
            }
          }

          if (kDebugMode) {
            _logRequest(options);
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            _logResponse(response);
          }

          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            _logError(error);
          }

          final requestOptions = error.requestOptions;
          final isUnauthorized = error.response?.statusCode == 401;
          final skipRefresh =
              requestOptions.headers['x-skip-auth-refresh'] == 'true';
          final alreadyRetried = requestOptions.extra['retried'] == true;

          if (isUnauthorized && !skipRefresh && !alreadyRetried) {
            final refreshed = await _tryRefreshToken();

            if (!refreshed) {
              await clearTokens(notifySession: true);
              return handler.next(error);
            }

            final retryHeaders = Map<String, dynamic>.from(
              requestOptions.headers,
            )..remove('x-skip-auth-refresh');

            final newAccessToken =
                _accessToken ?? await _authStorage.getAccessToken();

            if (newAccessToken != null && newAccessToken.trim().isNotEmpty) {
              retryHeaders['Authorization'] = 'Bearer ${newAccessToken.trim()}';
            } else {
              retryHeaders.remove('Authorization');
            }

            final retryOptions = Options(
              method: requestOptions.method,
              headers: retryHeaders,
              responseType: requestOptions.responseType,
              contentType: requestOptions.contentType,
              sendTimeout: requestOptions.sendTimeout,
              receiveTimeout: requestOptions.receiveTimeout,
              extra: {
                ...requestOptions.extra,
                'retried': true,
              },
            );

            try {
              final response = await _dio.request(
                requestOptions.path,
                data: requestOptions.data,
                queryParameters: requestOptions.queryParameters,
                options: retryOptions,
              );

              return handler.resolve(response);
            } catch (retryError) {
              if (retryError is DioException) {
                return handler.next(retryError);
              }

              return handler.next(error);
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio _dio;
  final AuthStorage _authStorage = AuthStorage();

  String? _accessToken;
  String? _refreshToken;
  bool _isInitialized = false;
  Future<bool>? _refreshFuture;
  String _locale = 'ru';

  Dio get dio => _dio;

  void setLocale(String locale) {
    final normalized = locale.trim().toLowerCase();
    _locale = normalized == 'kk' ? 'kk' : 'ru';
  }

  Future<void> init() async {
    if (_isInitialized) return;

    _accessToken = await _authStorage.getAccessToken();
    _refreshToken = await _authStorage.getRefreshToken();

    await _authStorage.getOrCreateDeviceId();

    _isInitialized = true;
  }

  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    await _authStorage.saveAccessToken(token);
  }

  Future<void> setRefreshToken(String token) async {
    _refreshToken = token;
    await _authStorage.saveRefreshToken(token);
  }

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken.trim();
    _refreshToken = refreshToken.trim();

    await _authStorage.saveTokens(
      accessToken.trim(),
      refreshToken.trim(),
    );
  }

  Future<void> loadTokensFromStorage() async {
    _accessToken = await _authStorage.getAccessToken();
    _refreshToken = await _authStorage.getRefreshToken();
  }

  Future<String?> getAccessToken() async {
    if (_accessToken != null && _accessToken!.trim().isNotEmpty) {
      return _accessToken;
    }

    _accessToken = await _authStorage.getAccessToken();
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    if (_refreshToken != null && _refreshToken!.trim().isNotEmpty) {
      return _refreshToken;
    }

    _refreshToken = await _authStorage.getRefreshToken();
    return _refreshToken;
  }

  Future<String> getDeviceId() async {
    return _authStorage.getOrCreateDeviceId();
  }

  Future<void> clearTokens({bool notifySession = false}) async {
    _accessToken = null;
    _refreshToken = null;
    await _authStorage.clear();
    if (notifySession) {
      AuthSessionController.instance.sessionChanged();
    }
  }

  Future<void> clearAccessToken() async {
    await clearTokens();
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _performRefreshToken();

    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _performRefreshToken() async {
    final refreshToken = _refreshToken ?? await _authStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.trim().isEmpty) {
      return false;
    }

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken.trim(),
        },
        options: Options(
          headers: const {
            'x-skip-auth-refresh': 'true',
          },
        ),
      );

      if (response.data is! Map) {
        return false;
      }

      final data = Map<String, dynamic>.from(response.data as Map);

      final newAccessToken = data['accessToken']?.toString() ?? '';
      final newRefreshToken = data['refreshToken']?.toString() ?? refreshToken;

      if (newAccessToken.trim().isEmpty) {
        return false;
      }

      await setTokens(
        accessToken: newAccessToken.trim(),
        refreshToken: newRefreshToken.trim(),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _applyBaseHeaders(RequestOptions options) async {
    final deviceId = await _authStorage.getOrCreateDeviceId();

    options.headers['X-Request-Id'] = _generateRequestId();
    options.headers['X-App'] = 'client';
    options.headers['X-Platform'] = _platformName();
    options.headers['X-App-Version'] = '1.0.0';
    options.headers['X-Device-Id'] = deviceId;
    options.headers['X-Locale'] = _locale;
    options.headers['X-Timezone'] = 'Asia/Almaty';
    options.headers['User-Agent'] = 'JetkizApp/1.0';
  }

  String _platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String _generateRequestId() {
    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);

    final randomPart = List<int>.generate(
      8,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();

    return 'req-$timestamp-$randomPart';
  }

  void _logRequest(RequestOptions options) {
    debugPrint('*** Request ***');
    debugPrint('uri: ${options.uri}');
    debugPrint('method: ${options.method}');
    debugPrint('headers: ${_sanitizeHeaders(options.headers)}');
    debugPrint('data: ${_sanitizeData(options.data)}');
  }

  void _logResponse(Response<dynamic> response) {
    debugPrint('*** Response ***');
    debugPrint('uri: ${response.requestOptions.uri}');
    debugPrint('statusCode: ${response.statusCode}');
    debugPrint('data: ${_sanitizeData(response.data)}');
  }

  void _logError(DioException error) {
    debugPrint('*** DioException ***');
    debugPrint('uri: ${error.requestOptions.uri}');
    debugPrint('statusCode: ${error.response?.statusCode}');
    debugPrint('data: ${_sanitizeData(error.response?.data)}');
    debugPrint('message: ${error.message}');
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final result = <String, dynamic>{};

    for (final entry in headers.entries) {
      final key = entry.key;
      final lowerKey = key.toLowerCase();

      if (lowerKey == 'authorization' ||
          lowerKey == 'cookie' ||
          lowerKey == 'set-cookie') {
        result[key] = '***';
      } else {
        result[key] = entry.value;
      }
    }

    return result;
  }

  dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      final result = <String, dynamic>{};

      for (final entry in data.entries) {
        final key = entry.key.toString();
        final lowerKey = key.toLowerCase();

        if (lowerKey.contains('token') ||
            lowerKey.contains('password') ||
            lowerKey == 'code' ||
            lowerKey == 'otp' ||
            lowerKey == 'smscode') {
          result[key] = '***';
        } else {
          result[key] = _sanitizeData(entry.value);
        }
      }

      return result;
    }

    if (data is List) {
      return data.map(_sanitizeData).toList();
    }

    return data;
  }
}
