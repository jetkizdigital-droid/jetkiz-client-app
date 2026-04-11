import 'dart:io';

import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/profile/domain/profileData.dart';
import 'package:jetkiz_mobile/features/profile/domain/updateProfileDto.dart';

/// ProfileApi
///
/// ВАЖНО:
/// - Токен НЕ передаётся вручную
/// - Он уже установлен в ApiClient
class ProfileApi {
  final ApiClient _apiClient;

  ProfileApi(this._apiClient);

  Future<ProfileData> getMe() async {
    final response = await _apiClient.dio.get('/users/me');
    return _extractProfile(response.data);
  }

  Future<ProfileData> updateMe(UpdateProfileDto dto) async {
    final response = await _apiClient.dio.patch(
      '/users/me',
      data: dto.toJson(),
    );

    return _extractProfile(response.data);
  }

  Future<ProfileData> uploadMyAvatar(File file) async {
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

    final data = _asMap(response.data);
    final avatarUrl = _extractAvatarUrl(data);

    final current = await getMe();
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return current;
    }

    return current.copyWith(avatarUrl: avatarUrl);
  }

  ProfileData _extractProfile(dynamic raw) {
    final data = _asMap(raw);

    final directUserKeys = ['id', 'phone', 'firstName', 'lastName', 'email', 'avatarUrl'];
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

    throw Exception('Invalid profile response format');
  }

  String? _extractAvatarUrl(Map<String, dynamic> data) {
    final direct = data['avatarUrl']?.toString();
    if (direct != null && direct.trim().isNotEmpty) {
      return direct;
    }

    final nested = _tryNestedMap(data, ['user']) ??
        _tryNestedMap(data, ['data']) ??
        _tryNestedMap(data, ['item']) ??
        _tryNestedMap(data, ['result']);

    final nestedAvatar = nested?['avatarUrl']?.toString();
    if (nestedAvatar != null && nestedAvatar.trim().isNotEmpty) {
      return nestedAvatar;
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

    if (current is Map<String, dynamic>) {
      return current;
    }

    if (current is Map) {
      return current.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }

    throw Exception('Invalid profile response format');
  }
}