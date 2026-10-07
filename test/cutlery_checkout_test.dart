import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/orders/domain/createOrderPayload.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderDetailsData.dart';
import 'package:jetkiz_mobile/features/restaurants/domain/restaurant.dart';

void main() {
  test('checkout payload sends cutlery count', () {
    const payload = CreateOrderPayload(
      restaurantId: 'restaurant-1',
      fulfillmentType: OrderFulfillmentType.pickup,
      cutleryCount: 5,
      items: [
        CreateOrderItemPayload(productId: 'product-1', quantity: 1),
      ],
    );

    expect(payload.isValid, isTrue);
    expect(payload.toJson()['cutleryCount'], 5);
  });

  test('restaurant parses cutlery policy with safe defaults', () {
    final restaurant = Restaurant.fromJson(const {
      'id': 'restaurant-1',
      'cutleryEnabled': true,
      'cutleryFreeLimit': 3,
      'cutleryUnitPrice': 100,
      'cutleryMaxCount': 10,
    });

    expect(restaurant.cutleryEnabled, isTrue);
    expect(restaurant.cutleryFreeLimit, 3);
    expect(restaurant.cutleryUnitPrice, 100);
    expect(restaurant.cutleryMaxCount, 10);
  });

  test('order details preserve cutlery price snapshot', () {
    final order = OrderDetailsData.fromJson({
      'id': 'order-1',
      'number': 1,
      'status': 'CREATED',
      'subtotal': 10000,
      'deliveryFee': 800,
      'discountAmount': 0,
      'deliveryDiscountAmount': 0,
      'cutleryCount': 5,
      'cutleryFreeLimitApplied': 3,
      'cutleryUnitPriceApplied': 100,
      'cutleryPaidCount': 2,
      'cutleryAmount': 200,
      'total': 11000,
      'phone': '+77000000000',
      'paymentMethod': 'CARD',
      'paymentStatus': 'AUTHORIZED',
      'createdAt': '2026-10-07T12:00:00.000Z',
      'updatedAt': '2026-10-07T12:00:00.000Z',
    });

    expect(order.cutleryCount, 5);
    expect(order.cutleryPaidCount, 2);
    expect(order.cutleryAmount, 200);
  });
}
