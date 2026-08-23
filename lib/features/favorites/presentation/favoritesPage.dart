import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/features/auth/data/authStorage.dart';
import 'package:jetkiz_mobile/features/auth/data/authSessionController.dart';
import 'package:jetkiz_mobile/features/auth/presentation/phoneLoginPage.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';
import 'package:jetkiz_mobile/features/cart/presentation/cartAddFlow.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesController.dart';
import 'package:jetkiz_mobile/features/favorites/domain/favorite_models.dart';
import 'package:jetkiz_mobile/features/menu/domain/restaurantMenuData.dart';
import 'package:jetkiz_mobile/features/menu/presentation/productDetailsPage.dart';
import 'package:jetkiz_mobile/features/menu/presentation/restaurantMenuPage.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FavoritesController _favorites = FavoritesController.instance;
  bool _isCheckingAuth = true;
  bool _isAuthorized = false;
  Timer? _availabilityTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _favorites.addListener(_handleFavoritesChanged);
    AuthSessionController.instance.addListener(_handleSessionChanged);
    _availabilityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted && _isAuthorized) setState(() {});
      },
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _availabilityTimer?.cancel();
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _favorites.removeListener(_handleFavoritesChanged);
    AuthSessionController.instance.removeListener(_handleSessionChanged);
    super.dispose();
  }

  void _handleSessionChanged() {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final authorized = await AuthStorage().hasAccessToken();
    if (!mounted) return;
    setState(() {
      _isAuthorized = authorized;
      _isCheckingAuth = false;
    });
    if (!authorized) return;
    await _favorites.initialize();
    await _favorites.refreshRestaurants();
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhoneLoginPage(
          onAuthorized: () async {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (!mounted) return;
    await _bootstrap();
  }

  void _handleFavoritesChanged() {
    if (mounted) setState(() {});
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1 && !_favorites.productsLoaded) {
      _favorites.refreshProducts();
    }
  }

  Future<void> refreshIfStale() async {
    await _favorites.refreshIfStale();
  }

  void _openRestaurant(FavoriteRestaurantRecord item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantMenuPage(
          restaurantId: item.restaurant.id,
          restaurantName: item.restaurant.name,
        ),
      ),
    );
  }

  Future<void> _removeRestaurant(String restaurantId) async {
    try {
      await _favorites.removeRestaurant(restaurantId);
      _showSnack('Ресторан удален из избранного');
    } catch (_) {
      _showSnack('Не удалось удалить ресторан из избранного');
    }
  }

  Future<void> _removeProduct(String productId) async {
    try {
      await _favorites.removeProduct(productId);
      _showSnack('Блюдо удалено из избранного');
    } catch (_) {
      _showSnack('Не удалось удалить блюдо из избранного');
    }
  }

  RestaurantMenuItem _menuItem(FavoriteProduct product) {
    return RestaurantMenuItem(
      id: product.id,
      titleRu: product.title,
      titleKk: '',
      price: product.price,
      imageUrl: product.effectiveImageUrl ?? product.imageUrl,
      isAvailable: product.isAvailable,
      categoryId: product.categoryId,
      categoryNameRu: product.category?.title,
      categoryNameKk: null,
      categoryCode: null,
      categorySortOrder: null,
      weight: product.weight,
      composition: product.composition,
      description: product.description,
      isDrink: product.isDrink,
      images: product.images
          .map((image) => RestaurantMenuItemImage(
                id: image.id,
                url: image.url,
                isMain: image.isMain,
                sortOrder: image.sortOrder,
              ))
          .toList(),
    );
  }

  void _openProduct(FavoriteProductRecord item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: _menuItem(item.product),
          restaurantId: item.product.restaurantId,
          restaurantName: item.product.restaurant.name,
        ),
      ),
    );
  }

  Future<void> _addProduct(FavoriteProductRecord item) async {
    final product = item.product;
    final result = await addItemWithRestaurantConfirmation(
      context: context,
      productId: product.id,
      restaurantId: product.restaurantId,
      restaurantName: product.restaurant.name,
      title: product.title,
      price: product.price,
      quantity: 1,
      imageUrl: product.effectiveImageUrl ?? product.imageUrl,
      description: product.description,
      weight: product.weight,
    );
    if (!mounted || result == CartAddResult.rejectedDifferentRestaurant) return;
    _showSnack('Добавлено в корзину');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildRestaurantsTab() {
    final restaurants = _favorites.restaurants;
    final error = _favorites.restaurantError;

    if (error != null && !_favorites.restaurantsLoaded) {
      return _ErrorView(
        message: error,
        onRetry: _favorites.refreshRestaurants,
      );
    }

    if (_favorites.isRestaurantsLoading && !_favorites.restaurantsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (restaurants.isEmpty) {
      return RefreshIndicator(
        onRefresh: _favorites.refreshRestaurants,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _EmptyView(
              icon: Icons.favorite_border,
              title: 'Нет избранных ресторанов',
              subtitle:
                  'Добавь рестораны в избранное, чтобы быстро возвращаться к ним.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _favorites.refreshRestaurants,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = restaurants[index];
          final busy = _favorites.isRestaurantBusy(item.restaurant.id);

          return _RestaurantFavoriteCard(
            item: item,
            isBusy: busy,
            onOpen: () => _openRestaurant(item),
            onRemove: () => _removeRestaurant(item.restaurant.id),
          );
        },
      ),
    );
  }

  Widget _buildProductsTab() {
    final products = _favorites.products;
    final error = _favorites.productError;

    if (error != null && !_favorites.productsLoaded) {
      return _ErrorView(
        message: error,
        onRetry: _favorites.refreshProducts,
      );
    }

    if (_favorites.isProductsLoading && !_favorites.productsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_favorites.productsLoaded) {
      return const Center(
        child: Text(
          'Открой вкладку, чтобы загрузить блюда',
          style: TextStyle(fontSize: 15),
        ),
      );
    }

    if (products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _favorites.refreshProducts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _EmptyView(
              icon: Icons.favorite_outline,
              title: 'Нет избранных блюд',
              subtitle: 'Добавь блюда в избранное, чтобы не искать их заново.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _favorites.refreshProducts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = products[index];
          final busy = _favorites.isProductBusy(item.product.id);

          return _ProductFavoriteCard(
            item: item,
            isBusy: busy,
            onOpen: () => _openProduct(item),
            onAdd: () => _addProduct(item),
            onRemove: () => _removeProduct(item.product.id),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizationScope.of(context).strings;
    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.favoritesTitle)),
        body: _GuestFavorites(onLogin: _openLogin),
      );
    }
    final isInitialLoading = _favorites.isInitializing ||
        (_favorites.isRestaurantsLoading && !_favorites.restaurantsLoaded);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.favoritesTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: '${strings.favoriteRestaurants} (${_favorites.restaurants.length})'),
            Tab(text: '${strings.favoriteProducts} (${_favorites.products.length})'),
          ],
        ),
      ),
      body: isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRestaurantsTab(),
                _buildProductsTab(),
              ],
            ),
    );
  }
}

class _RestaurantFavoriteCard extends StatelessWidget {
  const _RestaurantFavoriteCard({
    required this.item,
    required this.isBusy,
    required this.onOpen,
    required this.onRemove,
  });

  final FavoriteRestaurantRecord item;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final restaurant = item.restaurant;
    final availability = restaurant.availability;
    final subtitle = <String>[
      if ((restaurant.address ?? '').trim().isNotEmpty)
        restaurant.address!.trim(),
      if ((restaurant.workingHours ?? '').trim().isNotEmpty)
        restaurant.workingHours!.trim(),
    ].join(' • ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((restaurant.coverImageUrl ?? '').trim().isNotEmpty)
              SizedBox(
                height: 170,
                width: double.infinity,
                child: Image.network(
                  restaurant.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                ),
              )
            else
              const SizedBox(
                height: 170,
                width: double.infinity,
                child: _ImagePlaceholder(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: isBusy ? null : onRemove,
                        icon: isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.favorite),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.star_rounded,
                        text: restaurant.ratingAvg.toStringAsFixed(1),
                      ),
                      _InfoChip(
                        icon: Icons.reviews_outlined,
                        text: '${restaurant.ratingCount}',
                      ),
                      _InfoChip(
                        icon: availability.canOrder
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        text: availability.label,
                      ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFavoriteCard extends StatelessWidget {
  const _ProductFavoriteCard({
    required this.item,
    required this.isBusy,
    required this.onOpen,
    required this.onAdd,
    required this.onRemove,
  });

  final FavoriteProductRecord item;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final restaurantAvailability = product.restaurant.availability;
    final canOrder = product.isAvailable && restaurantAvailability.canOrder;
    final imageUrl = product.effectiveImageUrl ?? product.imageUrl;
    final priceText = '${product.price} ₸';
    final disabledReason =
        product.isAvailable ? restaurantAvailability.label : 'Недоступно';

    return Opacity(
      opacity: canOrder ? 1 : 0.58,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: imageUrl != null && imageUrl.trim().isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _ImagePlaceholder(),
                        )
                      : const _ImagePlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            priceText,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!canOrder)
                            _AvailabilityPill(text: disabledReason),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: isBusy ? null : onRemove,
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.favorite),
                  ),
                  IconButton.filled(
                    onPressed: canOrder ? onAdd : null,
                    tooltip: 'Добавить в корзину',
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _GuestFavorites extends StatelessWidget {
  const _GuestFavorites({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizationScope.of(context).strings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border_rounded, size: 72),
            const SizedBox(height: 20),
            Text(strings.guestFavoritesTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(strings.guestFavoritesSubtitle,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onLogin, child: Text(strings.loginToAccount)),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.orange.withValues(alpha: 0.12),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 54),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.5),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 28),
      ),
    );
  }
}
