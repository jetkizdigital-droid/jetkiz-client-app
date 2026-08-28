import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/menu/domain/restaurantMenuData.dart';
import 'package:jetkiz_mobile/features/restaurants/domain/restaurant.dart';
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

    test('server isOpenNow overrides local working-hours fallback', () {
      const availability = RestaurantAvailability(
        status: 'OPEN',
        isInApp: true,
        isAcceptingOrders: true,
        allowMissingWorkingHours: true,
        serverIsOpenNow: false,
        serverCanAcceptOrders: false,
      );

      expect(availability.isOpen, isFalse);
      expect(availability.canOrder, isFalse);
      expect(availability.label, 'Закрыто');
    });

    test('server canAcceptOrders can pause an otherwise open restaurant', () {
      const availability = RestaurantAvailability(
        status: 'OPEN',
        isInApp: true,
        isAcceptingOrders: true,
        serverIsOpenNow: true,
        serverCanAcceptOrders: false,
      );

      expect(availability.isOpen, isTrue);
      expect(availability.canOrder, isFalse);
      expect(availability.label, 'Временно не принимает заказы');
    });

    test('server availability allows order without using device time', () {
      const availability = RestaurantAvailability(
        status: 'OPEN',
        isInApp: true,
        isAcceptingOrders: true,
        workingHours: '00:00 - 00:01',
        serverIsOpenNow: true,
        serverCanAcceptOrders: true,
      );

      expect(availability.isOpen, isTrue);
      expect(availability.canOrder, isTrue);
    });

    test('restaurant model consumes server availability and pickup contract',
        () {
      final restaurant = Restaurant.fromJson({
        'id': 'restaurant-1',
        'number': 1,
        'slug': 'restaurant-1',
        'nameRu': 'Тест',
        'nameKk': 'Тест',
        'status': 'OPEN',
        'isInApp': true,
        'isAcceptingOrders': true,
        'workingHours': '00:00 - 00:01',
        'isOpenNow': false,
        'canAcceptOrders': false,
        'isPickupEnabled': true,
      });

      expect(restaurant.serverIsOpenNow, isFalse);
      expect(restaurant.serverCanAcceptOrders, isFalse);
      expect(restaurant.canOrder, isFalse);
      expect(restaurant.isPickupEnabled, isTrue);
    });

    test('menu restaurant consumes the same server availability contract', () {
      final menuRestaurant = RestaurantMenuRestaurant.fromJson({
        'id': 'restaurant-1',
        'number': 1,
        'slug': 'restaurant-1',
        'nameRu': 'Тест',
        'nameKk': 'Тест',
        'status': 'OPEN',
        'isInApp': true,
        'isAcceptingOrders': true,
        'workingHours': '00:00 - 00:01',
        'isOpenNow': true,
        'canAcceptOrders': true,
        'isPickupEnabled': true,
      });

      expect(menuRestaurant.serverIsOpenNow, isTrue);
      expect(menuRestaurant.serverCanAcceptOrders, isTrue);
      expect(menuRestaurant.canOrder, isTrue);
      expect(menuRestaurant.isPickupEnabled, isTrue);
    });
  });
}
