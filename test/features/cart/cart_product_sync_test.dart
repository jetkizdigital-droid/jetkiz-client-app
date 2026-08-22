import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/cart/data/cartPersistence.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';
import 'package:jetkiz_mobile/features/cart/data/productSyncApi.dart';
import 'package:jetkiz_mobile/features/cart/domain/cartItem.dart';
import 'package:jetkiz_mobile/features/cart/domain/cartState.dart';

void main() {
  group('Cart product sync', () {
    test('updates 2000 price to backend 2300 and reports one price change',
        () async {
      final api = _FakeProductSyncClient()
        ..items = [_syncItem('p1', price: 2300)];
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'Плов',
        price: 2000,
        quantity: 2,
      );

      final result = await repository.syncWithServer();

      expect(result.priceChanged, isTrue);
      expect(repository.itemOf('p1')?.price, 2300);
      expect(repository.subtotal, 4600);
      expect(repository.hasPendingPriceUpdateNotification, isTrue);
      expect(repository.consumePendingPriceUpdateNotification(), isTrue);
      expect(repository.consumePendingPriceUpdateNotification(), isFalse);
    });

    test('next sync with persisted backend price does not report price change',
        () async {
      final api = _FakeProductSyncClient()
        ..items = [_syncItem('p1', price: 2300)];
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'Плов',
        price: 2300,
        quantity: 1,
      );

      final result = await repository.syncWithServer();

      expect(result.priceChanged, isFalse);
      expect(repository.hasPendingPriceUpdateNotification, isFalse);
    });

    test('multiple changed prices produce one overall event', () async {
      final api = _FakeProductSyncClient()
        ..items = [
          _syncItem('p1', price: 2300),
          _syncItem('p2', price: 1800),
        ];
      final repository = _repository(api);

      repository
        ..addItem(
          productId: 'p1',
          restaurantId: 'r1',
          title: 'Плов',
          price: 2000,
          quantity: 1,
        )
        ..addItem(
          productId: 'p2',
          restaurantId: 'r1',
          title: 'Салат',
          price: 1500,
          quantity: 1,
        );

      final result = await repository.syncWithServer();

      expect(result.priceChanged, isTrue);
      expect(repository.consumePendingPriceUpdateNotification(), isTrue);
      expect(repository.consumePendingPriceUpdateNotification(), isFalse);
    });

    test('UNAVAILABLE keeps item, persists new price, and blocks ordering',
        () async {
      final api = _FakeProductSyncClient()
        ..items = [
          _syncItem('p1', price: 2300, state: ProductSyncState.unavailable),
        ];
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'Плов',
        price: 2000,
        quantity: 1,
      );

      final result = await repository.syncWithServer();
      final item = repository.itemOf('p1');

      expect(result.hasBlockingItems, isTrue);
      expect(item?.price, 2300);
      expect(item?.syncState, CartItemSyncState.unavailable);
      expect(item?.canOrder, isFalse);
      expect(repository.toOrderItemsJson, throwsStateError);
    });

    test('NOT_FOUND keeps item unavailable and does not destroy cart',
        () async {
      final api = _FakeProductSyncClient()
        ..items = [
          _syncItem('p1', exists: false, state: ProductSyncState.notFound),
        ];
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'Плов',
        price: 2000,
        quantity: 1,
      );

      await repository.syncWithServer();

      expect(repository.items, hasLength(1));
      expect(repository.itemOf('p1')?.syncState, CartItemSyncState.notFound);
      expect(repository.itemOf('p1')?.canOrder, isFalse);
      expect(repository.itemOf('p1')?.blockingReason, 'Больше недоступно');
      expect(repository.toOrderItemsJson, throwsStateError);
    });

    test('blocking item does not produce a partial order payload', () async {
      final api = _FakeProductSyncClient()
        ..items = [
          _syncItem('p1', state: ProductSyncState.unavailable),
          _syncItem('p2', price: 1500),
        ];
      final repository = _repository(api);

      repository
        ..addItem(
          productId: 'p1',
          restaurantId: 'r1',
          title: 'РџР»РѕРІ',
          price: 2000,
          quantity: 1,
        )
        ..addItem(
          productId: 'p2',
          restaurantId: 'r1',
          title: 'РЎР°Р»Р°С‚',
          price: 1500,
          quantity: 1,
        );

      await repository.syncWithServer();

      expect(repository.hasBlockingItems, isTrue);
      expect(repository.toOrderItemsJson, throwsStateError);
    });

    test('checkout order payload is not formed with blocking items', () async {
      final api = _FakeProductSyncClient()
        ..items = [_syncItem('p1', state: ProductSyncState.unavailable)];
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'РџР»РѕРІ',
        price: 2000,
        quantity: 1,
      );

      await repository.syncWithServer();

      expect(repository.hasBlockingItems, isTrue);
      expect(repository.toOrderItemsJson, throwsStateError);
    });

    test('NOT_FOUND blocking reason says no longer available', () async {
      const item = CartItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'РџР»РѕРІ',
        price: 2000,
        quantity: 1,
        syncState: CartItemSyncState.notFound,
      );

      expect(item.blockingReason, 'Больше недоступно');
    });

    test('UNAVAILABLE blocking reason says unavailable', () async {
      const item = CartItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'РџР»РѕРІ',
        price: 2000,
        quantity: 1,
        syncState: CartItemSyncState.unavailable,
      );

      expect(item.blockingReason, 'Недоступно');
    });

    test('API failure keeps old cart data and has no price notification',
        () async {
      final api = _FakeProductSyncClient()..error = Exception('offline');
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'Плов',
        price: 2000,
        quantity: 1,
      );

      final result = await repository.syncWithServer();

      expect(result.failed, isTrue);
      expect(repository.itemOf('p1')?.price, 2000);
      expect(repository.hasPendingPriceUpdateNotification, isFalse);
    });

    test('duplicate product IDs are sent once to sync client', () async {
      final api = _FakeProductSyncClient()
        ..items = [_syncItem('p1', price: 2300)];
      final repository = _repository(api);

      repository
        ..addItem(
          productId: 'p1',
          restaurantId: 'r1',
          title: 'Плов',
          price: 2000,
          quantity: 1,
        )
        ..addItem(
          productId: 'p1',
          restaurantId: 'r1',
          title: 'Плов',
          price: 2000,
          quantity: 1,
        );

      await repository.syncWithServer();

      expect(api.calls, 1);
      expect(api.requestedProductIds.single, ['p1']);
    });

    test('ProductSyncApi batches more than 50 IDs and keeps de-dupe order',
        () async {
      final batches = <List<String>>[];
      final api = ProductSyncApi(
        ApiClient(),
        transport: (ids) async {
          batches.add(List<String>.from(ids));
          return ids.map((id) => _syncJson(id, price: 1000)).toList();
        },
      );

      final ids = [
        for (var index = 0; index < 55; index++) 'p$index',
        'p1',
        'p2',
      ];

      final result = await api.syncProducts(ids);

      expect(result, hasLength(55));
      expect(batches, hasLength(2));
      expect(batches.first, hasLength(50));
      expect(batches.last, hasLength(5));
      expect(batches.first.first, 'p0');
      expect(batches.last.last, 'p54');
    });

    test('concurrent sync shares the in-flight request', () async {
      final completer = Completer<List<ProductSyncItem>>();
      final api = _FakeProductSyncClient()..completer = completer;
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'Плов',
        price: 2000,
        quantity: 1,
      );

      final first = repository.syncWithServer();
      final second = repository.syncWithServer();
      await Future<void>.delayed(Duration.zero);

      expect(api.calls, 1);

      completer.complete([_syncItem('p1', price: 2300)]);

      final results = await Future.wait([first, second]);

      expect(results.map((result) => result.priceChanged).toList(), [
        true,
        true,
      ]);
      expect(api.calls, 1);
    });

    test('item added during in-flight sync is not marked by old response',
        () async {
      final completer = Completer<List<ProductSyncItem>>();
      final api = _FakeProductSyncClient()..completer = completer;
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'РџР»РѕРІ',
        price: 2000,
        quantity: 1,
      );

      final sync = repository.syncWithServer();
      await Future<void>.delayed(Duration.zero);

      repository.addItem(
        productId: 'p2',
        restaurantId: 'r1',
        title: 'РЎР°Р»Р°С‚',
        price: 1500,
        quantity: 1,
      );

      completer.complete([_syncItem('p1', price: 2300)]);
      await sync;

      expect(api.requestedProductIds.single, ['p1']);
      expect(repository.itemOf('p2')?.syncState, CartItemSyncState.ok);
      expect(repository.itemOf('p2')?.canOrder, isTrue);
    });

    test('updated price persists and restored cart does not notify again',
        () async {
      final persistence = _FakeCartPersistence();
      final api = _FakeProductSyncClient()
        ..items = [_syncItem('p1', price: 2300)];
      final repository = _repository(api, persistence: persistence);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'Плов',
        price: 2000,
        quantity: 1,
      );

      final firstResult = await repository.syncWithServer();
      expect(repository.consumePendingPriceUpdateNotification(), isTrue);

      final restoredRepository = _repository(api, persistence: persistence);
      await restoredRepository.restore();
      final secondResult = await restoredRepository.syncWithServer();

      expect(firstResult.priceChanged, isTrue);
      expect(restoredRepository.itemOf('p1')?.price, 2300);
      expect(secondResult.priceChanged, isFalse);
      expect(restoredRepository.hasPendingPriceUpdateNotification, isFalse);
    });

    test('pending price notification survives restart until consumed',
        () async {
      final persistence = _FakeCartPersistence();
      final api = _FakeProductSyncClient()
        ..items = [_syncItem('p1', price: 2300)];
      final repository = _repository(api, persistence: persistence);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'РџР»РѕРІ',
        price: 2000,
        quantity: 1,
      );

      await repository.syncWithServer();

      final restoredRepository = _repository(api, persistence: persistence);
      await restoredRepository.restore();

      expect(restoredRepository.hasPendingPriceUpdateNotification, isTrue);
      expect(
          restoredRepository.consumePendingPriceUpdateNotification(), isTrue);

      final acknowledgedRepository = _repository(api, persistence: persistence);
      await acknowledgedRepository.restore();

      expect(
        acknowledgedRepository.hasPendingPriceUpdateNotification,
        isFalse,
      );
    });

    test('unknown product sync state blocks ordering fail-safe', () async {
      final api = ProductSyncApi(
        ApiClient(),
        transport: (_) async {
          return [
            _syncJson('p1', price: 2000)
              ..['state'] = 'SOMETHING_NEW'
              ..['isAvailable'] = true,
          ];
        },
      );
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'РџР»РѕРІ',
        price: 2000,
        quantity: 1,
      );

      await repository.syncWithServer();

      expect(repository.itemOf('p1')?.syncState, CartItemSyncState.unavailable);
      expect(repository.itemOf('p1')?.canOrder, isFalse);
    });

    test('missing restaurant data blocks ordering fail-safe', () async {
      final api = _FakeProductSyncClient()
        ..items = [
          _syncItem(
            'p1',
            price: 2000,
            includeRestaurant: false,
          ),
        ];
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'РџР»РѕРІ',
        price: 2000,
        quantity: 1,
      );

      await repository.syncWithServer();

      expect(repository.itemOf('p1')?.canOrder, isFalse);
      expect(repository.itemOf('p1')?.restaurantIsInApp, isFalse);
    });

    test('closed restaurant blocks ordering with restaurant availability',
        () async {
      final api = _FakeProductSyncClient()
        ..items = [
          _syncItem(
            'p1',
            price: 2000,
            restaurantStatus: 'CLOSED',
          ),
        ];
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'Плов',
        price: 2000,
        quantity: 1,
      );

      await repository.syncWithServer();

      expect(repository.itemOf('p1')?.canOrder, isFalse);
      expect(repository.itemOf('p1')?.blockingReason, 'Ресторан сейчас закрыт');
    });

    test('not accepting restaurant blocks ordering', () async {
      final api = _FakeProductSyncClient()
        ..items = [
          _syncItem(
            'p1',
            price: 2000,
            isAcceptingOrders: false,
          ),
        ];
      final repository = _repository(api);

      repository.addItem(
        productId: 'p1',
        restaurantId: 'r1',
        title: 'Плов',
        price: 2000,
        quantity: 1,
      );

      await repository.syncWithServer();

      expect(repository.itemOf('p1')?.canOrder, isFalse);
      expect(
        repository.itemOf('p1')?.blockingReason,
        'Ресторан временно не принимает заказы',
      );
    });
  });
}

CartRepository _repository(
  ProductSyncClient api, {
  _FakeCartPersistence? persistence,
}) {
  return CartRepository.forTesting(
    productSyncClient: api,
    persistence: persistence ?? _FakeCartPersistence(),
  );
}

class _FakeProductSyncClient implements ProductSyncClient {
  List<ProductSyncItem> items = const <ProductSyncItem>[];
  Object? error;
  Completer<List<ProductSyncItem>>? completer;
  int calls = 0;
  final requestedProductIds = <List<String>>[];

  @override
  Future<List<ProductSyncItem>> syncProducts(List<String> productIds) async {
    calls++;
    requestedProductIds.add(List<String>.from(productIds));

    if (error != null) throw error!;

    final pending = completer;
    if (pending != null) {
      return pending.future;
    }

    return items;
  }
}

class _FakeCartPersistence implements CartPersistence {
  CartState? state;
  bool pendingPriceUpdateNotification = false;

  @override
  Future<void> clear() async {
    state = null;
    pendingPriceUpdateNotification = false;
  }

  @override
  Future<CartState?> load() async {
    return state;
  }

  @override
  Future<void> save(CartState state) async {
    this.state = CartState.fromJson(state.toJson());
  }

  @override
  Future<bool> loadPendingPriceUpdateNotification() async {
    return pendingPriceUpdateNotification;
  }

  @override
  Future<void> savePendingPriceUpdateNotification(bool value) async {
    pendingPriceUpdateNotification = value;
  }
}

ProductSyncItem _syncItem(
  String id, {
  int price = 2000,
  bool exists = true,
  ProductSyncState state = ProductSyncState.ok,
  String restaurantId = 'r1',
  String restaurantStatus = 'OPEN',
  bool isInApp = true,
  bool isAcceptingOrders = true,
  bool includeRestaurant = true,
}) {
  return ProductSyncItem(
    id: id,
    exists: exists,
    state: state,
    price: exists ? price : null,
    isAvailable: state == ProductSyncState.ok,
    restaurantId: restaurantId,
    titleRu: 'Product $id',
    titleKk: null,
    effectiveImageUrl: 'https://cdn.jetkiz.test/$id.png',
    restaurant: includeRestaurant
        ? ProductSyncRestaurant(
            id: restaurantId,
            status: restaurantStatus,
            isInApp: isInApp,
            isAcceptingOrders: isAcceptingOrders,
          )
        : null,
  );
}

Map<String, dynamic> _syncJson(String id, {required int price}) {
  return {
    'id': id,
    'exists': true,
    'state': 'OK',
    'price': price,
    'isAvailable': true,
    'restaurantId': 'r1',
    'titleRu': 'Product $id',
    'effectiveImageUrl': 'https://cdn.jetkiz.test/$id.png',
    'restaurant': {
      'id': 'r1',
      'status': 'OPEN',
      'isInApp': true,
      'isAcceptingOrders': true,
    },
  };
}
