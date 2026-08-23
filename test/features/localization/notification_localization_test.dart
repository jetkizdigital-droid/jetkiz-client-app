import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/localizedValue.dart';
import 'package:jetkiz_mobile/features/notifications/domain/notificationItem.dart';

void main() {
  tearDown(() {
    LocalizedValue.setLanguage(AppLanguage.ru);
  });

  test('new notification uses stored RU and KK variants', () {
    final item = NotificationItem.fromJson({
      'id': 'n1',
      'type': 'ORDER_ACCEPTED',
      'title': 'Заказ принят',
      'body': 'Ресторан принял заказ №42',
      'isRead': false,
      'createdAt': '2026-08-23T15:00:00Z',
      'data': {
        'orderId': 'order-1',
        'orderNumber': 42,
        'status': 'ACCEPTED',
        'titleRu': 'Заказ принят',
        'titleKk': 'Тапсырыс қабылданды',
        'bodyRu': 'Ресторан принял заказ №42',
        'bodyKk': 'Мейрамхана №42 тапсырысты қабылдады',
      },
    });

    LocalizedValue.setLanguage(AppLanguage.ru);
    expect(item.displayTitle, 'Заказ принят');
    expect(item.displayBody, 'Ресторан принял заказ №42');

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(item.displayTitle, 'Тапсырыс қабылданды');
    expect(item.displayBody, 'Мейрамхана №42 тапсырысты қабылдады');
  });

  test('legacy order notification derives safe Kazakh copy', () {
    final item = NotificationItem.fromJson({
      'id': 'n2',
      'type': 'ORDER_ON_THE_WAY',
      'title': 'В пути',
      'body': 'Курьер везёт заказ №77',
      'isRead': true,
      'createdAt': '2026-08-23T15:00:00Z',
      'data': {
        'orderId': 'order-2',
        'orderNumber': 77,
        'status': 'ON_THE_WAY',
      },
    });

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(item.displayTitle, 'Жолда');
    expect(item.displayBody, 'Курьер №77 тапсырысты жеткізіп келеді');
  });

  test('free-form campaign copy is not fabricated in Kazakh', () {
    final item = NotificationItem.fromJson({
      'id': 'n3',
      'type': 'ADMIN_CAMPAIGN',
      'title': 'Специальное предложение',
      'body': 'Только сегодня',
      'isRead': false,
      'createdAt': '2026-08-23T15:00:00Z',
      'data': <String, dynamic>{},
    });

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(item.displayTitle, 'Специальное предложение');
    expect(item.displayBody, 'Только сегодня');
  });
}
