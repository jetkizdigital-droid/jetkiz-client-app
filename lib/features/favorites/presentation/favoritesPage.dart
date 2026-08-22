import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesApi.dart';
import 'package:jetkiz_mobile/features/favorites/domain/favorite_models.dart';
import 'package:jetkiz_mobile/features/menu/presentation/restaurantMenuPage.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final FavoritesApi _favoritesApi;

  bool _isInitialLoading = true;
  bool _isRestaurantsLoading = false;
  bool _isProductsLoading = false;

  bool _restaurantsLoaded = false;
  bool _productsLoaded = false;

  String? _restaurantsError;
  String? _productsError;

  List<FavoriteRestaurantRecord> _restaurants = const [];
  List<FavoriteProductRecord> _products = const [];

  final Set<String> _restaurantBusyIds = <String>{};
  final Set<String> _productBusyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _favoritesApi = FavoritesApi(ApiClient());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _loadInitial();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;

    if (_tabController.index == 1 && !_productsLoaded && !_isProductsLoading) {
      _loadProducts();
    }
  }

  Future<void> _loadInitial() async {
    if (!mounted) return;

    setState(() {
      _isInitialLoading = true;
      _restaurantsError = null;
    });

    try {
      await _loadRestaurants();
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadRestaurants() async {
    if (!mounted || _isRestaurantsLoading) return;

    setState(() {
      _isRestaurantsLoading = true;
      _restaurantsError = null;
    });

    try {
      final response = await _favoritesApi.getFavoriteRestaurants();

      if (!mounted) return;

      setState(() {
        _restaurants = response.items;
        _restaurantsLoaded = true;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _restaurantsError = _favoritesApi.extractMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _restaurantsError = 'Не удалось загрузить избранные рестораны';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isRestaurantsLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted || _isProductsLoading) return;

    setState(() {
      _isProductsLoading = true;
      _productsError = null;
    });

    try {
      final response = await _favoritesApi.getFavoriteProducts();

      if (!mounted) return;

      setState(() {
        _products = response.items;
        _productsLoaded = true;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _productsError = _favoritesApi.extractMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _productsError = 'Не удалось загрузить избранные блюда';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProductsLoading = false;
      });
    }
  }

  Future<void> _refreshRestaurants() async {
    await _loadRestaurants();
  }

  Future<void> _refreshProducts() async {
    await _loadProducts();
  }

  Future<void> _removeRestaurant(String restaurantId) async {
    if (_restaurantBusyIds.contains(restaurantId)) return;

    setState(() {
      _restaurantBusyIds.add(restaurantId);
    });

    try {
      await _favoritesApi.removeRestaurantFavorite(restaurantId);

      if (!mounted) return;

      setState(() {
        _restaurants =
            _restaurants.where((x) => x.restaurant.id != restaurantId).toList();
      });

      _showSnack('Ресторан удалён из избранного');
    } on DioException catch (e) {
      _showSnack(_favoritesApi.extractMessage(e));
    } catch (_) {
      _showSnack('Не удалось удалить ресторан из избранного');
    } finally {
      if (!mounted) return;
      setState(() {
        _restaurantBusyIds.remove(restaurantId);
      });
    }
  }

  Future<void> _removeProduct(String productId) async {
    if (_productBusyIds.contains(productId)) return;

    setState(() {
      _productBusyIds.add(productId);
    });

    try {
      await _favoritesApi.removeProductFavorite(productId);

      if (!mounted) return;

      setState(() {
        _products = _products.where((x) => x.product.id != productId).toList();
      });

      _showSnack('Блюдо удалено из избранного');
    } on DioException catch (e) {
      _showSnack(_favoritesApi.extractMessage(e));
    } catch (_) {
      _showSnack('Не удалось удалить блюдо из избранного');
    } finally {
      if (!mounted) return;
      setState(() {
        _productBusyIds.remove(productId);
      });
    }
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildRestaurantsTab() {
    if (_restaurantsError != null && !_restaurantsLoaded) {
      return _ErrorView(
        message: _restaurantsError!,
        onRetry: _loadRestaurants,
      );
    }

    if (_isRestaurantsLoading && !_restaurantsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_restaurants.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshRestaurants,
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
      onRefresh: _refreshRestaurants,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _restaurants[index];
          final busy = _restaurantBusyIds.contains(item.restaurant.id);

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
    if (_productsError != null && !_productsLoaded) {
      return _ErrorView(
        message: _productsError!,
        onRetry: _loadProducts,
      );
    }

    if (_isProductsLoading && !_productsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_productsLoaded) {
      return const Center(
        child: Text(
          'Открой вкладку, чтобы загрузить блюда',
          style: TextStyle(fontSize: 15),
        ),
      );
    }

    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshProducts,
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
      onRefresh: _refreshProducts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _products[index];
          final busy = _productBusyIds.contains(item.product.id);

          return _ProductFavoriteCard(
            item: item,
            isBusy: busy,
            onRemove: () => _removeProduct(item.product.id),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Рестораны (${_restaurants.length})'),
            Tab(text: 'Блюда (${_products.length})'),
          ],
        ),
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRestaurantsTab(),
                _buildProductsTab(),
              ],
            ),
      backgroundColor: theme.scaffoldBackgroundColor,
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
                        icon: Icons.circle,
                        text: restaurant.status,
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
    required this.onRemove,
  });

  final FavoriteProductRecord item;
  final bool isBusy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final imageUrl = product.effectiveImageUrl ?? product.imageUrl;
    final priceText = '${product.price} ₸';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
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
                          if (!product.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.orange.withOpacity(0.12),
                              ),
                              child: const Text(
                                'Недоступно',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
            ],
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
            .withOpacity(0.7),
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
          .withOpacity(0.5),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 28),
      ),
    );
  }
}
