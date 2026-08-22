import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/restaurants/domain/restaurantAvailability.dart';

void main() {
  group('RestaurantAvailability', () {
    test('label is Открыто for open and accepting restaurant', () {
      const availability = RestaurantAvailability(
        status: 'OPEN',
        isInApp: true,
        isAcceptingOrders: true,
        allowMissingWorkingHours: true,
      );

      expect(availability.label, 'Открыто');
    });

    test('label is Закрыто for unavailable or closed restaurant', () {
      const closed = RestaurantAvailability(
        status: 'CLOSED',
        isInApp: true,
        isAcceptingOrders: true,
      );
      const unavailable = RestaurantAvailability(
        status: 'OPEN',
        isInApp: false,
        isAcceptingOrders: true,
      );

      expect(closed.label, 'Закрыто');
      expect(unavailable.label, 'Закрыто');
    });

    test('label says temporarily not accepting orders when open but paused',
        () {
      const availability = RestaurantAvailability(
        status: 'OPEN',
        isInApp: true,
        isAcceptingOrders: false,
        allowMissingWorkingHours: true,
      );

      expect(availability.label, 'Временно не принимает заказы');
    });

    test('canOrder is true only when open, in-app, and accepting orders', () {
      const orderable = RestaurantAvailability(
        status: 'OPEN',
        isInApp: true,
        isAcceptingOrders: true,
        allowMissingWorkingHours: true,
      );
      const closed = RestaurantAvailability(
        status: 'CLOSED',
        isInApp: true,
        isAcceptingOrders: true,
      );
      const unavailable = RestaurantAvailability(
        status: 'OPEN',
        isInApp: false,
        isAcceptingOrders: true,
      );
      const paused = RestaurantAvailability(
        status: 'OPEN',
        isInApp: true,
        isAcceptingOrders: false,
        allowMissingWorkingHours: true,
      );

      expect(orderable.canOrder, isTrue);
      expect(closed.canOrder, isFalse);
      expect(unavailable.canOrder, isFalse);
      expect(paused.canOrder, isFalse);
    });

    test('missing working hours is closed by default', () {
      const availability = RestaurantAvailability(
        status: 'OPEN',
        isInApp: true,
        isAcceptingOrders: true,
      );

      expect(availability.canOrder, isFalse);
      expect(availability.label, 'Закрыто');
    });
  });
}
