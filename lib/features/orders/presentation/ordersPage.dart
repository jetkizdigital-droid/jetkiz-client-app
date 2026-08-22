import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/orders/data/ordersApi.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderHistoryItem.dart';
import 'package:jetkiz_mobile/features/orders/presentation/orderDetailsPage.dart';
import 'package:jetkiz_mobile/features/orders/presentation/widgets/orderHistoryCard.dart';

enum OrderHistoryTab {
  all,
  active,
  delivered,
  canceled,
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const Color _green = Color(0xFF489F2A);
  static const Color _bg = Color(0xFFF9FAFB);
  static const int _pageLimit = 20;

  late final OrdersApi _ordersApi;
  late final ScrollController _scrollController;

  final List<OrderHistoryItem> _orders = <OrderHistoryItem>[];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorText;

  int _page = 1;
  int _total = 0;

  OrderHistoryTab _activeTab = OrderHistoryTab.all;
  String? _selectedRestaurantId;
  String? _selectedRestaurantName;

  @override
  void initState() {
    super.initState();

    _ordersApi = OrdersApi(ApiClient());
    _scrollController = ScrollController()..addListener(_onScroll);

    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _errorText = null;
      _page = 1;
      _total = 0;
      _hasMore = true;
    });

    try {
      final data = await _ordersApi.getMyOrders(
        page: 1,
        limit: _pageLimit,
      );

      if (!mounted) return;

      setState(() {
        _orders
          ..clear()
          ..addAll(data.items);

        _total = data.total;
        _hasMore = _orders.length < _total;

        _resetRestaurantFilterIfMissing();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorText = error.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final data = await _ordersApi.getMyOrders(
        page: 1,
        limit: _pageLimit,
      );

      if (!mounted) return;

      setState(() {
        _page = 1;
        _orders
          ..clear()
          ..addAll(data.items);

        _total = data.total;
        _hasMore = _orders.length < _total;
        _errorText = null;

        _resetRestaurantFilterIfMissing();
      });
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(error.toString());
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _page + 1;

      final data = await _ordersApi.getMyOrders(
        page: nextPage,
        limit: _pageLimit,
      );

      if (!mounted) return;

      setState(() {
        _page = nextPage;
        _orders.addAll(data.items);
        _total = data.total;
        _hasMore = _orders.length < _total;

        _resetRestaurantFilterIfMissing();
      });
    } catch (_) {
      // Не блокируем экран из-за ошибки догрузки.
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final shouldLoadMore = position.pixels >= position.maxScrollExtent - 260;

    if (shouldLoadMore) {
      _loadMore();
    }
  }

  void _resetRestaurantFilterIfMissing() {
    final selectedId = _selectedRestaurantId?.trim() ?? '';

    if (selectedId.isEmpty) return;

    final exists = _orders.any((order) => order.restaurant.id == selectedId);

    if (!exists) {
      _selectedRestaurantId = null;
      _selectedRestaurantName = null;
    }
  }

  List<_RestaurantFilterOption> get _restaurantOptions {
    final map = <String, _RestaurantFilterOption>{};

    for (final order in _orders) {
      final id = order.restaurant.id.trim();
      final name = order.restaurant.displayName.trim();

      if (id.isEmpty || name.isEmpty) continue;

      map.putIfAbsent(
        id,
        () => _RestaurantFilterOption(
          id: id,
          name: name,
          imageUrl: order.restaurant.fullCoverImageUrl,
        ),
      );
    }

    final items = map.values.toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );

    return items;
  }

  List<OrderHistoryItem> get _filteredOrders {
    Iterable<OrderHistoryItem> items = _orders;

    switch (_activeTab) {
      case OrderHistoryTab.all:
        break;

      case OrderHistoryTab.active:
        items = items.where((order) => order.isActive);

      case OrderHistoryTab.delivered:
        items = items.where((order) => order.isCompleted);

      case OrderHistoryTab.canceled:
        items = items.where((order) => order.isCanceled);
    }

    final selectedRestaurantId = _selectedRestaurantId?.trim() ?? '';

    if (selectedRestaurantId.isNotEmpty) {
      items = items.where(
        (order) => order.restaurant.id == selectedRestaurantId,
      );
    }

    return items.toList();
  }

  void _openOrderDetails(OrderHistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(
          orderId: item.id,
        ),
      ),
    );
  }

  Future<void> _openRestaurantFilterSheet() async {
    final options = _restaurantOptions;
    final selectedId = _selectedRestaurantId;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Фильтр по ресторану',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 14),
                _RestaurantFilterTile(
                  title: 'Все рестораны',
                  selected: selectedId == null,
                  onTap: () {
                    setState(() {
                      _selectedRestaurantId = null;
                      _selectedRestaurantName = null;
                    });

                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 8),
                if (options.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Рестораны пока не найдены',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final option = options[index];

                        return _RestaurantFilterTile(
                          title: option.name,
                          imageUrl: option.imageUrl,
                          selected: option.id == selectedId,
                          onTap: () {
                            setState(() {
                              _selectedRestaurantId = option.id;
                              _selectedRestaurantName = option.name;
                            });

                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _clearRestaurantFilter() {
    setState(() {
      _selectedRestaurantId = null;
      _selectedRestaurantName = null;
    });
  }

  void _showSnackBar(String message) {
    final text =
        message.trim().isEmpty ? 'Не удалось загрузить заказы' : message.trim();

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              hasActiveFilter: (_selectedRestaurantId ?? '').isNotEmpty,
              onBackTap: () => Navigator.of(context).maybePop(),
              onFilterTap: _openRestaurantFilterSheet,
            ),
            if ((_selectedRestaurantName ?? '').isNotEmpty)
              _ActiveRestaurantFilterBar(
                title: _selectedRestaurantName!,
                onClear: _clearRestaurantFilter,
              ),
            _TabsBar(
              current: _activeTab,
              onChanged: (value) {
                setState(() {
                  _activeTab = value;
                });
              },
            ),
            Expanded(
              child: _buildBody(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<OrderHistoryItem> filtered) {
    if (_isLoading) {
      return const _LoadingState();
    }

    if (_errorText != null) {
      return _ErrorState(
        message: _errorText!,
        onRetry: _loadInitial,
      );
    }

    if (_orders.isEmpty) {
      return _EmptyState(
        tab: _activeTab,
        isRestaurantFilterApplied: false,
        onPrimaryTap: () => Navigator.of(context).maybePop(),
      );
    }

    if (filtered.isEmpty) {
      return _EmptyState(
        tab: _activeTab,
        isRestaurantFilterApplied: (_selectedRestaurantId ?? '').isNotEmpty,
        onClearRestaurantFilter: (_selectedRestaurantId ?? '').isNotEmpty
            ? _clearRestaurantFilter
            : null,
      );
    }

    return RefreshIndicator(
      color: _green,
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: CircularProgressIndicator(color: _green),
              ),
            );
          }

          final item = filtered[index];

          return OrderHistoryCard(
            item: item,
            onDetailsTap: () => _openOrderDetails(item),
          );
        },
      ),
    );
  }
}

class _RestaurantFilterOption {
  const _RestaurantFilterOption({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? imageUrl;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBackTap,
    required this.onFilterTap,
    required this.hasActiveFilter,
  });

  final VoidCallback onBackTap;
  final VoidCallback onFilterTap;
  final bool hasActiveFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBackTap,
              ),
              const Spacer(),
              _CircleIconButton(
                icon: hasActiveFilter
                    ? Icons.filter_alt_rounded
                    : Icons.tune_rounded,
                iconColor: hasActiveFilter ? const Color(0xFF489F2A) : null,
                onTap: onFilterTap,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 56),
            child: Text(
              'Мои заказы',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(
          icon,
          size: 23,
          color: iconColor ?? const Color(0xFF374151),
        ),
      ),
    );
  }
}

class _ActiveRestaurantFilterBar extends StatelessWidget {
  const _ActiveRestaurantFilterBar({
    required this.title,
    required this.onClear,
  });

  final String title;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7E5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 16,
                color: Color(0xFF489F2A),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF489F2A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(999),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFF489F2A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantFilterTile extends StatelessWidget {
  const _RestaurantFilterTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final img = imageUrl?.trim() ?? '';

    return Material(
      color: selected ? const Color(0xFFEAF7E5) : const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _RestaurantThumb(
                url: img.isEmpty ? null : img,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? const Color(0xFF489F2A)
                        : const Color(0xFF111827),
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF489F2A),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantThumb extends StatelessWidget {
  const _RestaurantThumb({
    required this.url,
  });

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';

    if (imageUrl.isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        color: Color(0xFF489F2A),
      ),
    );
  }
}

class _TabsBar extends StatelessWidget {
  const _TabsBar({
    required this.current,
    required this.onChanged,
  });

  final OrderHistoryTab current;
  final ValueChanged<OrderHistoryTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <_TabOption>[
      const _TabOption(OrderHistoryTab.all, 'Все'),
      const _TabOption(OrderHistoryTab.active, 'Активные'),
      const _TabOption(OrderHistoryTab.delivered, 'Доставлены'),
      const _TabOption(OrderHistoryTab.canceled, 'Отменены'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = item.tab == current;

            return GestureDetector(
              onTap: () => onChanged(item.tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF489F2A)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TabOption {
  const _TabOption(this.tab, this.label);

  final OrderHistoryTab tab;
  final String label;
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Column(
            children: [
              Row(
                children: [
                  _SkeletonBox(width: 120, height: 18),
                  Spacer(),
                  _SkeletonBox(width: 90, height: 28, radius: 999),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  _SkeletonBox(width: 58, height: 58, radius: 14),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: double.infinity, height: 16),
                        SizedBox(height: 8),
                        _SkeletonBox(width: 140, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              _SkeletonBox(width: double.infinity, height: 36, radius: 12),
              SizedBox(height: 14),
              Row(
                children: [
                  _SkeletonBox(width: 90, height: 24),
                  Spacer(),
                  _SkeletonBox(width: 110, height: 40, radius: 14),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.isInfinite ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.tab,
    required this.isRestaurantFilterApplied,
    this.onPrimaryTap,
    this.onClearRestaurantFilter,
  });

  final OrderHistoryTab tab;
  final bool isRestaurantFilterApplied;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onClearRestaurantFilter;

  @override
  Widget build(BuildContext context) {
    final title = isRestaurantFilterApplied
        ? 'По этому ресторану заказов нет'
        : switch (tab) {
            OrderHistoryTab.all => 'У вас пока нет заказов',
            OrderHistoryTab.active => 'Нет активных заказов',
            OrderHistoryTab.delivered => 'Нет доставленных заказов',
            OrderHistoryTab.canceled => 'Нет отменённых заказов',
          };

    final subtitle = isRestaurantFilterApplied
        ? 'Попробуйте убрать фильтр по ресторану.'
        : tab == OrderHistoryTab.all
            ? 'Добавьте блюда в корзину и оформите первый заказ.'
            : 'Здесь появятся заказы после изменения статуса.';

    return RefreshIndicator(
      color: const Color(0xFF489F2A),
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Color(0xFFF3F4F6),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 54,
                color: Color(0xFFD1D5DB),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (onClearRestaurantFilter != null) ...[
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton(
                onPressed: onClearRestaurantFilter,
                child: const Text('Убрать фильтр'),
              ),
            ),
          ] else if (onPrimaryTap != null) ...[
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: onPrimaryTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF489F2A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Перейти к ресторанам',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text =
        message.trim().isEmpty ? 'Не удалось загрузить заказы' : message.trim();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
