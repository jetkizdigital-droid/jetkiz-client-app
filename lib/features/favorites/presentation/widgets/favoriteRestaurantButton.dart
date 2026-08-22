import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesController.dart';

class FavoriteRestaurantButton extends StatefulWidget {
  const FavoriteRestaurantButton({
    super.key,
    required this.restaurantId,
    this.initialIsFavorite = false,
    this.iconSize = 22,
    this.filledColor,
    this.onChanged,
  });

  final String restaurantId;
  final bool initialIsFavorite;
  final double iconSize;
  final Color? filledColor;
  final ValueChanged<bool>? onChanged;

  @override
  State<FavoriteRestaurantButton> createState() =>
      _FavoriteRestaurantButtonState();
}

class _FavoriteRestaurantButtonState extends State<FavoriteRestaurantButton> {
  final FavoritesController _favorites = FavoritesController.instance;

  @override
  void initState() {
    super.initState();
    _favorites.addListener(_handleFavoritesChanged);
    _favorites.initialize();
  }

  @override
  void dispose() {
    _favorites.removeListener(_handleFavoritesChanged);
    super.dispose();
  }

  void _handleFavoritesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (_favorites.isRestaurantBusy(widget.restaurantId)) return;

    try {
      await _favorites.toggleRestaurant(widget.restaurantId);
      widget.onChanged?.call(
        _favorites.isRestaurantFavorite(widget.restaurantId),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Не удалось обновить избранное');
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.filledColor ?? Colors.redAccent;
    final isFavorite = _favorites.idsLoaded
        ? _favorites.isRestaurantFavorite(widget.restaurantId)
        : widget.initialIsFavorite;
    final isBusy = _favorites.isRestaurantBusy(widget.restaurantId);

    return IconButton(
      onPressed: isBusy ? null : _toggle,
      icon: isBusy
          ? SizedBox(
              width: widget.iconSize,
              height: widget.iconSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: widget.iconSize,
              color: isFavorite ? color : null,
            ),
      tooltip: isFavorite ? 'Убрать из избранного' : 'Добавить в избранное',
    );
  }
}
