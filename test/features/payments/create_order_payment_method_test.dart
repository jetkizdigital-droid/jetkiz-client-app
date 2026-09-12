import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/orders/domain/createOrderPayload.dart';

void main() {
  test('checkout payload always creates a CARD order', () {
    const payload = CreateOrderPayload(
      restaurantId: 'restaurant-1',
      fulfillmentType: OrderFulfillmentType.pickup,
      items: [
        CreateOrderItemPayload(
          productId: 'product-1',
          quantity: 1,
        ),
      ],
    );

    expect(payload.toJson()['paymentMethod'], 'CARD');
  });
}
