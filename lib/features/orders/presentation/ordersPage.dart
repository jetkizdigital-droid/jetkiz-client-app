import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/orders/data/ordersApi.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderHistoryItem.dart';
import 'package:jetkiz_mobile/features/orders/presentation/orderDetailsPage.dart';

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
  static const Color _cardBorder = Color(0xFFF0F1F3);

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
      _errorText = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final data = await _ordersApi.getMyOrders(page: 1, limit: 20);

      if (!mounted) return;

      setState(() {
        _orders
          ..clear()
          ..addAll(data.items);
        _total = data.total;
        _hasMore = _orders.length < _total;

        if (_selectedRestaurantId != null &&
            !_orders.any((e) => e.restaurant.id == _selectedRestaurantId)) {
          _selectedRestaurantId = null;
          _selectedRestaurantName = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Не удалось загрузить историю заказов';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final data = await _ordersApi.getMyOrders(page: 1, limit: 20);

      if (!mounted) return;

      setState(() {
        _page = 1;
        _orders
          ..clear()
          ..addAll(data.items);
        _total = data.total;
        _hasMore = _orders.length < _total;
        _errorText = null;

        if (_selectedRestaurantId != null &&
            !_orders.any((e) => e.restaurant.id == _selectedRestaurantId)) {
          _selectedRestaurantId = null;
          _selectedRestaurantName = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Не удалось обновить историю заказов'),
        ),
      );
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _page + 1;
      final data = await _ordersApi.getMyOrders(page: nextPage, limit: 20);

      if (!mounted) return;

      setState(() {
        _page = nextPage;
        _orders.addAll(data.items);
        _total = data.total;
        _hasMore = _orders.length < _total;

        if (_selectedRestaurantId != null &&
            !_orders.any((e) => e.restaurant.id == _selectedRestaurantId)) {
          _selectedRestaurantId = null;
          _selectedRestaurantName = null;
        }
      });
    } catch (_) {
      // silent
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      _loadMore();
    }
  }

  List<_RestaurantFilterOption> get _restaurantOptions {
    final map = <String, _RestaurantFilterOption>{};

    for (final order in _orders) {
      final id = order.restaurant.id.trim();
      final name = order.restaurant.nameRu.trim();

      if (id.isEmpty || name.isEmpty) continue;

      map.putIfAbsent(
        id,
        () => _RestaurantFilterOption(
          id: id,
          name: name,
          imageUrl: order.restaurant.coverImageUrl,
        ),
      );
    }

    final items = map.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return items;
  }

  List<OrderHistoryItem> get _filteredOrders {
    Iterable<OrderHistoryItem> items = _orders;

    switch (_activeTab) {
      case OrderHistoryTab.all:
        break;
      case OrderHistoryTab.active:
        items = items.where((e) => e.isActive);
        break;
      case OrderHistoryTab.delivered:
        items = items.where((e) => e.isCompleted);
        break;
      case OrderHistoryTab.canceled:
        items = items.where((e) => e.isCanceled);
        break;
    }

    if ((_selectedRestaurantId ?? '').isNotEmpty) {
      items = items.where((e) => e.restaurant.id == _selectedRestaurantId);
    }

    return items.toList();
  }

  void _openOrderDetails(OrderHistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(orderId: item.id),
      ),
    );
  }

  Future<void> _openRestaurantFilterSheet() async {
    final options = _restaurantOptions;
    final selectedId = _selectedRestaurantId;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Выбрать ресторан',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
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
                const SizedBox(height: 6),
                if (options.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      'Рестораны пока недоступны',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
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
                onClear: () {
                  setState(() {
                    _selectedRestaurantId = null;
                    _selectedRestaurantName = null;
                  });
                },
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
        isRestaurantFilterApplied: (_selectedRestaurantId ?? '').isNotEmpty,
        onPrimaryTap: _activeTab == OrderHistoryTab.all
            ? () => Navigator.of(context).maybePop()
            : null,
      );
    }

    if (filtered.isEmpty) {
      return _EmptyState(
        tab: _activeTab,
        isRestaurantFilterApplied: (_selectedRestaurantId ?? '').isNotEmpty,
        onClearRestaurantFilter: (_selectedRestaurantId ?? '').isNotEmpty
            ? () {
                setState(() {
                  _selectedRestaurantId = null;
                  _selectedRestaurantName = null;
                });
              }
            : null,
      );
    }

    return RefreshIndicator(
      color: _green,
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(color: _green),
              ),
            );
          }

          final item = filtered[index];
          return _OrderCard(
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
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
              'История заказов',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
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
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF489F2A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
    return Material(
      color: selected ? const Color(0xFFEAF7E5) : const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if ((imageUrl ?? '').trim().isNotEmpty) ...[
                _RestaurantThumb(url: imageUrl),
                const SizedBox(width: 10),
              ] else ...[
                Container(
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
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF489F2A)
                        : const Color(0xFF1F2937),
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
    final imageUrl = _normalizeImageUrl(url);

    if (imageUrl == null) {
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
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
        },
      ),
    );
  }

  String? _normalizeImageUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '${AppConfig.baseUrl}$value';
    }
    return '${AppConfig.baseUrl}/$value';
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
    final items = <(OrderHistoryTab, String)>[
      (OrderHistoryTab.all, 'Все'),
      (OrderHistoryTab.active, 'Активные'),
      (OrderHistoryTab.delivered, 'Завершённые'),
      (OrderHistoryTab.canceled, 'Отменённые'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = item.$1 == current;

            return GestureDetector(
              onTap: () => onChanged(item.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
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
                  item.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.item,
    required this.onDetailsTap,
  });

  final OrderHistoryItem item;
  final VoidCallback onDetailsTap;

  static const Color _green = Color(0xFF489F2A);

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatus(item.status);
    final previewText = _buildPreviewText(item.previewItems);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F1F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Заказ №${item.number}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                _StatusChip(
                  label: status.label,
                  backgroundColor: status.backgroundColor,
                  textColor: status.textColor,
                  icon: status.icon,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _RestaurantImage(url: item.restaurant.coverImageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.restaurant.nameRu.isEmpty
                            ? 'Ресторан'
                            : item.restaurant.nameRu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(item.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                previewText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Сумма заказа',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.total} ₸',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onDetailsTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: const BorderSide(color: _green, width: 2),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Подробнее',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildPreviewText(List<OrderPreviewItem> items) {
    if (items.isEmpty) return 'Состав заказа недоступен';
    return items.take(2).map((e) => '${e.title} x${e.quantity}').join(', ');
  }

  String _formatDateTime(DateTime value) {
    const months = <int, String>{
      1: 'января',
      2: 'февраля',
      3: 'марта',
      4: 'апреля',
      5: 'мая',
      6: 'июня',
      7: 'июля',
      8: 'августа',
      9: 'сентября',
      10: 'октября',
      11: 'ноября',
      12: 'декабря',
    };

    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.day} ${months[value.month] ?? ''} ${value.year} в ${two(value.hour)}:${two(value.minute)}';
  }

  _StatusUi _resolveStatus(String raw) {
    final status = raw.toUpperCase();

    if ([
      'CREATED',
      'ACCEPTED',
      'COOKING',
      'READY',
      'ON_THE_WAY',
    ].contains(status)) {
      return const _StatusUi(
        label: 'В пути',
        backgroundColor: Color(0xFF489F2A),
        textColor: Colors.white,
        icon: Icons.access_time_rounded,
      );
    }

    if (status == 'DELIVERED' || status == 'PAID') {
      return const _StatusUi(
        label: 'Доставлен',
        backgroundColor: Color(0xFFF3F4F6),
        textColor: Color(0xFF4B5563),
        icon: Icons.check_circle_rounded,
      );
    }

    if (status == 'CANCELED') {
      return const _StatusUi(
        label: 'Отменён',
        backgroundColor: Color(0xFFFDE8E8),
        textColor: Color(0xFFC53030),
        icon: Icons.cancel_rounded,
      );
    }

    return const _StatusUi(
      label: 'Статус',
      backgroundColor: Color(0xFFF3F4F6),
      textColor: Color(0xFF4B5563),
      icon: Icons.info_outline_rounded,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusUi {
  const _StatusUi({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({
    required this.url,
  });

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _normalizeImageUrl(url);

    if (imageUrl == null) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: Color(0xFF9CA3AF),
        size: 28,
      ),
    );
  }

  String? _normalizeImageUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '${AppConfig.baseUrl}$value';
    }
    return '${AppConfig.baseUrl}/$value';
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF0F1F3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 110,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 90,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 90,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 110,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
        ? 'Нет заказов по выбранному ресторану'
        : switch (tab) {
            OrderHistoryTab.all => 'У вас пока нет заказов',
            OrderHistoryTab.active => 'Нет активных заказов',
            OrderHistoryTab.delivered => 'Нет завершённых заказов',
            OrderHistoryTab.canceled => 'Нет отменённых заказов',
          };

    final subtitle = isRestaurantFilterApplied
        ? 'Попробуйте выбрать другой ресторан'
        : tab == OrderHistoryTab.all
            ? 'Сделайте первый заказ в любимом ресторане'
            : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const Center(
          child: CircleAvatar(
            radius: 64,
            backgroundColor: Color(0xFFF3F4F6),
            child: Icon(
              Icons.access_time_rounded,
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
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (onClearRestaurantFilter != null) ...[
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton(
              onPressed: onClearRestaurantFilter,
              child: const Text('Сбросить фильтр'),
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
                elevation: 2,
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 14),
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