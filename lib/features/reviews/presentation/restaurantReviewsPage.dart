import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/reviews/data/restaurantReviewsApi.dart';
import 'package:jetkiz_mobile/features/reviews/domain/restaurantReview.dart';
import 'package:jetkiz_mobile/features/reviews/presentation/widgets/reviewCard.dart';

class RestaurantReviewsPage extends StatefulWidget {
  const RestaurantReviewsPage({
    super.key,
    required this.restaurantId,
    this.restaurantName,
  });

  final String restaurantId;
  final String? restaurantName;

  @override
  State<RestaurantReviewsPage> createState() => _RestaurantReviewsPageState();
}

class _RestaurantReviewsPageState extends State<RestaurantReviewsPage> {
  static const int _pageSize = 30;

  late final RestaurantReviewsApi _api;
  late final ScrollController _scrollController;

  bool _loading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  String? _error;
  String? _loadMoreError;
  List<RestaurantReview> _items = const <RestaurantReview>[];
  int _total = 0;
  int _page = 1;

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _api = RestaurantReviewsApi(ApiClient());
    _scrollController = ScrollController()..addListener(_handleScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        !_hasMore ||
        _loadingMore ||
        _loading) {
      return;
    }

    if (_scrollController.position.extentAfter < 500) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage({bool refresh = false}) async {
    if (refresh) {
      if (_refreshing) return;
      setState(() {
        _refreshing = true;
        _loadMoreError = null;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
        _loadMoreError = null;
      });
    }

    try {
      final result = await _api.getRestaurantReviews(
        widget.restaurantId,
        page: 1,
        limit: _pageSize,
        includeUser: true,
        includeOrder: false,
      );

      if (!mounted) return;

      setState(() {
        _items = _dedupe(result.items);
        _total = result.total;
        _page = 1;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_items.isEmpty) {
          _error = 'Не удалось загрузить отзывы';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (!_hasMore || _loadingMore || _loading) return;

    final nextPage = _page + 1;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });

    try {
      final result = await _api.getRestaurantReviews(
        widget.restaurantId,
        page: nextPage,
        limit: _pageSize,
        includeUser: true,
        includeOrder: false,
      );

      if (!mounted) return;

      setState(() {
        _items = _dedupe(<RestaurantReview>[..._items, ...result.items]);
        _total = result.total;
        _page = nextPage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadMoreError = 'Не удалось загрузить следующие отзывы';
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<RestaurantReview> _dedupe(List<RestaurantReview> source) {
    final seen = <String>{};
    return source.where((item) => seen.add(item.id)).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _ReviewsHeader(
              title: 'Отзывы',
              onBackTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _items.isEmpty
                      ? _ReviewsErrorState(
                          message: _error!,
                          onRetry: _loadFirstPage,
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadFirstPage(refresh: true),
                          child: _items.isEmpty
                              ? const _ReviewsEmptyState()
                              : ListView.separated(
                                  controller: _scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _items.length + 1,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    if (index < _items.length) {
                                      return ReviewCard(
                                        key: ValueKey(_items[index].id),
                                        review: _items[index],
                                      );
                                    }

                                    if (_loadingMore) {
                                      return const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 18),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    if (_loadMoreError != null) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          bottom: 18,
                                        ),
                                        child: Center(
                                          child: OutlinedButton(
                                            onPressed: _loadNextPage,
                                            child: const LocalizedText(
                                              'Загрузить ещё',
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    if (_hasMore) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          bottom: 18,
                                        ),
                                        child: Center(
                                          child: TextButton(
                                            onPressed: _loadNextPage,
                                            child: const LocalizedText(
                                              'Загрузить ещё',
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: 2,
                                        bottom: 18,
                                      ),
                                      child: Center(
                                        child: LocalizedText(
                                          'Все отзывы загружены',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
            if (_refreshing) const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }
}

class _ReviewsHeader extends StatelessWidget {
  const _ReviewsHeader({
    required this.title,
    required this.onBackTap,
  });

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22,
              color: Color(0xFF374151),
            ),
          ),
          Expanded(
            child: LocalizedText(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ReviewsEmptyState extends StatelessWidget {
  const _ReviewsEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
      children: const [
        Icon(Icons.reviews_outlined, size: 54, color: Color(0xFF9CA3AF)),
        SizedBox(height: 16),
        LocalizedText(
          'Пока нет отзывов',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 8),
        LocalizedText(
          'Когда клиенты оставят отзывы, они появятся здесь.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _ReviewsErrorState extends StatelessWidget {
  const _ReviewsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            LocalizedText(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const LocalizedText('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
