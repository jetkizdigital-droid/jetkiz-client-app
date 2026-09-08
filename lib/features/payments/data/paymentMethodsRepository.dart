import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';

/// Saved-card façade backed only by the JETKIZ API.
///
/// The backend never exposes PayLink card tokens to Flutter. The app receives
/// display-safe metadata only (brand/last4/bank/default state).
class PaymentMethodsRepository {
  PaymentMethodsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static final PaymentMethodsRepository instance = PaymentMethodsRepository();

  final ApiClient _apiClient;

  Future<List<SavedPaymentCard>> getSavedCards() async {
    try {
      final response = await _apiClient.dio.get('/payments/methods');
      final raw = response.data;
      if (raw is! List) {
        throw const FormatException('Invalid saved payment methods payload');
      }

      return raw
          .whereType<Map>()
          .map(
            (item) => SavedPaymentCard.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    } on PaymentMethodsException {
      rethrow;
    } on DioException catch (error) {
      throw PaymentMethodsException(
        statusCode: error.response?.statusCode,
        message: _messageFor(error),
      );
    } catch (_) {
      throw const PaymentMethodsException(
        message: 'Не удалось загрузить сохранённые карты',
      );
    }
  }

  Future<SavedPaymentCard> setDefaultCard(String cardId) async {
    final id = cardId.trim();
    if (id.isEmpty) {
      throw const PaymentMethodsException(message: 'Некорректная карта');
    }

    try {
      final response =
          await _apiClient.dio.patch('/payments/methods/$id/default');
      if (response.data is! Map) {
        throw const FormatException('Invalid saved payment method payload');
      }
      return SavedPaymentCard.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on PaymentMethodsException {
      rethrow;
    } on DioException catch (error) {
      throw PaymentMethodsException(
        statusCode: error.response?.statusCode,
        message: _messageFor(error),
      );
    } catch (_) {
      throw const PaymentMethodsException(
        message: 'Не удалось сделать карту основной',
      );
    }
  }

  Future<void> deleteCard(String cardId) async {
    final id = cardId.trim();
    if (id.isEmpty) {
      throw const PaymentMethodsException(message: 'Некорректная карта');
    }

    try {
      await _apiClient.dio.delete('/payments/methods/$id');
    } on DioException catch (error) {
      throw PaymentMethodsException(
        statusCode: error.response?.statusCode,
        message: _messageFor(error),
      );
    } catch (_) {
      throw const PaymentMethodsException(
        message: 'Не удалось удалить карту',
      );
    }
  }

  static String _messageFor(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401) return 'Нужно снова войти в аккаунт';
    if (status == 404) return 'Сохранённая карта не найдена';
    if (status == 429) {
      return 'Слишком много запросов. Подождите немного и повторите.';
    }
    if (status != null && status >= 500) {
      return 'Сервис оплаты временно недоступен';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Проверьте подключение к интернету';
      case DioExceptionType.badCertificate:
        return 'Ошибка безопасного соединения';
      case DioExceptionType.cancel:
        return 'Операция отменена';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return 'Не удалось выполнить операцию с картой';
    }
  }
}

class PaymentMethodsException implements Exception {
  const PaymentMethodsException({
    this.statusCode,
    this.message = 'Не удалось выполнить операцию с картой',
  });

  final int? statusCode;
  final String message;
}
