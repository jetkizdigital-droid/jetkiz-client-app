/*
  RestaurantsPage

  Экран полного списка ресторанов Jetkiz mobile.

  Backend-first contract:
  - This screen uses:
      GET /restaurants/public/all?random=1
  - HomePage uses:
      GET /restaurants/public/list?random=1
  - Do not use GET /restaurants for mobile client.
*/

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/favorites/presentation/widgets/favoriteRestaurantButton.dart';
import 'package:jetkiz_mobile/features/menu/presentation/restaurantMenuPage.dart';
import 'package:jetkiz_mobile/features/restaurants/data/restaurantsApi.dart';
import 'package:jetkiz_mobile/features/restaurants/domain/restaurant.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  static const Color _green = Color(0xFF489F2A);
  static const Color _bg = Color(0xFFF7FAF5);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  late final RestaurantsApi _restaurantsApi;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorText;

  List<Restaurant> _restaurants = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();

    _restaurantsApi = RestaurantsApi(ApiClient());
    _searchController.addListener(_handleSearchChanged);

    _loadRestaurants();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();

    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();

    if (nextQuery == _query) return;

    setState(() {
      _query = nextQuery;
    });
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final items = await _restaurantsApi.getAllPublicRestaurants();

      if (!mounted) return;

      setState(() {
        _restaurants = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Не удалось загрузить рестораны';
        _isLoading = false;
      });
    }
  }

  List<Restaurant> get _filteredRestaurants {
    final q = _query.trim().toLowerCase();

    if (q.isEmpty) {
      return _restaurants;
    }

    return _restaurants.where((restaurant) {
      final name = restaurant.displayName.toLowerCase();
      final address = (restaurant.address ?? '').toLowerCase();
      final description = restaurant.displayDescription.toLowerCase();

      return name.contains(q) || address.contains(q) || description.contains(q);
    }).toList();
  }

  void _openRestaurant(Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantMenuPage(
          restaurantId: restaurant.id,
          restaurantName: restaurant.displayName,
          restaurantImageUrl: restaurant.fullCoverImageUrl,
          restaurantAddress: restaurant.address,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = _filteredRestaurants;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Все рестораны',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRestaurants,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const _PageLoader();
            }

            if (_errorText != null) {
              return _PageError(
                text: _errorText!,
                onRetry: _loadRestaurants,
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _SearchBox(
                  controller: _searchController,
                  query: _query,
                ),
                const SizedBox(height: 14),
                _ResultHeader(
                  totalCount: _restaurants.length,
                  visibleCount: restaurants.length,
                  query: _query,
                ),
                const SizedBox(height: 14),
                if (_restaurants.isEmpty)
                  const _PageEmpty(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'Рестораны пока не добавлены',
                    text: 'Список ресторанов появится здесь после публикации.',
                  )
                else if (restaurants.isEmpty)
                  const _PageEmpty(
                    icon: Icons.search_off_rounded,
                    title: 'Ничего не найдено',
                    text: 'Попробуйте изменить запрос.',
                  )
                else
                  ...restaurants.map(
                    (restaurant) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RestaurantCard(
                        restaurant: restaurant,
                        onTap: () => _openRestaurant(restaurant),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = restaurant.fullCoverImageUrl;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _RestaurantImage(imageUrl: imageUrl),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _StatusBadge(
                      isOpen: restaurant.isOpen,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white.withOpacity(0.94),
                      shape: const CircleBorder(),
                      elevation: 1,
                      child: FavoriteRestaurantButton(
                        restaurantId: restaurant.id,
                        iconSize: 22,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      restaurant.displayDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.access_time_rounded,
                          text: restaurant.subtitle,
                        ),
                        _InfoChip(
                          icon: Icons.star_rounded,
                          text: restaurant.hasRating
                              ? '${restaurant.ratingText} · ${restaurant.ratingCount}'
                              : 'Нет рейтинга',
                        ),
                        if (restaurant.formattedDeliveryFee != null)
                          _InfoChip(
                            icon: Icons.delivery_dining_rounded,
                            text: restaurant.formattedDeliveryFee!,
                          ),
                        if (restaurant.formattedMinOrderAmount != null)
                          _InfoChip(
                            icon: Icons.receipt_long_outlined,
                            text: restaurant.formattedMinOrderAmount!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.query,
  });

  final TextEditingController controller;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Поиск ресторанов',
                border: InputBorder.none,
                isCollapsed: true,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (query.isNotEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: controller.clear,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.totalCount,
    required this.visibleCount,
    required this.query,
  });

  final int totalCount;
  final int visibleCount;
  final String query;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Text(
            hasQuery ? 'Найдено: $visibleCount' : 'Ресторанов: $totalCount',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (hasQuery)
          Text(
            'по запросу “${query.trim()}”',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return const _RestaurantImagePlaceholder();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Image.network(
        imageUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const _RestaurantImagePlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return const _RestaurantImagePlaceholder(
            showLoader: true,
          );
        },
      ),
    );
  }
}

class _RestaurantImagePlaceholder extends StatelessWidget {
  const _RestaurantImagePlaceholder({
    this.showLoader = false,
  });

  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(
              Icons.restaurant_rounded,
              size: 42,
              color: Color(0xFF9CA3AF),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isOpen,
  });

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final text = isOpen ? 'Открыто' : 'Закрыто';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
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
    final value = text.trim();

    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageLoader extends StatelessWidget {
  const _PageLoader();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 220),
        Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }
}

class _PageError extends StatelessWidget {
  const _PageError({
    required this.text,
    required this.onRetry,
  });

  final String text;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.wifi_off_rounded,
          size: 54,
          color: Color(0xFFDC2626),
        ),
        const SizedBox(height: 16),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF489F2A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Повторить'),
          ),
        ),
      ],
    );
  }
}

class _PageEmpty extends StatelessWidget {
  const _PageEmpty({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
      child: Column(
        children: [
          Icon(
            icon,
            size: 58,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
