import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderDetailsData.dart';
import 'package:jetkiz_mobile/features/reviews/domain/restaurantReview.dart';

void main() {
  group('review access contract', () {
    test('only a delivered order without a review can be reviewed', () {
      expect(_order(status: 'DELIVERED').canLeaveReview, isTrue);
      expect(_order(status: 'PAID').canLeaveReview, isFalse);
      expect(_order(status: 'READY').canLeaveReview, isFalse);
      expect(
        _order(status: 'DELIVERED', ratingGiven: true).canLeaveReview,
        isFalse,
      );
    });
  });

  group('restaurant reviews backend contract', () {
    test('reads total from meta and reaction summary map', () {
      final data = RestaurantReviewPageData.fromJson({
        'items': [
          {
            'id': 'review-1',
            'rating': 5,
            'createdAt': '2026-08-23T10:00:00.000Z',
            'reactionsSummary': {'LIKE': 2, 'YUMMY': 1},
            'currentUserReaction': 'LIKE',
          },
        ],
        'meta': {'page': 1, 'limit': 30, 'total': 14},
      });

      expect(data.total, 14);
      expect(data.items.single.reactionsSummary, hasLength(2));
      expect(data.items.single.currentUserReaction, 'LIKE');
      expect(
        data.items.single.reactionsSummary
            .firstWhere((item) => item.type == 'LIKE')
            .count,
        2,
      );
    });
  });
}

OrderDetailsData _order({
  required String status,
  bool ratingGiven = false,
}) {
  return OrderDetailsData(
    id: 'order-1',
    number: 1,
    status: status,
    subtotal: 1000,
    deliveryFee: 0,
    discountAmount: 0,
    deliveryDiscountAmount: 0,
    total: 1000,
    phone: '+77000000000',
    paymentMethod: 'CARD',
    paymentStatus: 'PAID',
    ratingGiven: ratingGiven,
    createdAt: DateTime.utc(2026, 8, 23),
    updatedAt: DateTime.utc(2026, 8, 23),
  );
}
