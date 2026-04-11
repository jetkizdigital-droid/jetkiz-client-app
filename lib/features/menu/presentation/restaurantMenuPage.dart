import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';
import 'package:jetkiz_mobile/features/cart/presentation/widgets/cartSummaryBar.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesApi.dart';
import 'package:jetkiz_mobile/features/menu/data/financeConfigApi.dart';
import 'package:jetkiz_mobile/features/menu/data/restaurantMenuApi.dart';
import 'package:jetkiz_mobile/features/menu/domain/restaurantMenuData.dart';
import 'package:jetkiz_mobile/features/menu/presentation/productDetailsPage.dart';
import 'package:jetkiz_mobile/features/reviews/domain/restaurantReview.dart';
import 'package:jetkiz_mobile/features/reviews/presentation/restaurantReviewsPage.dart';

class RestaurantMenuPage extends StatefulWidget {
  final String restaurantId;
  final String? restaurantName;
  final String? restaurantImageUrl;
  final String? restaurantAddress;

  const RestaurantMenuPage({
    super.key,
    required this.restaurantId,
    this.restaurantName,
    this.restaurantImageUrl,
    this.restaurantAddress,
  });

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

enum _MenuLanguage {
  ru,
  kk,
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  late final RestaurantMenuApi _menuApi;
  late final FinanceConfigApi _financeConfigApi;
  late final FavoritesApi _favoritesApi;
  late final ApiClient _apiClient;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  RestaurantMenuData? _menuData;
  RestaurantReviewPageData? _reviewsData;

  String _searchQuery = '';
  String _selectedTabId = 'all';

  final Set<String> _favoriteProductIds = <String>{};
  final Set<String> _favoritePendingProductIds = <String>{};

  bool _isRestaurantFavorite = false;
  bool _isRestaurantFavoriteLoading = false;
  bool _isRestaurantFavoriteBusy = false;

  _MenuLanguage _menuLanguage = _MenuLanguage.ru;
  int _deliveryFee = 0;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _menuApi = RestaurantMenuApi(_apiClient);
    _financeConfigApi = FinanceConfigApi(_apiClient);
    _favoritesApi = FavoritesApi(_apiClient);
    _load();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<RestaurantReviewPageData> _loadReviewsSummary() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/restaurants/${widget.restaurantId}/reviews',
      queryParameters: const {
        'page': 1,
        'limit': 100,
        'includeUser': true,
        'includeOrder': false,
      },
    );

    final json = response.data ?? const <String, dynamic>{};
    return RestaurantReviewPageData.fromJson(json);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _menuApi.getRestaurantMenu(
          restaurantId: widget.restaurantId,
        ),
        _financeConfigApi.getFinanceConfig(),
        _loadReviewsSummary(),
      ]);

      final data = results[0] as RestaurantMenuData;
      final financeConfig = results[1] as FinanceConfigData;
      final reviewsData = results[2] as RestaurantReviewPageData;

      if (!mounted) return;

      setState(() {
        _menuData = data;
        _reviewsData = reviewsData;
        _selectedTabId = 'all';
        _deliveryFee = financeConfig.activeDeliveryFee;
      });

      await _loadFavoriteIdsSilently();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить меню ресторана';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFavoriteIdsSilently() async {
    if (!mounted) return;

    setState(() {
      _isRestaurantFavoriteLoading = true;
    });

    try {
      final ids = await _favoritesApi.getFavoriteIds();

      if (!mounted) return;

      setState(() {
        _favoriteProductIds
          ..clear()
          ..addAll(ids.productIds);
        _isRestaurantFavorite = ids.restaurantIds.contains(widget.restaurantId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favoriteProductIds.clear();
        _isRestaurantFavorite = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRestaurantFavoriteLoading = false;
        });
      }
    }
  }

  String _allTabTitle() {
    switch (_menuLanguage) {
      case _MenuLanguage.ru:
        return 'Все';
      case _MenuLanguage.kk:
        return 'Барлығы';
    }
  }

  String _searchHint() {
    switch (_menuLanguage) {
      case _MenuLanguage.ru:
        return 'Поиск по меню...';
      case _MenuLanguage.kk:
        return 'Мәзірден іздеу...';
    }
  }

  String _basketItemsLabel() {
    switch (_menuLanguage) {
      case _MenuLanguage.ru:
        return 'В корзине';
      case _MenuLanguage.kk:
        return 'Себетте';
    }
  }

  String _deliveryLabel() {
    switch (_menuLanguage) {
      case _MenuLanguage.ru:
        return 'Доставка';
      case _MenuLanguage.kk:
        return 'Жеткізу';
    }
  }

  String _nextButtonLabel() {
    switch (_menuLanguage) {
      case _MenuLanguage.ru:
        return 'Далее';
      case _MenuLanguage.kk:
        return 'Әрі қарай';
    }
  }

  List<RestaurantMenuGroup> get _allGroups {
    return _menuData?.groupedItems ?? const <RestaurantMenuGroup>[];
  }

  List<RestaurantMenuGroup> get _visibleGroups {
    final groups = _allGroups;

    final filteredByTab = _selectedTabId == 'all'
        ? groups
        : groups.where((group) => group.category.id == _selectedTabId).toList();

    if (_searchQuery.trim().isEmpty) {
      return filteredByTab;
    }

    final query = _searchQuery.trim().toLowerCase();
    final result = <RestaurantMenuGroup>[];

    for (final group in filteredByTab) {
      final items = group.items.where((item) {
        final haystack = [
          item.titleRu,
          item.titleKk,
          item.composition,
          item.description,
          item.weight,
          item.categoryNameRu,
          item.categoryNameKk,
        ].whereType<String>().join(' ').toLowerCase();

        return haystack.contains(query);
      }).toList();

      if (items.isNotEmpty) {
        result.add(
          RestaurantMenuGroup(
            category: group.category,
            items: items,
          ),
        );
      }
    }

    return result;
  }

  int _getQuantity(String productId) {
    return CartRepository.instance.quantityOf(productId);
  }

  void _addFirst(RestaurantMenuItem item) {
    CartRepository.instance.addItem(
      productId: item.id,
      restaurantId: widget.restaurantId,
      title: item.title,
      price: item.price,
      quantity: 1,
      imageUrl: item.mainImageUrl,
      description: item.description,
      weight: item.weight,
    );

    setState(() {});
  }

  void _increment(RestaurantMenuItem item) {
    CartRepository.instance.addItem(
      productId: item.id,
      restaurantId: widget.restaurantId,
      title: item.title,
      price: item.price,
      quantity: 1,
      imageUrl: item.mainImageUrl,
      description: item.description,
      weight: item.weight,
    );

    setState(() {});
  }

  void _decrement(RestaurantMenuItem item) {
    CartRepository.instance.decrement(item.id);
    setState(() {});
  }

  Future<void> _toggleRestaurantFavorite() async {
    if (_isRestaurantFavoriteBusy || _isRestaurantFavoriteLoading) {
      return;
    }

    final wasFavorite = _isRestaurantFavorite;

    setState(() {
      _isRestaurantFavoriteBusy = true;
      _isRestaurantFavorite = !wasFavorite;
    });

    try {
      if (wasFavorite) {
        await _favoritesApi.removeRestaurantFavorite(widget.restaurantId);
      } else {
        await _favoritesApi.addRestaurantFavorite(widget.restaurantId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRestaurantFavorite = wasFavorite;
      });
      _showFavoriteError(
        wasFavorite
            ? 'Не удалось удалить ресторан из избранного'
            : 'Не удалось добавить ресторан в избранное',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestaurantFavoriteBusy = false;
        });
      }
    }
  }

  Future<void> _toggleProductFavorite(String productId) async {
    if (_favoritePendingProductIds.contains(productId)) {
      return;
    }

    final wasFavorite = _favoriteProductIds.contains(productId);

    setState(() {
      _favoritePendingProductIds.add(productId);
      if (wasFavorite) {
        _favoriteProductIds.remove(productId);
      } else {
        _favoriteProductIds.add(productId);
      }
    });

    try {
      if (wasFavorite) {
        await _favoritesApi.removeProductFavorite(productId);
      } else {
        await _favoritesApi.addProductFavorite(productId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favoriteProductIds.add(productId);
        } else {
          _favoriteProductIds.remove(productId);
        }
      });
      _showFavoriteError(
        wasFavorite
            ? 'Не удалось удалить блюдо из избранного'
            : 'Не удалось добавить блюдо в избранное',
      );
    } finally {
      if (mounted) {
        setState(() {
          _favoritePendingProductIds.remove(productId);
        });
      }
    }
  }

  void _showFavoriteError(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openProductDetails(RestaurantMenuItem item) {
    final restaurantName =
        _menuData?.restaurant.displayName ?? widget.restaurantName;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: item,
          restaurantName: restaurantName,
          restaurantId: widget.restaurantId,
        ),
      ),
    );
  }

  int get _basketItemsCount {
    return CartRepository.instance.totalQuantity;
  }

  int get _basketTotal {
    return CartRepository.instance.subtotal;
  }

  String get _restaurantName {
    final data = _menuData;
    if (data == null) {
      return widget.restaurantName ?? 'Ресторан';
    }

    final name = data.restaurant.displayName.trim();
    if (name.isNotEmpty) {
      return name;
    }

    return widget.restaurantName ?? 'Ресторан';
  }

  String? get _restaurantImageUrl {
    final dynamic restaurant = _menuData?.restaurant;

    final raw = _firstNonEmpty([
      widget.restaurantImageUrl,
      _readDynamicString(restaurant, 'coverImageUrl'),
      _readDynamicString(restaurant, 'fullCoverImageUrl'),
      _readDynamicString(restaurant, 'imageUrl'),
      _readDynamicString(restaurant, 'fullImageUrl'),
      _readDynamicString(restaurant, 'photoUrl'),
      _readDynamicString(restaurant, 'avatarUrl'),
      _readDynamicString(restaurant, 'logoUrl'),
    ]);

    return _normalizeUrl(raw);
  }

  String get _restaurantDescription {
    final dynamic restaurant = _menuData?.restaurant;

    return _firstNonEmpty([
          _readDynamicString(restaurant, 'description'),
          _readDynamicString(restaurant, 'descriptionRu'),
          _readDynamicString(restaurant, 'subtitle'),
          _readDynamicString(restaurant, 'tagline'),
          _readDynamicString(restaurant, 'shortDescription'),
        ]) ??
        'Лучшие блюда с доставкой на дом';
  }

  String get _restaurantRatingText {
    final dynamic restaurant = _menuData?.restaurant;

    final raw = _firstNonEmpty([
      _readDynamicString(restaurant, 'ratingAvg'),
      _readDynamicString(restaurant, 'rating'),
    ]);

    if (raw == null) return '4.9';

    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) return raw;

    return parsed.toStringAsFixed(1);
  }

  String get _restaurantDeliveryText {
    final dynamic restaurant = _menuData?.restaurant;

    return _firstNonEmpty([
          _readDynamicString(restaurant, 'deliveryTime'),
          _readDynamicString(restaurant, 'deliveryEta'),
          _readDynamicString(restaurant, 'estimatedDeliveryTime'),
          _readDynamicString(restaurant, 'deliveryDuration'),
        ]) ??
        '30–35 мин';
  }

  String get _restaurantAddressText {
    final dynamic restaurant = _menuData?.restaurant;

    return _firstNonEmpty([
          _readDynamicString(restaurant, 'address'),
          _readDynamicString(restaurant, 'addressLine'),
          _readDynamicString(restaurant, 'fullAddress'),
          widget.restaurantAddress,
        ]) ??
        'Адрес уточняется';
  }

  int get _reviewsCount => _reviewsData?.total ?? 0;

  int get _videoReviewsCount {
    final data = _reviewsData;
    if (data == null) return 0;

    var count = 0;
    for (final review in data.items) {
      for (final media in review.media) {
        if (media.isVideo) count++;
      }
    }
    return count;
  }

  int get _photoReviewsCount {
    final data = _reviewsData;
    if (data == null) return 0;

    var count = 0;
    for (final review in data.items) {
      for (final media in review.media) {
        if (media.isImage) count++;
      }
    }
    return count;
  }

  int get _audioReviewsCount {
    final data = _reviewsData;
    if (data == null) return 0;

    var count = 0;
    for (final review in data.items) {
      for (final media in review.media) {
        if (media.isAudio) count++;
      }
    }
    return count;
  }

  void _onReviewsTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantReviewsPage(
          restaurantId: widget.restaurantId,
          restaurantName: _restaurantName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuData = _menuData;
    final groups = _visibleGroups;
    final hasBasket = _basketItemsCount > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _RestaurantMenuErrorState(
                    message: _error!,
                    onRetry: _load,
                  )
                : menuData == null
                    ? _RestaurantMenuErrorState(
                        message: 'Меню ресторана не найдено',
                        onRetry: _load,
                      )
                    : ScrollConfiguration(
                        behavior: const _SmoothScrollBehavior(),
                        child: CustomScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverAppBar(
                              pinned: true,
                              automaticallyImplyLeading: false,
                              backgroundColor: const Color(0xFFF7F7F7),
                              surfaceTintColor: const Color(0xFFF7F7F7),
                              expandedHeight: 160,
                              collapsedHeight: 56,
                              elevation: 0,
                              flexibleSpace: LayoutBuilder(
                                builder: (context, constraints) {
                                  final top = MediaQuery.of(context).padding.top;
                                  final maxHeight = 160 + top;
                                  final collapseT =
                                      ((maxHeight - constraints.maxHeight) /
                                              (160 - 56))
                                          .clamp(0.0, 1.0);

                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Transform.translate(
                                        offset: Offset(0, -20 * collapseT),
                                        child: _HeroImageLayer(
                                          imageUrl: _restaurantImageUrl,
                                        ),
                                      ),
                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0x2E000000),
                                              Color(0x0A000000),
                                              Color(0x3D000000),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: top + 6,
                                        left: 14,
                                        child: _HeaderCircleButton(
                                          onTap: () {
                                            Navigator.of(context).maybePop();
                                          },
                                          child: const Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            color: Colors.black87,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: top + 6,
                                        right: 14,
                                        child: _HeaderCircleButton(
                                          onTap: (_isRestaurantFavoriteBusy ||
                                                  _isRestaurantFavoriteLoading)
                                              ? null
                                              : _toggleRestaurantFavorite,
                                          child: (_isRestaurantFavoriteBusy ||
                                                  _isRestaurantFavoriteLoading)
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Icon(
                                                  _isRestaurantFavorite
                                                      ? Icons.favorite_rounded
                                                      : Icons
                                                          .favorite_border_rounded,
                                                  color: _isRestaurantFavorite
                                                      ? Colors.redAccent
                                                      : Colors.black87,
                                                  size: 21,
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 60,
                                        right: 60,
                                        top: top + 14,
                                        child: IgnorePointer(
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 120,
                                            ),
                                            opacity: collapseT > 0.55 ? 1 : 0,
                                            child: Text(
                                              _restaurantName,
                                              maxLines: 1,
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1E1E1E),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _FixedHeaderDelegate(
                                height: 142,
                                child: Container(
                                  color: const Color(0xFFF7F7F7),
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 10),
                                  child: _RestaurantInfoCard(
                                    restaurantName: _restaurantName,
                                    restaurantDescription:
                                        _restaurantDescription,
                                    ratingText: _restaurantRatingText,
                                    deliveryText: _restaurantDeliveryText,
                                    addressText: _restaurantAddressText,
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: _ReviewsSummaryCard(
                                  reviewsCount: _reviewsCount,
                                  videoReviewsCount: _videoReviewsCount,
                                  photoReviewsCount: _photoReviewsCount,
                                  audioReviewsCount: _audioReviewsCount,
                                  onTap: _onReviewsTap,
                                ),
                              ),
                            ),
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _FixedHeaderDelegate(
                                height: 56,
                                child: Container(
                                  color: const Color(0xFFF7F7F7),
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: _MenuSearchField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    hintText: _searchHint(),
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _FixedHeaderDelegate(
                                height: 46,
                                child: Container(
                                  color: const Color(0xFFF7F7F7),
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: _CategoriesStrip(
                                    groups: _allGroups,
                                    selectedTabId: _selectedTabId,
                                    allTabTitle: _allTabTitle(),
                                    onTabSelected: (tabId) {
                                      setState(() {
                                        _selectedTabId = tabId;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (groups.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: _MenuEmptyState(),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  hasBasket ? 190 : 32,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: groups.length,
                                  itemBuilder: (context, groupIndex) {
                                    final group = groups[groupIndex];

                                    return _MenuCategorySection(
                                      title: group.category.title,
                                      showTitle: _selectedTabId == 'all',
                                      items: group.items,
                                      favoriteProductIds: _favoriteProductIds,
                                      favoritePendingProductIds:
                                          _favoritePendingProductIds,
                                      getQuantity: _getQuantity,
                                      onProductTap: _openProductDetails,
                                      onFavoriteTap: _toggleProductFavorite,
                                      onAddFirst: (productId) {
                                        final item = group.items.firstWhere(
                                          (x) => x.id == productId,
                                        );
                                        _addFirst(item);
                                      },
                                      onAdd: (productId) {
                                        final item = group.items.firstWhere(
                                          (x) => x.id == productId,
                                        );
                                        _increment(item);
                                      },
                                      onRemove: (productId) {
                                        final item = group.items.firstWhere(
                                          (x) => x.id == productId,
                                        );
                                        _decrement(item);
                                      },
                                    );
                                  },
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 18),
                                ),
                              ),
                          ],
                        ),
                      ),
      ),
      bottomNavigationBar: hasBasket
          ? CartSummaryBar(
              itemsCount: _basketItemsCount,
              itemsTotal: _basketTotal,
              deliveryFee: _deliveryFee,
              deliveryLabel: _deliveryLabel(),
              basketLabelPrefix: _basketItemsLabel(),
              nextButtonLabel: _nextButtonLabel(),
              onNextTap: () {
                Navigator.of(context).pushNamed('/cart');
              },
            )
          : null,
    );
  }
}

class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FixedHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _FixedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _CategoriesStrip extends StatelessWidget {
  const _CategoriesStrip({
    required this.groups,
    required this.selectedTabId,
    required this.allTabTitle,
    required this.onTabSelected,
  });

  final List<RestaurantMenuGroup> groups;
  final String selectedTabId;
  final String allTabTitle;
  final ValueChanged<String> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ScrollConfiguration(
        behavior: const _SmoothScrollBehavior(),
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            _MenuCategoryChip(
              title: allTabTitle,
              isSelected: selectedTabId == 'all',
              onTap: () => onTabSelected('all'),
            ),
            const SizedBox(width: 8),
            ...groups.expand((group) {
              return [
                _MenuCategoryChip(
                  title: group.category.title,
                  isSelected: selectedTabId == group.category.id,
                  onTap: () => onTabSelected(group.category.id),
                ),
                const SizedBox(width: 8),
              ];
            }),
          ],
        ),
      ),
    );
  }
}

class _RestaurantHeroHeader extends StatelessWidget {
  const _RestaurantHeroHeader({
    required this.imageUrl,
    required this.onBackTap,
    required this.onFavoriteTap,
    required this.isRestaurantFavorite,
    required this.isRestaurantFavoriteBusy,
  });

  final String? imageUrl;
  final VoidCallback onBackTap;
  final VoidCallback onFavoriteTap;
  final bool isRestaurantFavorite;
  final bool isRestaurantFavoriteBusy;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HeroImageLayer(imageUrl: imageUrl),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x2E000000),
                  Color(0x0A000000),
                  Color(0x3D000000),
                ],
              ),
            ),
          ),
          Positioned(
            top: topInset + 6,
            left: 14,
            child: _HeaderCircleButton(
              onTap: onBackTap,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black87,
                size: 18,
              ),
            ),
          ),
          Positioned(
            top: topInset + 6,
            right: 14,
            child: _HeaderCircleButton(
              onTap: isRestaurantFavoriteBusy ? null : onFavoriteTap,
              child: isRestaurantFavoriteBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isRestaurantFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isRestaurantFavorite
                          ? Colors.redAccent
                          : Colors.black87,
                      size: 21,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImageLayer extends StatelessWidget {
  const _HeroImageLayer({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeUrl(imageUrl);

    if (normalized == null || normalized.isEmpty) {
      return const _RestaurantHeroPlaceholder();
    }

    return Image.network(
      normalized,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: frame != null ? child : const _RestaurantHeroPlaceholder(),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _RestaurantHeroPlaceholder();
      },
      errorBuilder: (_, __, ___) {
        return const _RestaurantHeroPlaceholder();
      },
    );
  }
}

class _RestaurantHeroPlaceholder extends StatelessWidget {
  const _RestaurantHeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8E8E8),
            Color(0xFFD6D6D6),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_rounded,
        size: 48,
        color: Colors.black45,
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF2FFFFFF),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RestaurantInfoCard extends StatelessWidget {
  const _RestaurantInfoCard({
    required this.restaurantName,
    required this.restaurantDescription,
    required this.ratingText,
    required this.deliveryText,
    required this.addressText,
  });

  final String restaurantName;
  final String restaurantDescription;
  final String ratingText;
  final String deliveryText;
  final String addressText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E1E),
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F5E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFF489F2A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ratingText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF489F2A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            restaurantDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6D6D6D),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniMetaItem(
                icon: Icons.access_time_rounded,
                text: deliveryText,
              ),
              _MiniMetaItem(
                icon: Icons.location_on_outlined,
                text: addressText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetaItem extends StatelessWidget {
  const _MiniMetaItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFF808080),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF808080),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSummaryCard extends StatelessWidget {
  const _ReviewsSummaryCard({
    required this.reviewsCount,
    required this.videoReviewsCount,
    required this.photoReviewsCount,
    required this.audioReviewsCount,
    required this.onTap,
  });

  final int reviewsCount;
  final int videoReviewsCount;
  final int photoReviewsCount;
  final int audioReviewsCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5EA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Отзывы ($reviewsCount)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _ReviewStat(
                        icon: Icons.videocam_outlined,
                        value: videoReviewsCount,
                      ),
                      _ReviewStat(
                        icon: Icons.photo_camera_outlined,
                        value: photoReviewsCount,
                      ),
                      _ReviewStat(
                        icon: Icons.mic_none_rounded,
                        value: audioReviewsCount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF5A5A5A),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewStat extends StatelessWidget {
  const _ReviewStat({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF5A5A5A),
        ),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5A5A5A),
          ),
        ),
      ],
    );
  }
}

class _MenuSearchField extends StatelessWidget {
  const _MenuSearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9A9A9A),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9A9A9A),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: const Color(0xFFF2F2F2),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF489F2A),
              width: 1.2,
            ),
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _MenuCategoryChip extends StatelessWidget {
  const _MenuCategoryChip({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFECECEC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF555555),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCategorySection extends StatelessWidget {
  const _MenuCategorySection({
    required this.title,
    required this.showTitle,
    required this.items,
    required this.favoriteProductIds,
    required this.favoritePendingProductIds,
    required this.getQuantity,
    required this.onProductTap,
    required this.onFavoriteTap,
    required this.onAddFirst,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final bool showTitle;
  final List<RestaurantMenuItem> items;
  final Set<String> favoriteProductIds;
  final Set<String> favoritePendingProductIds;
  final int Function(String productId) getQuantity;
  final void Function(RestaurantMenuItem item) onProductTap;
  final Future<void> Function(String productId) onFavoriteTap;
  final void Function(String productId) onAddFirst;
  final void Function(String productId) onAdd;
  final void Function(String productId) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.0,
              ),
            ),
          ),
        ],
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final productId = item.id;

            return _MenuProductCard(
              item: item,
              quantity: getQuantity(productId),
              isFavorite: favoriteProductIds.contains(productId),
              isFavoriteBusy: favoritePendingProductIds.contains(productId),
              onTap: () => onProductTap(item),
              onFavoriteTap: () => onFavoriteTap(productId),
              onAddFirst: () => onAddFirst(productId),
              onAdd: () => onAdd(productId),
              onRemove: () => onRemove(productId),
            );
          },
        ),
      ],
    );
  }
}

class _MenuProductCard extends StatelessWidget {
  const _MenuProductCard({
    required this.item,
    required this.quantity,
    required this.isFavorite,
    required this.isFavoriteBusy,
    required this.onTap,
    required this.onFavoriteTap,
    required this.onAddFirst,
    required this.onAdd,
    required this.onRemove,
  });

  final RestaurantMenuItem item;
  final int quantity;
  final bool isFavorite;
  final bool isFavoriteBusy;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddFirst;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isAvailable = item.isAvailable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _MenuProductImage(item: item),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: isFavoriteBusy ? null : onFavoriteTap,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: isFavoriteBusy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFavorite ? Colors.red : Colors.black,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                  ),
                  if (!isAvailable)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xB3000000),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Недоступно',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    if ((item.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF5F5F5F),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      '${item.price}₸',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isAvailable)
                    const SizedBox.shrink()
                  else if (quantity > 0)
                    _MenuQuantityControl(
                      quantity: quantity,
                      onAdd: onAdd,
                      onRemove: onRemove,
                    )
                  else
                    _CompactAddButton(
                      onTap: onAddFirst,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuProductImage extends StatelessWidget {
  const _MenuProductImage({
    required this.item,
  });

  final RestaurantMenuItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _normalizeUrl(item.mainImageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) {
                  return const _MenuImagePlaceholder();
                },
              )
            : const _MenuImagePlaceholder(),
      ),
    );
  }
}

class _MenuImagePlaceholder extends StatelessWidget {
  const _MenuImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F4F4),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 42,
        color: Colors.black54,
      ),
    );
  }
}

class _CompactAddButton extends StatelessWidget {
  const _CompactAddButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 74,
        height: 36,
        decoration: ShapeDecoration(
          color: const Color(0xFF489F2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _MenuQuantityControl extends StatelessWidget {
  const _MenuQuantityControl({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF489F2A),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove_rounded,
            onTap: onRemove,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add_rounded,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _MenuEmptyState extends StatelessWidget {
  const _MenuEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Color(0xFFB0B0B0),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ничего не найдено',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Попробуй изменить поиск или выбрать другую категорию.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF6D6D6D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantMenuErrorState extends StatelessWidget {
  const _RestaurantMenuErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: Colors.black45,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF489F2A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmoothScrollBehavior extends ScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

String? _normalizeUrl(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;

  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }

  final base = AppConfig.baseUrl.trim();
  if (base.isEmpty) return raw;

  if (raw.startsWith('/')) {
    if (base.endsWith('/')) {
      return '${base.substring(0, base.length - 1)}$raw';
    }
    return '$base$raw';
  }

  if (base.endsWith('/')) {
    return '$base$raw';
  }

  return '$base/$raw';
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

String? _readDynamicString(dynamic source, String field) {
  if (source == null) return null;

  if (source is Map) {
    final direct = source[field];
    if (direct != null) {
      final value = direct.toString().trim();
      if (value.isNotEmpty) return value;
    }
  }

  try {
    switch (field) {
      case 'coverImageUrl':
        return source.coverImageUrl?.toString();
      case 'fullCoverImageUrl':
        return source.fullCoverImageUrl?.toString();
      case 'imageUrl':
        return source.imageUrl?.toString();
      case 'fullImageUrl':
        return source.fullImageUrl?.toString();
      case 'photoUrl':
        return source.photoUrl?.toString();
      case 'avatarUrl':
        return source.avatarUrl?.toString();
      case 'logoUrl':
        return source.logoUrl?.toString();
      case 'description':
        return source.description?.toString();
      case 'descriptionRu':
        return source.descriptionRu?.toString();
      case 'subtitle':
        return source.subtitle?.toString();
      case 'tagline':
        return source.tagline?.toString();
      case 'shortDescription':
        return source.shortDescription?.toString();
      case 'ratingAvg':
        return source.ratingAvg?.toString();
      case 'rating':
        return source.rating?.toString();
      case 'deliveryTime':
        return source.deliveryTime?.toString();
      case 'deliveryEta':
        return source.deliveryEta?.toString();
      case 'estimatedDeliveryTime':
        return source.estimatedDeliveryTime?.toString();
      case 'deliveryDuration':
        return source.deliveryDuration?.toString();
      case 'address':
        return source.address?.toString();
      case 'addressLine':
        return source.addressLine?.toString();
      case 'fullAddress':
        return source.fullAddress?.toString();
      case 'reviewsCount':
        return source.reviewsCount?.toString();
      case 'reviewCount':
        return source.reviewCount?.toString();
      case 'ratingCount':
        return source.ratingCount?.toString();
      case 'videoReviewsCount':
        return source.videoReviewsCount?.toString();
      case 'reviewVideoCount':
        return source.reviewVideoCount?.toString();
      case 'photoReviewsCount':
        return source.photoReviewsCount?.toString();
      case 'reviewPhotoCount':
        return source.reviewPhotoCount?.toString();
      case 'audioReviewsCount':
        return source.audioReviewsCount?.toString();
      case 'reviewAudioCount':
        return source.reviewAudioCount?.toString();
    }
  } catch (_) {
    return null;
  }

  return null;
}