import 'dart:io';

import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/profile/domain/profileData.dart';
import 'package:jetkiz_mobile/features/profile/domain/updateProfileDto.dart';

class ProfileApiException implements Exception {
  const ProfileApiException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ProfileApi {
  ProfileApi(this._apiClient);

  final ApiClient _apiClient;

  Future<ProfileData> getMe() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return _extractProfile(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error, fallback: 'Не удалось загрузить профиль');
    } catch (_) {
      throw const ProfileApiException('Не удалось загрузить профиль');
    }
  }

  Future<ProfileData> updateMe(UpdateProfileDto dto) async {
    try {
      final response = await _apiClient.dio.patch(
        '/users/me',
        data: dto.toJson(),
      );

      return _extractProfile(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error, fallback: 'Не удалось сохранить профиль');
    } catch (_) {
      throw const ProfileApiException('Не удалось сохранить профиль');
    }
  }

  Future<ProfileData> uploadMyAvatar(File file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        '/users/me/avatar',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final responseMap = _tryAsMap(response.data);
      final avatarUrl =
          responseMap == null ? null : _extractAvatarUrl(responseMap);

      final current = await getMe();

      if (avatarUrl == null || avatarUrl.trim().isEmpty) {
        return current;
      }

      return current.copyWith(avatarUrl: avatarUrl);
    } on DioException catch (error) {
      throw _mapDioError(error, fallback: 'Не удалось загрузить фото');
    } catch (_) {
      throw const ProfileApiException('Не удалось загрузить фото');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } on DioException {
      // Даже если backend logout не прошёл, UI всё равно очистит локальную сессию.
      return;
    } catch (_) {
      return;
    }
  }

  Future<void> deleteMyAccount() async {
    try {
      await _apiClient.dio.delete<void>('/users/me');
    } on DioException catch (error) {
      throw _mapDioError(
        error,
        fallback: 'Не удалось удалить аккаунт',
      );
    } catch (_) {
      throw const ProfileApiException('Не удалось удалить аккаунт');
    }
  }

  ProfileData _extractProfile(dynamic raw) {
    final data = _asMap(raw);

    final directUserKeys = <String>[
      'id',
      'phone',
      'role',
      'isActive',
      'firstName',
      'lastName',
      'email',
      'avatarUrl',
      'name',
      'createdAt',
      'updatedAt',
    ];

    final hasDirectUser = directUserKeys.any(data.containsKey);
    if (hasDirectUser) {
      return ProfileData.fromJson(data);
    }

    final nestedUser = _tryNestedMap(data, ['user']) ??
        _tryNestedMap(data, ['data']) ??
        _tryNestedMap(data, ['item']) ??
        _tryNestedMap(data, ['result']);

    if (nestedUser != null) {
      return ProfileData.fromJson(nestedUser);
    }

    throw const ProfileApiException('Некорректный ответ профиля');
  }

  String? _extractAvatarUrl(Map<String, dynamic> data) {
    final direct = data['avatarUrl']?.toString();
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    final nested = _tryNestedMap(data, ['user']) ??
        _tryNestedMap(data, ['data']) ??
        _tryNestedMap(data, ['item']) ??
        _tryNestedMap(data, ['result']);

    final nestedAvatar = nested?['avatarUrl']?.toString();
    if (nestedAvatar != null && nestedAvatar.trim().isNotEmpty) {
      return nestedAvatar.trim();
    }

    return null;
  }

  Map<String, dynamic>? _tryNestedMap(
    Map<String, dynamic> source,
    List<String> path,
  ) {
    dynamic current = source;

    for (final part in path) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return _tryAsMap(current);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    final result = _tryAsMap(value);
    if (result == null) {
      throw const ProfileApiException('Некорректный ответ сервера');
    }

    return result;
  }

  Map<String, dynamic>? _tryAsMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }

    return null;
  }

  ProfileApiException _mapDioError(
    DioException error, {
    required String fallback,
  }) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final serverMessage = _readServerMessage(data);

    if (statusCode == 401) {
      return ProfileApiException(
        'Сессия истекла. Войдите заново',
        statusCode: statusCode,
      );
    }

    if (statusCode == 413) {
      return ProfileApiException(
        'Файл слишком большой',
        statusCode: statusCode,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ProfileApiException(
        'Сервер временно недоступен',
        statusCode: statusCode,
      );
    }

    return ProfileApiException(
      serverMessage ?? fallback,
      statusCode: statusCode,
    );
  }

  String? _readServerMessage(dynamic data) {
    final map = _tryAsMap(data);
    if (map == null) return null;

    final message = map['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    if (message is List && message.isNotEmpty) {
      return message.first.toString();
    }

    final error = map['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }

    return null;
  }
}
