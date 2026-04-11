import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import '../domain/createReviewModels.dart';

class ReviewMediaUploadApi {
  final ApiClient _client;

  ReviewMediaUploadApi(this._client);

  Future<UploadReviewMediaResponse> uploadFile(
    File file, {
    String? kind,
    bool makePreview = true,
  }) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final resolvedKind = (kind ?? _detectKindFromPath(file.path)).trim().toUpperCase();

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: _detectMediaType(file.path, resolvedKind),
      ),
      'kind': resolvedKind,
      'makePreview': makePreview.toString(),
    });

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/restaurants/review-media/upload',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final json = response.data ?? <String, dynamic>{};
    return UploadReviewMediaResponse.fromJson(json);
  }

  String _detectKindFromPath(String path) {
    final lower = path.toLowerCase();

    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.qt') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.3g2') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mpeg') ||
        lower.endsWith('.mpg') ||
        lower.endsWith('.mts') ||
        lower.endsWith('.m2ts') ||
        lower.endsWith('.ts')) {
      return 'VIDEO';
    }

    if (lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.oga') ||
        lower.endsWith('.opus') ||
        lower.endsWith('.amr') ||
        lower.endsWith('.caf') ||
        lower.endsWith('.flac')) {
      return 'AUDIO';
    }

    return 'IMAGE';
  }

  MediaType _detectMediaType(String path, String kind) {
    final lower = path.toLowerCase();

    if (kind == 'VIDEO') {
      if (lower.endsWith('.mov') || lower.endsWith('.qt')) {
        return MediaType('video', 'quicktime');
      }
      if (lower.endsWith('.webm')) {
        return MediaType('video', 'webm');
      }
      if (lower.endsWith('.mkv')) {
        return MediaType('video', 'x-matroska');
      }
      if (lower.endsWith('.avi')) {
        return MediaType('video', 'x-msvideo');
      }
      if (lower.endsWith('.3gp')) {
        return MediaType('video', '3gpp');
      }
      if (lower.endsWith('.3g2')) {
        return MediaType('video', '3gpp2');
      }
      if (lower.endsWith('.mpeg') || lower.endsWith('.mpg')) {
        return MediaType('video', 'mpeg');
      }
      return MediaType('video', 'mp4');
    }

    if (kind == 'AUDIO') {
      if (lower.endsWith('.m4a')) {
        return MediaType('audio', 'x-m4a');
      }
      if (lower.endsWith('.aac')) {
        return MediaType('audio', 'aac');
      }
      if (lower.endsWith('.wav')) {
        return MediaType('audio', 'wav');
      }
      if (lower.endsWith('.ogg') || lower.endsWith('.oga')) {
        return MediaType('audio', 'ogg');
      }
      if (lower.endsWith('.opus')) {
        return MediaType('audio', 'opus');
      }
      if (lower.endsWith('.amr')) {
        return MediaType('audio', 'amr');
      }
      if (lower.endsWith('.caf')) {
        return MediaType('audio', 'x-caf');
      }
      if (lower.endsWith('.flac')) {
        return MediaType('audio', 'flac');
      }
      return MediaType('audio', 'mpeg');
    }

    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (lower.endsWith('.heic')) {
      return MediaType('image', 'heic');
    }
    if (lower.endsWith('.heif')) {
      return MediaType('image', 'heif');
    }
    if (lower.endsWith('.bmp')) {
      return MediaType('image', 'bmp');
    }
    if (lower.endsWith('.gif')) {
      return MediaType('image', 'gif');
    }
    if (lower.endsWith('.tif') || lower.endsWith('.tiff')) {
      return MediaType('image', 'tiff');
    }
    if (lower.endsWith('.avif')) {
      return MediaType('image', 'avif');
    }

    return MediaType('image', 'jpeg');
  }
}