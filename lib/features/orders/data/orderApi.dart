import 'dart:math';

import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/orders/domain/createOrderPayload.dart';

class OrderApi {
  OrderApi(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createOrder(
    CreateOrderPayload payload, {
    String? idempotencyKey,
  }) async {
    if (!payload.isValid) {
      throw const CreateOrderException(
        message: 'Некорректные данные заказа',
      );
    }

    final requestIdempotencyKey = _normalizeIdempotencyKey(idempotencyKey) ??
        _generateIdempotencyKey(payload);

    try {
      final response = await _apiClient.dio.post(
        '/orders',
        data: payload.toJson(),
        options: Options(
          headers: {
            'Idempotency-Key': requestIdempotencyKey,
          },
        ),
      );

      return _extractOrderMap(response.data);
    } on DioException catch (error) {
      throw CreateOrderException(
        message: _extractErrorMessage(error),
        statusCode: error.response?.statusCode,
        raw: error.response?.data,
        idempotencyKey: requestIdempotencyKey,
      );
    } catch (_) {
      throw CreateOrderException(
        message: 'Не удалось создать заказ',
        idempotencyKey: requestIdempotencyKey,
      );
    }
  }

  Map<String, dynamic> _extractOrderMap(dynamic raw) {
    final root = _asMap(raw);

    if (_looksLikeOrder(root)) {
      return root;
    }

    final nestedOrder = _tryReadNestedMap(root, const ['order']) ??
        _tryReadNestedMap(root, const ['data']) ??
        _tryReadNestedMap(root, const ['item']) ??
        _tryReadNestedMap(root, const ['result']);

    if (nestedOrder != null) {
      return nestedOrder;
    }

    return root;
  }

  bool _looksLikeOrder(Map<String, dynamic> value) {
    return value.containsKey('id') ||
        value.containsKey('number') ||
        value.containsKey('status') ||
        value.containsKey('total') ||
        value.containsKey('paymentStatus');
  }

  Map<String, dynamic>? _tryReadNestedMap(
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
      return Map<String, dynamic>.from(current);
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw const CreateOrderException(
      message: 'Backend вернул некорректный формат заказа',
    );
  }

  String _extractErrorMessage(DioException error) {
    final serverMessage = _extractServerMessage(error.response?.data);
    if (serverMessage != null) {
      return _translateServerMessage(serverMessage);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Превышено время ожидания. Проверьте интернет и попробуйте снова';

      case DioExceptionType.connectionError:
        return 'Нет соединения с сервером. Проверьте интернет';

      case DioExceptionType.cancel:
        return 'Создание заказа отменено';

      case DioExceptionType.badCertificate:
        return 'Ошибка безопасного соединения';

      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final statusCode = error.response?.statusCode;

    if (statusCode == 400) {
      return 'Проверьте данные заказа';
    }

    if (statusCode == 401) {
      return 'Нужно войти в аккаунт';
    }

    if (statusCode == 403) {
      return 'Нет доступа к созданию заказа';
    }

    if (statusCode == 404) {
      return 'Ресторан, адрес или товар не найден';
    }

    if (statusCode == 409) {
      return 'Заказ уже обрабатывается или сейчас нельзя создать новый';
    }

    if (statusCode == 422) {
      return 'Заказ не прошёл проверку. Проверьте корзину и адрес';
    }

    if (statusCode == 429) {
      return 'Слишком много попыток. Подождите немного и попробуйте снова';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'Ошибка сервера. Попробуйте позже';
    }

    return 'Не удалось создать заказ';
  }

  String _translateServerMessage(String message) {
    switch (message.trim().toLowerCase()) {
      case 'restaurant is closed':
        return 'Ресторан сейчас закрыт и не принимает заказы';
      case 'restaurant is not accepting orders':
        return 'Ресторан временно не принимает заказы';
      case 'product is unavailable':
        return 'Один из товаров сейчас недоступен';
      default:
        return message;
    }
  }

  String? _extractServerMessage(dynamic data) {
    if (data is Map) {
      final message = data['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      if (message is List && message.isNotEmpty) {
        return message
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .join('\n');
      }

      final errorText = data['error'];

      if (errorText is String && errorText.trim().isNotEmpty) {
        return errorText.trim();
      }
    }

    return null;
  }

  String? _normalizeIdempotencyKey(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  String _generateIdempotencyKey(CreateOrderPayload payload) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random.secure().nextInt(1 << 32);
    final payloadHash = payload.toJson().toString().hashCode.abs();

    return 'client-order-$timestamp-$random-$payloadHash';
  }
}

class CreateOrderException implements Exception {
  const CreateOrderException({
    required this.message,
    this.statusCode,
    this.raw,
    this.idempotencyKey,
  });

  final String message;
  final int? statusCode;
  final dynamic raw;
  final String? idempotencyKey;

  @override
  String toString() {
    return message;
  }
}
