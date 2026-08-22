import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';

class AuthApi {
  final ApiClient _apiClient;

  AuthApi(this._apiClient);

  Future<RequestSmsCodeResponse> requestSmsCode({
    required String phone,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/request-code',
        data: {
          'phone': phone,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);

      return RequestSmsCodeResponse.fromJson(data);
    } on DioException catch (error) {
      throw AuthApiException.fromDio(error);
    } catch (_) {
      throw const AuthApiException(AuthApiErrorType.serverError);
    }
  }

  Future<VerifySmsCodeResponse> verifySmsCode({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-code',
        data: {
          'phone': phone,
          'code': code,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);

      return VerifySmsCodeResponse.fromJson(data);
    } on DioException catch (error) {
      throw AuthApiException.fromDio(error);
    } catch (_) {
      throw const AuthApiException(AuthApiErrorType.serverError);
    }
  }

  Future<RefreshTokenResponse> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/refresh',
      data: {
        'refreshToken': refreshToken,
      },
      options: Options(
        headers: const {
          'x-skip-auth-refresh': 'true',
        },
      ),
    );

    final data = Map<String, dynamic>.from(response.data as Map);

    return RefreshTokenResponse.fromJson(data);
  }
}

class RequestSmsCodeResponse {
  final bool success;
  final String phone;
  final DateTime? expiresAt;
  final DateTime? resendAvailableAt;
  final int? ttlSeconds;
  final int? resendCooldownSeconds;
  final int? maxAttempts;

  const RequestSmsCodeResponse({
    required this.success,
    required this.phone,
    required this.expiresAt,
    required this.resendAvailableAt,
    required this.ttlSeconds,
    required this.resendCooldownSeconds,
    required this.maxAttempts,
  });

  factory RequestSmsCodeResponse.fromJson(Map<String, dynamic> json) {
    return RequestSmsCodeResponse(
      success: json['success'] == true,
      phone: json['phone']?.toString() ?? '',
      expiresAt: _tryParseDateTime(json['expiresAt'] ?? json['expires_at']),
      resendAvailableAt: _tryParseDateTime(
        json['resendAvailableAt'] ?? json['resend_available_at'],
      ),
      ttlSeconds: _tryParseInt(json['ttlSeconds'] ?? json['ttl_seconds']),
      resendCooldownSeconds: _tryParseInt(
        json['resendCooldownSeconds'] ??
            json['resendCooldown'] ??
            json['resend_cooldown_seconds'] ??
            json['cooldownSeconds'] ??
            json['cooldown_seconds'],
      ),
      maxAttempts: _tryParseInt(
        json['maxAttempts'] ?? json['max_attempts'],
      ),
    );
  }
}

DateTime? _tryParseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int? _tryParseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

class VerifySmsCodeResponse {
  final String accessToken;
  final String refreshToken;

  const VerifySmsCodeResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory VerifySmsCodeResponse.fromJson(Map<String, dynamic> json) {
    return VerifySmsCodeResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }
}

class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;

  const RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }
}

enum AuthApiErrorType {
  invalidCode,
  expiredCode,
  tooManyAttempts,
  noInternet,
  serverError,
}

class AuthApiException implements Exception {
  final AuthApiErrorType type;
  final int? statusCode;

  const AuthApiException(
    this.type, {
    this.statusCode,
  });

  factory AuthApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final serverCode = _extractServerValue(error.response?.data, const [
      'code',
      'error',
      'type',
      'reason',
    ]);
    final message = _extractServerValue(error.response?.data, const [
      'message',
      'error',
      'detail',
    ]);
    final marker = '$serverCode $message'.toLowerCase();

    if (statusCode == 429 ||
        marker.contains('too_many') ||
        marker.contains('too many') ||
        marker.contains('attempt') ||
        marker.contains('rate') ||
        marker.contains('limit')) {
      return AuthApiException(
        AuthApiErrorType.tooManyAttempts,
        statusCode: statusCode,
      );
    }

    if (marker.contains('expired') ||
        marker.contains('expire') ||
        marker.contains('ttl') ||
        marker.contains('ист') ||
        marker.contains('просроч')) {
      return AuthApiException(
        AuthApiErrorType.expiredCode,
        statusCode: statusCode,
      );
    }

    if (marker.contains('invalid') ||
        marker.contains('wrong') ||
        marker.contains('incorrect') ||
        marker.contains('otp') ||
        marker.contains('code') ||
        marker.contains('невер') ||
        marker.contains('код')) {
      return AuthApiException(
        AuthApiErrorType.invalidCode,
        statusCode: statusCode,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AuthApiException(
          AuthApiErrorType.noInternet,
          statusCode: statusCode,
        );
      case DioExceptionType.badResponse:
        if (statusCode == 400 || statusCode == 401 || statusCode == 422) {
          return AuthApiException(
            AuthApiErrorType.invalidCode,
            statusCode: statusCode,
          );
        }
        return AuthApiException(
          AuthApiErrorType.serverError,
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return AuthApiException(
          AuthApiErrorType.serverError,
          statusCode: statusCode,
        );
    }
  }

  String get userMessage {
    switch (type) {
      case AuthApiErrorType.invalidCode:
        return 'Неверный код. Проверьте цифры и попробуйте еще раз.';
      case AuthApiErrorType.expiredCode:
        return 'Код истек. Запросите новый код.';
      case AuthApiErrorType.tooManyAttempts:
        return 'Слишком много попыток. Запросите новый код позже.';
      case AuthApiErrorType.noInternet:
        return 'Нет соединения с интернетом. Проверьте сеть и попробуйте снова.';
      case AuthApiErrorType.serverError:
        return 'Сервис временно недоступен. Попробуйте позже.';
    }
  }

  @override
  String toString() => 'AuthApiException($type, statusCode: $statusCode)';
}

String? _extractServerValue(dynamic raw, List<String> keys) {
  if (raw is! Map) return null;

  final data = Map<String, dynamic>.from(raw);
  for (final key in keys) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  final nested = data['data'];
  if (nested is Map) {
    return _extractServerValue(nested, keys);
  }

  return null;
}
