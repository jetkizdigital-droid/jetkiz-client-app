import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/menu/presentation/restaurantMenuPage.dart';
import 'package:jetkiz_mobile/features/search/data/searchApi.dart';
import 'package:jetkiz_mobile/features/search/domain/searchResult.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchApi _searchApi;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  String? _error;
  SearchResult _result = const SearchResult(
    restaurants: [],
    products: [],
  );

  @override
  void initState() {
    super.initState();
    _searchApi = SearchApi(ApiClient());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = null;
        _result = const SearchResult(
          restaurants: [],
          products: [],
        );
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _searchApi.search(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Не удалось выполнить поиск';
        _result = const SearchResult(
          restaurants: [],
          products: [],
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();

    setState(() {
      _isLoading = false;
      _error = null;
      _result = const SearchResult(
        restaurants: [],
        products: [],
      );
    });
  }

  void _openRestaurant({
    required String restaurantId,
    required String restaurantName,
  }) {
    if (restaurantId.trim().isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantMenuPage(
          restaurantId: restaurantId,
          restaurantName:
              restaurantName.trim().isEmpty ? 'Ресторан' : restaurantName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final hasQuery = query.isNotEmpty;
    final isEmptyResult = hasQuery &&
        !_isLoading &&
        _error == null &&
        _result.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'Поиск',
          style: TextStyle(
            color: Color(0xFF14181F),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Блюда, напитки, рестораны',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF14181F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_controller.text.trim().isNotEmpty)
                    IconButton(
                      onPressed: _clear,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF7B7F87),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _SearchBody(
              query: query,
              isLoading: _isLoading,
              error: _error,
              result: _result,
              onRestaurantTap: (item) {
                _openRestaurant(
                  restaurantId: item.id,
                  restaurantName: item.name,
                );
              },
              onProductTap: (item) {
                _openRestaurant(
                  restaurantId: item.restaurantId,
                  restaurantName: item.restaurantName,
                );
              },
              isEmptyResult: isEmptyResult,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.query,
    required this.isLoading,
    required this.error,
    required this.result,
    required this.onRestaurantTap,
    required this.onProductTap,
    required this.isEmptyResult,
  });

  final String query;
  final bool isLoading;
  final String? error;
  final SearchResult result;
  final ValueChanged<SearchRestaurantItem> onRestaurantTap;
  final ValueChanged<SearchProductItem> onProductTap;
  final bool isEmptyResult;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return const _SearchHintState();
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _InfoState(
        icon: Icons.cloud_off_rounded,
        title: error!,
        subtitle: 'Проверь подключение и попробуй ещё раз',
      );
    }

    if (isEmptyResult) {
      return const _InfoState(
        icon: Icons.search_off_rounded,
        title: 'Ничего не найдено',
        subtitle: 'Попробуй изменить запрос',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (result.restaurants.isNotEmpty) ...[
          const _SectionTitle(title: 'Рестораны'),
          const SizedBox(height: 10),
          ...result.restaurants.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RestaurantTile(
                item: item,
                onTap: () => onRestaurantTap(item),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (result.products.isNotEmpty) ...[
          const _SectionTitle(title: 'Блюда и напитки'),
          const SizedBox(height: 10),
          ...result.products.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProductTile(
                item: item,
                onTap: () => onProductTap(item),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF14181F),
      ),
    );
  }
}

class _RestaurantTile extends StatelessWidget {
  const _RestaurantTile({
    required this.item,
    required this.onTap,
  });

  final SearchRestaurantItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratingText = item.ratingAvg == 0
        ? '0,0'
        : item.ratingAvg.toStringAsFixed(1).replaceAll('.', ',');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3E6EA)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 76,
                height: 76,
                child: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                    ? Image.network(
                        item.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _ImagePlaceholder(
                          icon: Icons.restaurant_rounded,
                        ),
                      )
                    : const _ImagePlaceholder(
                        icon: Icons.restaurant_rounded,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14181F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.address?.trim().isNotEmpty == true
                        ? item.address!
                        : (item.workingHours?.trim().isNotEmpty == true
                            ? item.workingHours!
                            : 'Открыть меню ресторана'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6E7480),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Color(0xFF4FAF43),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ratingText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14181F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: Color(0xFF97A0AA),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.item,
    required this.onTap,
  });

  final SearchProductItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (item.restaurantName.trim().isNotEmpty) item.restaurantName.trim(),
      if (item.categoryTitle?.trim().isNotEmpty == true) item.categoryTitle!.trim(),
      if (item.isDrink) 'Напиток',
      if (item.weight?.trim().isNotEmpty == true) item.weight!.trim(),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3E6EA)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 76,
                height: 76,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _ImagePlaceholder(
                          icon: Icons.fastfood_rounded,
                        ),
                      )
                    : const _ImagePlaceholder(
                        icon: Icons.fastfood_rounded,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14181F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitleParts.isEmpty
                        ? 'Открыть ресторан'
                        : subtitleParts.join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6E7480),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF97A0AA),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${item.price} ₸',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4FAF43),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: Color(0xFF97A0AA),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF8F3),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 34,
        color: const Color(0xFF489F2A),
      ),
    );
  }
}

class _SearchHintState extends StatelessWidget {
  const _SearchHintState();

  @override
  Widget build(BuildContext context) {
    return const _InfoState(
      icon: Icons.search_rounded,
      title: 'Начни вводить запрос',
      subtitle: 'Можно искать рестораны, блюда и напитки',
    );
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({
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
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 52,
              color: const Color(0xFF97A0AA),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF14181F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7B7F87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}