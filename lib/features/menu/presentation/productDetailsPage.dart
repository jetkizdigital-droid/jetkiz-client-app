import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:http/http.dart' as http;
import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';
import 'package:jetkiz_mobile/features/cart/presentation/cartAddFlow.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesController.dart';
import 'package:jetkiz_mobile/features/menu/domain/restaurantMenuData.dart';

/// Jetkiz mobile
/// Product details page.
///
/// Current source of truth:
/// - canonical product and restaurant availability are loaded from backend when
///   restaurantId is available
/// - preview product is used for instant first render / fallback
///
/// Confirmed backend-supported product fields:
/// - id
/// - titleRu / titleKk
/// - price
/// - imageUrl
/// - images[]
/// - weight
/// - composition
/// - description
/// - isAvailable
///
/// Important notes for future GPT sessions:
/// - product can contain up to 10 photos
/// - gallery must use images[] first
/// - if images[] is empty, fallback to imageUrl
/// - product orderability must include restaurant availability; product
///   isAvailable alone is not sufficient
/// - add-to-cart goes through shared CartRepository
class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({
    super.key,
    required this.product,
    this.restaurantName,
    this.restaurantId,
  });

  /// Preview product.
  /// Can already be full (menu flow) or partial (home/category flow).
  final RestaurantMenuItem product;

  final String? restaurantName;

  /// Required for canonical backend fetch.
  /// If null/empty, page uses only provided preview product.
  final String? restaurantId;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final PageController _pageController;
  final FavoritesController _favorites = FavoritesController.instance;

  int _quantity = 1;
  int _selectedImageIndex = 0;

  late RestaurantMenuItem _product;
  bool _isLoadingCanonical = false;
  bool _restaurantCanOrder = false;
  String _restaurantAvailabilityReason = '';
  String? _canonicalLoadError;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _product = widget.product;
    _restaurantCanOrder = !_canFetchCanonical;
    _favorites.addListener(_handleFavoritesChanged);
    _favorites.initialize();
    _loadCanonicalProductIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ProductDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final productChanged = oldWidget.product.id != widget.product.id;
    final restaurantChanged = (oldWidget.restaurantId ?? '').trim() !=
        (widget.restaurantId ?? '').trim();

    if (productChanged || restaurantChanged) {
      _product = widget.product;
      _selectedImageIndex = 0;
      _quantity = 1;
      _restaurantCanOrder = !_canFetchCanonical;
      _restaurantAvailabilityReason = '';

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }

      _loadCanonicalProductIfNeeded();
    }
  }

  @override
  void dispose() {
    _favorites.removeListener(_handleFavoritesChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _handleFavoritesChanged() {
    if (mounted) setState(() {});
  }

  bool get _canFetchCanonical {
    final restaurantId = widget.restaurantId?.trim();
    return restaurantId != null && restaurantId.isNotEmpty;
  }

  bool get _canOrderProduct {
    return _product.canAddToCart && _restaurantCanOrder;
  }

  String get _availabilityText {
    if (!_product.canAddToCart) {
      return 'Товар сейчас недоступен';
    }

    if (!_restaurantCanOrder) {
      final reason = _restaurantAvailabilityReason.trim();
      if (reason.isNotEmpty) return reason;
      return _isLoadingCanonical
          ? 'Проверяем доступность ресторана'
          : 'Ресторан сейчас не принимает заказы';
    }

    return 'Доступно к заказу';
  }

  String? get _resolvedRestaurantId {
    final canonical = widget.restaurantId?.trim();
    if (canonical != null && canonical.isNotEmpty) {
      return canonical;
    }

    return null;
  }

  String get _resolvedTitle {
    return _product.title.trim().isNotEmpty ? _product.title.trim() : 'Товар';
  }

  String? get _resolvedImageUrl {
    final gallery = _galleryUrls;
    if (gallery.isNotEmpty) {
      return gallery.first;
    }
    return null;
  }

  Future<void> _loadCanonicalProductIfNeeded() async {
    if (!_canFetchCanonical) {
      if (mounted) {
        setState(() {
          _isLoadingCanonical = false;
          _restaurantCanOrder = true;
          _restaurantAvailabilityReason = '';
          _canonicalLoadError = null;
        });
      }
      return;
    }

    setState(() {
      _isLoadingCanonical = true;
      _restaurantCanOrder = false;
      _restaurantAvailabilityReason = 'Проверяем доступность ресторана';
      _canonicalLoadError = null;
    });

    try {
      final restaurantId = widget.restaurantId!.trim();
      final uri = Uri.parse(
        '${AppConfig.baseUrl}/restaurants/$restaurantId/products',
      );

      final response = await http.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to load product details: ${response.statusCode}',
        );
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;

      final menuData = RestaurantMenuData.fromJson(json);
      final availability = menuData.restaurant.availability;

      final RestaurantMenuItem loadedProduct = menuData.items.firstWhere(
        (item) => item.id == widget.product.id,
      );

      if (!mounted) return;

      setState(() {
        _product = loadedProduct;
        _restaurantCanOrder = availability.canOrder;
        _restaurantAvailabilityReason = availability.reason;
        _isLoadingCanonical = false;
        _canonicalLoadError = null;
        _selectedImageIndex = 0;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCanonical = false;
        _restaurantCanOrder = false;
        _restaurantAvailabilityReason =
            'Не удалось проверить доступность ресторана';
        _canonicalLoadError = e.toString();
      });
    }
  }

  List<String> get _galleryUrls {
    final urls = <String>[];

    for (final image in _product.images) {
      if (image.url.trim().isNotEmpty && !urls.contains(image.url.trim())) {
        urls.add(image.url.trim());
      }
    }

    final fallback = _product.imageUrl?.trim();
    if (urls.isEmpty && fallback != null && fallback.isNotEmpty) {
      urls.add(fallback);
    }

    return urls;
  }

  String get _title {
    return _product.title.trim().isNotEmpty ? _product.title.trim() : 'Товар';
  }

  String? get _weight {
    final value = _product.weight?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get _composition {
    final value = _product.composition?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get _description {
    final value = _product.description?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  void _increment() {
    setState(() {
      _quantity += 1;
    });
  }

  void _decrement() {
    if (_quantity <= 1) return;

    setState(() {
      _quantity -= 1;
    });
  }

  Future<void> _toggleFavorite(String productId) async {
    try {
      await _favorites.toggleProduct(productId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('Не удалось обновить избранное')),
      );
    }
  }

  Future<void> _addToCart() async {
    if (!_canOrderProduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: LocalizedText(_availabilityText)),
      );
      return;
    }

    final restaurantId = _resolvedRestaurantId;

    if (restaurantId == null || restaurantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText(
            'Не удалось определить restaurantId. Передай restaurantId при открытии ProductDetailsPage.',
          ),
        ),
      );
      return;
    }

    final result = await addItemWithRestaurantConfirmation(
      context: context,
      productId: _product.id,
      restaurantId: restaurantId,
      restaurantName: widget.restaurantName ?? '',
      title: _resolvedTitle,
      titleRu: _product.titleRu,
      titleKk: _product.titleKk,
      price: _product.price,
      quantity: _quantity,
      imageUrl: _resolvedImageUrl,
      description: _description,
      weight: _weight,
    );

    if (!mounted || result == CartAddResult.rejectedDifferentRestaurant) return;
    if (result == CartAddResult.rejectedInvalidItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText('Не удалось добавить товар в корзину'),
        ),
      );
      return;
    }

    final message = 'Добавлено в корзину: $_quantity шт.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: LocalizedText(message),
        action: SnackBarAction(
          label: 'Корзина',
          onPressed: () {
            Navigator.of(context).pushNamed('/cart');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gallery = _galleryUrls;
    final totalPrice = _product.price * _quantity;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _ProductDetailsTopBar(
                        onBackTap: () => Navigator.of(context).pop(),
                        isFavorite: _favorites.isProductFavorite(_product.id),
                        isFavoriteBusy: _favorites.isProductBusy(_product.id),
                        onFavoriteTap: () => _toggleFavorite(_product.id),
                      ),
                      _ProductMainGallery(
                        imageUrls: gallery,
                        selectedIndex: _selectedImageIndex,
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        },
                      ),
                      if (gallery.length > 1) ...[
                        const SizedBox(height: 14),
                        _ProductGalleryStrip(
                          imageUrls: gallery,
                          selectedIndex: _selectedImageIndex,
                          onImageTap: (index) {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                            );
                            setState(() {
                              _selectedImageIndex = index;
                            });
                          },
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((widget.restaurantName ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              LocalizedText(
                                widget.restaurantName!.trim(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B6B6B),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            LocalizedText(
                              _title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 12),
                            LocalizedText(
                              '${_product.price}₸',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                height: 1.0,
                              ),
                            ),
                            if (_weight != null) ...[
                              const SizedBox(height: 14),
                              _InfoBlock(
                                title: 'Вес',
                                value: _weight!,
                              ),
                            ],
                            if (_composition != null) ...[
                              const SizedBox(height: 14),
                              _InfoBlock(
                                title: 'Состав',
                                value: _composition!,
                              ),
                            ],
                            if (_description != null) ...[
                              const SizedBox(height: 14),
                              _InfoBlock(
                                title: 'Описание',
                                value: _description!,
                              ),
                            ],
                            const SizedBox(height: 14),
                            _AvailabilityBlock(
                              isAvailable: _canOrderProduct,
                              text: _availabilityText,
                            ),
                            if (_canonicalLoadError != null) ...[
                              const SizedBox(height: 12),
                              _CanonicalLoadWarning(
                                onRetryTap: _loadCanonicalProductIfNeeded,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _BottomActionBar(
                  quantity: _quantity,
                  totalPrice: totalPrice,
                  isAvailable: _canOrderProduct,
                  onIncrementTap: _increment,
                  onDecrementTap: _decrement,
                  onAddToCartTap: _addToCart,
                ),
              ],
            ),
            if (_isLoadingCanonical)
              const Positioned(
                top: 12,
                right: 12,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailsTopBar extends StatelessWidget {
  const _ProductDetailsTopBar({
    required this.onBackTap,
    required this.isFavorite,
    required this.isFavoriteBusy,
    required this.onFavoriteTap,
  });

  final VoidCallback onBackTap;
  final bool isFavorite;
  final bool isFavoriteBusy;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: isFavoriteBusy ? null : onFavoriteTap,
            icon: isFavoriteBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.red : Colors.black,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductMainGallery extends StatelessWidget {
  const _ProductMainGallery({
    required this.imageUrls,
    required this.selectedIndex,
    required this.controller,
    required this.onPageChanged,
  });

  final List<String> imageUrls;
  final int selectedIndex;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 1.08,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            color: const Color(0xFFF1F1F1),
            child: imageUrls.isEmpty
                ? const _ImagePlaceholder()
                : Stack(
                    children: [
                      PageView.builder(
                        controller: controller,
                        itemCount: imageUrls.length,
                        onPageChanged: onPageChanged,
                        itemBuilder: (context, index) {
                          return Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const _ImagePlaceholder();
                            },
                          );
                        },
                      ),
                      if (imageUrls.length > 1)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: LocalizedText(
                              '${selectedIndex + 1}/${imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProductGalleryStrip extends StatelessWidget {
  const _ProductGalleryStrip({
    required this.imageUrls,
    required this.selectedIndex,
    required this.onImageTap,
  });

  final List<String> imageUrls;
  final int selectedIndex;
  final ValueChanged<int> onImageTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == selectedImageIndex;

          return GestureDetector(
            onTap: () => onImageTap(index),
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF489F2A)
                      : const Color(0xFFD7D7D7),
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const _ImagePlaceholder();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F1F1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_rounded,
        size: 44,
        color: Color(0xFFB3B3B3),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6C6C6C),
            ),
          ),
          const SizedBox(height: 8),
          LocalizedText(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBlock extends StatelessWidget {
  const _AvailabilityBlock({
    required this.isAvailable,
    required this.text,
  });

  final bool isAvailable;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFEFF8EA) : const Color(0xFFF8ECEC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LocalizedText(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color:
              isAvailable ? const Color(0xFF2F7D1D) : const Color(0xFFB63B3B),
        ),
      ),
    );
  }
}

class _CanonicalLoadWarning extends StatelessWidget {
  const _CanonicalLoadWarning({
    required this.onRetryTap,
  });

  final VoidCallback onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: LocalizedText(
              'Не удалось обновить полные данные товара',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A5A00),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onRetryTap,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: LocalizedText(
                'Повторить',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8A5A00),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.quantity,
    required this.totalPrice,
    required this.isAvailable,
    required this.onIncrementTap,
    required this.onDecrementTap,
    required this.onAddToCartTap,
  });

  final int quantity;
  final int totalPrice;
  final bool isAvailable;
  final VoidCallback onIncrementTap;
  final VoidCallback onDecrementTap;
  final VoidCallback onAddToCartTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _QuantityBox(
              quantity: quantity,
              onIncrementTap: onIncrementTap,
              onDecrementTap: onDecrementTap,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isAvailable ? onAddToCartTap : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF489F2A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: LocalizedText(
                    'Добавить · $totalPrice₸',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityBox extends StatelessWidget {
  const _QuantityBox({
    required this.quantity,
    required this.onIncrementTap,
    required this.onDecrementTap,
  });

  final int quantity;
  final VoidCallback onIncrementTap;
  final VoidCallback onDecrementTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF489F2A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _QtyButton(
            label: '-',
            onTap: onDecrementTap,
          ),
          Expanded(
            child: Center(
              child: LocalizedText(
                '$quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _QtyButton(
            label: '+',
            onTap: onIncrementTap,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 34,
        height: 54,
        child: Center(
          child: LocalizedText(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
