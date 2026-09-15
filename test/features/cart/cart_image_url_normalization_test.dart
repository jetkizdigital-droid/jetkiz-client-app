import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/core/network/networkAssetUrl.dart';
import 'package:jetkiz_mobile/features/cart/data/productSyncApi.dart';
import 'package:jetkiz_mobile/features/cart/domain/cartItem.dart';

void main() {
  group('cart image URL normalization', () {
    test('keeps absolute HTTPS URLs unchanged', () {
      const url = 'https://cdn.example.com/dishes/plov.jpg';
      expect(normalizeNetworkAssetUrl(url), url);
    });

    test('converts backend-relative URLs to absolute URLs', () {
      expect(
        normalizeNetworkAssetUrl('/uploads/dishes/plov.jpg'),
        '${AppConfig.productionBaseUrl}/uploads/dishes/plov.jpg',
      );
      expect(
        normalizeNetworkAssetUrl('uploads/dishes/plov.jpg'),
        '${AppConfig.productionBaseUrl}/uploads/dishes/plov.jpg',
      );
    });

    test('normalizes image URL returned by product sync', () {
      final item = ProductSyncItem.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'exists': true,
        'state': 'OK',
        'price': 2500,
        'isAvailable': true,
        'restaurantId': 'restaurant-1',
        'titleRu': 'Плов',
        'titleKk': 'Палау',
        'effectiveImageUrl': '/uploads/dishes/plov.jpg',
        'restaurant': {
          'id': 'restaurant-1',
          'status': 'OPEN',
          'isInApp': true,
          'isAcceptingOrders': true,
        },
      });

      expect(
        item.effectiveImageUrl,
        '${AppConfig.productionBaseUrl}/uploads/dishes/plov.jpg',
      );
    });

    test('repairs a relative image URL restored from persisted cart', () {
      final item = CartItem.fromJson({
        'productId': '11111111-1111-4111-8111-111111111111',
        'restaurantId': 'restaurant-1',
        'title': 'Плов',
        'titleRu': 'Плов',
        'titleKk': 'Палау',
        'price': 2500,
        'quantity': 1,
        'imageUrl': '/uploads/dishes/plov.jpg',
      });

      expect(
        item.imageUrl,
        '${AppConfig.productionBaseUrl}/uploads/dishes/plov.jpg',
      );
    });
  });
}
