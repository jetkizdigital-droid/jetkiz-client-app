import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesApi.dart';

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
  late final FavoritesApi _favoritesApi;

  bool _isFavorite = false;
  bool _isBusy = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _favoritesApi = FavoritesApi(ApiClient());
    _isFavorite = widget.initialIsFavorite;
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      final ids = await _favoritesApi.getFavoriteIds();
      if (!mounted) return;

      setState(() {
        _isFavorite = ids.restaurantIds.contains(widget.restaurantId);
        _isInitialized = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isFavorite = widget.initialIsFavorite;
        _isInitialized = true;
      });
    }
  }

  Future<void> _toggle() async {
    if (_isBusy) return;

    final nextValue = !_isFavorite;

    setState(() {
      _isBusy = true;
      _isFavorite = nextValue;
    });

    try {
      await _favoritesApi.toggleRestaurantFavorite(
        restaurantId: widget.restaurantId,
        isFavorite: !nextValue,
      );

      widget.onChanged?.call(nextValue);
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _isFavorite = !nextValue;
      });

      _showSnack(_favoritesApi.extractMessage(e));
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isFavorite = !nextValue;
      });

      _showSnack('Не удалось обновить избранное');
    } finally {
      if (!mounted) return;

      setState(() {
        _isBusy = false;
      });
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

    return IconButton(
      onPressed: _isBusy ? null : _toggle,
      icon: _isBusy && _isInitialized
          ? SizedBox(
              width: widget.iconSize,
              height: widget.iconSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              size: widget.iconSize,
              color: _isFavorite ? color : null,
            ),
      tooltip: _isFavorite ? 'Убрать из избранного' : 'Добавить в избранное',
    );
  }
}
