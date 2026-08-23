import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/localizedValue.dart';
import 'package:jetkiz_mobile/features/cart/domain/cartItem.dart';
import 'package:jetkiz_mobile/features/favorites/domain/favorite_models.dart';
import 'package:jetkiz_mobile/features/home/domain/homeData.dart';
import 'package:jetkiz_mobile/features/menu/domain/restaurantMenuData.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderDetailsData.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderHistoryItem.dart';
import 'package:jetkiz_mobile/features/search/domain/searchResult.dart';

void main() {
  tearDown(() {
    LocalizedValue.setLanguage(AppLanguage.ru);
  });

  test('selector uses current language with safe fallback', () {
    LocalizedValue.setLanguage(AppLanguage.ru);
    expect(LocalizedValue.select(ru: 'Плов', kk: 'Палау'), 'Плов');

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(LocalizedValue.select(ru: 'Плов', kk: 'Палау'), 'Палау');
    expect(LocalizedValue.select(ru: 'Плов', kk: ''), 'Плов');
  });

  test('menu dish and category switch without reparsing backend data', () {
    const category = RestaurantMenuCategory(
      id: 'category-1',
      code: 'hot',
      titleRu: 'Горячие блюда',
      titleKk: 'Ыстық тағамдар',
      sortOrder: 1,
      iconUrl: null,
    );
    const item = RestaurantMenuItem(
      id: 'product-1',
      titleRu: 'Куриный плов',
      titleKk: 'Тауық еті қосылған палау',
      price: 1800,
      imageUrl: null,
      isAvailable: true,
      categoryId: 'category-1',
      categoryNameRu: 'Горячие блюда',
      categoryNameKk: 'Ыстық тағамдар',
      categoryCode: 'hot',
      categorySortOrder: 1,
      weight: null,
      composition: null,
      description: null,
      isDrink: false,
      images: [],
    );

    LocalizedValue.setLanguage(AppLanguage.ru);
    expect(category.title, 'Горячие блюда');
    expect(item.title, 'Куриный плов');
    expect(item.categoryTitle, 'Горячие блюда');

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(category.title, 'Ыстық тағамдар');
    expect(item.title, 'Тауық еті қосылған палау');
    expect(item.categoryTitle, 'Ыстық тағамдар');
  });

  test('restaurant keeps brand name but localizes description', () {
    final restaurant = RestaurantMenuRestaurant.fromJson({
      'id': 'restaurant-1',
      'number': 1,
      'status': 'OPEN',
      'isInApp': true,
      'isAcceptingOrders': true,
      'nameRu': 'JET CAFE',
      'nameKk': 'JET CAFE',
      'slug': 'jet-cafe',
      'isPickupEnabled': true,
      'descriptionRu': 'Домашняя кухня',
      'descriptionKk': 'Үй тағамдары',
    });

    LocalizedValue.setLanguage(AppLanguage.ru);
    expect(restaurant.displayName, 'JET CAFE');
    expect(restaurant.description, 'Домашняя кухня');

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(restaurant.displayName, 'JET CAFE');
    expect(restaurant.description, 'Үй тағамдары');
  });

  test('home category and product switch language', () {
    final category = HomeCategoryData.fromJson({
      'id': 'category-1',
      'titleRu': 'Напитки',
      'titleKk': 'Сусындар',
      'products': <dynamic>[],
    });
    final product = HomeCategoryProductData.fromJson({
      'id': 'product-1',
      'titleRu': 'Чай',
      'titleKk': 'Шай',
      'price': 500,
      'restaurantId': 'restaurant-1',
      'restaurant': {
        'id': 'restaurant-1',
        'nameRu': 'JET CAFE',
        'status': 'OPEN',
        'runtimeStatus': 'OPEN',
        'isInApp': true,
        'isAcceptingOrders': true,
      },
    });

    LocalizedValue.setLanguage(AppLanguage.ru);
    expect(category.title, 'Напитки');
    expect(product.title, 'Чай');

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(category.title, 'Сусындар');
    expect(product.title, 'Шай');
    expect(product.restaurant.name, 'JET CAFE');
  });

  test('search product and category switch language while brand stays fixed', () {
    final result = SearchResult.fromJson({
      'restaurants': [
        {
          'id': 'restaurant-1',
          'name': 'JET CAFE',
          'nameRu': 'JET CAFE',
          'nameKk': 'JET CAFE',
          'ratingAvg': 5,
        },
      ],
      'products': [
        {
          'id': 'product-1',
          'titleRu': 'Куриный плов',
          'titleKk': 'Тауық еті қосылған палау',
          'price': 1800,
          'restaurantId': 'restaurant-1',
          'restaurantName': 'JET CAFE',
          'category': {
            'id': 'category-1',
            'titleRu': 'Горячие блюда',
            'titleKk': 'Ыстық тағамдар',
          },
        },
      ],
    });

    final restaurant = result.restaurants.single;
    final product = result.products.single;

    LocalizedValue.setLanguage(AppLanguage.ru);
    expect(restaurant.name, 'JET CAFE');
    expect(product.title, 'Куриный плов');
    expect(product.categoryTitle, 'Горячие блюда');

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(restaurant.name, 'JET CAFE');
    expect(product.title, 'Тауық еті қосылған палау');
    expect(product.categoryTitle, 'Ыстық тағамдар');
  });

  test('favorites preserve restaurant brand and localize dish/category', () {
    const restaurant = FavoriteRestaurant(
      id: 'restaurant-1',
      name: 'JET CAFE',
      ratingAvg: 5,
      ratingCount: 10,
      status: 'OPEN',
      isInApp: true,
      isAcceptingOrders: true,
    );
    const category = FavoriteProductCategory(
      id: 'category-1',
      titleRu: 'Десерты',
      titleKk: 'Десерттер',
    );
    const product = FavoriteProduct(
      id: 'product-1',
      titleRu: 'Медовик',
      titleKk: 'Бал торты',
      price: 1200,
      isAvailable: true,
      restaurantId: 'restaurant-1',
      restaurant: restaurant,
      category: category,
    );

    LocalizedValue.setLanguage(AppLanguage.ru);
    expect(product.title, 'Медовик');
    expect(product.category!.title, 'Десерты');
    expect(product.restaurant.name, 'JET CAFE');

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(product.title, 'Бал торты');
    expect(product.category!.title, 'Десерттер');
    expect(product.restaurant.name, 'JET CAFE');
  });

  test('cart item keeps both titles when app language changes', () {
    const item = CartItem(
      productId: 'product-1',
      restaurantId: 'restaurant-1',
      titleRu: 'Бургер',
      titleKk: 'Бургер',
      price: 2500,
      quantity: 1,
    );

    LocalizedValue.setLanguage(AppLanguage.ru);
    expect(item.title, 'Бургер');

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(item.title, 'Бургер');

    final restored = CartItem.fromJson({
      'productId': 'product-2',
      'restaurantId': 'restaurant-1',
      'title': 'Плов',
      'price': 1800,
      'quantity': 1,
    });
    expect(restored.title, 'Плов');
  });

  test('order preview and detail use immutable localized snapshots', () {
    final preview = OrderPreviewItem.fromJson({
      'title': 'Плов',
      'titleRu': 'Плов',
      'titleKk': 'Палау',
      'quantity': 2,
    });
    final detail = OrderDetailsItem.fromJson({
      'id': 'item-1',
      'productId': 'product-1',
      'title': 'Плов',
      'titleRu': 'Плов',
      'titleKk': 'Палау',
      'price': 1800,
      'quantity': 2,
    });

    LocalizedValue.setLanguage(AppLanguage.ru);
    expect(preview.title, 'Плов');
    expect(detail.title, 'Плов');

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(preview.title, 'Палау');
    expect(detail.title, 'Палау');
  });

  test('old order without Kazakh snapshot falls back to exact legacy title', () {
    final oldItem = OrderDetailsItem.fromJson({
      'id': 'old-item',
      'productId': 'product-old',
      'title': 'Старое название блюда',
      'price': 1000,
      'quantity': 1,
    });

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(oldItem.title, 'Старое название блюда');
  });

  test('order address labels follow selected language', () {
    const address = OrderDetailsAddress(
      id: 'address-1',
      title: 'Дом',
      address: 'ул. Абылай хана, 1',
      entrance: '2',
      floor: '3',
      door: '12',
    );

    LocalizedValue.setLanguage(AppLanguage.ru);
    expect(address.formatted, contains('Подъезд: 2'));
    expect(address.formatted, contains('Этаж: 3'));

    LocalizedValue.setLanguage(AppLanguage.kk);
    expect(address.formatted, contains('Кіреберіс: 2'));
    expect(address.formatted, contains('Қабат: 3'));
    expect(address.formatted, contains('Пәтер/кеңсе: 12'));
  });
}
