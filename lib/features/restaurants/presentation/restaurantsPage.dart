/*
  RestaurantsPage

  Экран полного списка ресторанов Jetkiz mobile.

  Контекст для будущих сессий ChatGPT:
  - Экран подключён к реальному backend endpoint:
      GET /restaurants/public/list
  - Используется backend-first подход.
  - На этом экране показывается только полный список ресторанов:
      response.items
  - pinned рестораны НЕ показываются отдельным блоком,
    потому что pinned уже используются на HomePage.
  - Экран поддерживает:
      - случайный порядок списка
      - локальный поиск по названию и адресу
      - pull-to-refresh
  - При нажатии на карточку открывается RestaurantMenuPage.
  - Для Android development используется:
      adb reverse tcp:3001 tcp:3001
*/

import 'dart:math';

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
  late final RestaurantsApi _restaurantsApi;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorText;

  List<Restaurant> _allRestaurants = const [];
  List<Restaurant> _shuffledRestaurants = const [];

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
      final response = await _restaurantsApi.getPublicRestaurants();

      if (!mounted) return;

      final items = List<Restaurant>.from(response.items);
      final shuffled = List<Restaurant>.from(items)..shuffle(Random());

      setState(() {
        _allRestaurants = items;
        _shuffledRestaurants = shuffled;
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
      return _shuffledRestaurants;
    }

    return _shuffledRestaurants.where((restaurant) {
      final name = restaurant.displayName.toLowerCase();
      final address = (restaurant.address ?? '').toLowerCase();
      return name.contains(q) || address.contains(q);
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
      appBar: AppBar(
        title: const Text('Все рестораны'),
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
                const SizedBox(height: 16),
                if (_allRestaurants.isEmpty)
                  const _PageEmpty(
                    text: 'Список ресторанов пока пуст',
                  )
                else if (restaurants.isEmpty)
                  const _PageEmpty(
                    text: 'По вашему запросу рестораны не найдены',
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDADDE2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Color(0xFF7B7F87),
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
                  color: Color(0xFF7B7F87),
                ),
              ),
            ),
        ],
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _RestaurantImage(imageUrl: imageUrl),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white.withOpacity(0.92),
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
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      restaurant.subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _InfoChip(
                          text: restaurant.isOpen ? 'Открыто' : 'Закрыто',
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          text:
                              'Рейтинг ${restaurant.ratingAvg.toStringAsFixed(1)}',
                        ),
                      ],
                    ),
                    if ((restaurant.workingHours ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Часы работы: ${restaurant.workingHours}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF777777),
                        ),
                      ),
                    ],
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

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F4F4),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.restaurant,
          size: 40,
          color: Color(0xFF9E9E9E),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Image.network(
        imageUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
            width: double.infinity,
            color: const Color(0xFFF4F4F4),
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Color(0xFF9E9E9E),
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
      children: [
        const SizedBox(height: 180),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PageEmpty extends StatelessWidget {
  const _PageEmpty({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}