import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/orders/data/ordersApi.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderHistoryItem.dart';
import 'package:jetkiz_mobile/features/orders/presentation/orderDetailsPage.dart';
import 'package:jetkiz_mobile/features/orders/presentation/widgets/orderHistoryCard.dart';

enum OrderHistoryTab {
  all,
  active,
  completed,
  canceled,
}

class OrdersHistoryPage extends StatefulWidget {
  const OrdersHistoryPage({
    super.key,
    this.initialOrderId,
    this.initialOrderNumber,
  });

  final String? initialOrderId;
  final int? initialOrderNumber;

  @override
  State<OrdersHistoryPage> createState() => _OrdersHistoryPageState();
}

class _OrdersHistoryPageState extends State<OrdersHistoryPage> {
  static const int _pageSize = 20;

  late final OrdersApi _ordersApi;
  late final ScrollController _scrollController;

  final List<OrderHistoryItem> _items = <OrderHistoryItem>[];

  bool _loading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _hasMore = true;
  bool _initialOrderOpened = false;
  String? _error;

  int _page = 1;
  int _total = 0;
  OrderHistoryTab _tab = OrderHistoryTab.all;

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
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
      _initialOrderOpened = false;
    });

    try {
      final data = await _ordersApi.getMyOrders(page: 1, limit: _pageSize);

      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(data.items);
        _total = data.total;
        _hasMore = _items.length < _total;
      });

      _tryOpenInitialOrder();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить историю заказов';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
    });

    try {
      final data = await _ordersApi.getMyOrders(page: 1, limit: _pageSize);

      if (!mounted) return;

      setState(() {
        _page = 1;
        _items
          ..clear()
          ..addAll(data.items);
        _total = data.total;
        _hasMore = _items.length < _total;
        _error = null;
      });

      _tryOpenInitialOrder();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Не удалось обновить историю заказов'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final nextPage = _page + 1;
      final data = await _ordersApi.getMyOrders(
        page: nextPage,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _page = nextPage;
        _items.addAll(data.items);
        _total = data.total;
        _hasMore = _items.length < _total;
      });

      _tryOpenInitialOrder();
    } catch (_) {
      // silent
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
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

  List<OrderHistoryItem> get _filteredItems {
    switch (_tab) {
      case OrderHistoryTab.all:
        return _items;
      case OrderHistoryTab.active:
        return _items.where((e) => e.isActive).toList();
      case OrderHistoryTab.completed:
        return _items.where((e) => e.isCompleted).toList();
      case OrderHistoryTab.canceled:
        return _items.where((e) => e.isCanceled).toList();
    }
  }

  void _tryOpenInitialOrder() {
    if (_initialOrderOpened) return;

    final targetId = (widget.initialOrderId ?? '').trim();
    final targetNumber = widget.initialOrderNumber;

    if (targetId.isEmpty && targetNumber == null) return;
    if (_items.isEmpty) return;

    OrderHistoryItem? match;
    for (final item in _items) {
      if (targetId.isNotEmpty && item.id == targetId) {
        match = item;
        break;
      }

      if (targetNumber != null && item.number == targetNumber) {
        match = item;
        break;
      }
    }

    if (match == null) {
      if (_hasMore && !_loadingMore) {
        _loadMore();
      }
      return;
    }

    _initialOrderOpened = true;

    if (_tab != OrderHistoryTab.completed && match.isCompleted) {
      setState(() {
        _tab = OrderHistoryTab.completed;
      });
    } else if (_tab != OrderHistoryTab.active && match.isActive) {
      setState(() {
        _tab = OrderHistoryTab.active;
      });
    } else if (_tab != OrderHistoryTab.canceled && match.isCanceled) {
      setState(() {
        _tab = OrderHistoryTab.canceled;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openOrderDetails(match!);
    });
  }

  void _openOrderDetails(OrderHistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(orderId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBackTap: () => Navigator.of(context).maybePop(),
            ),
            _Tabs(
              current: _tab,
              onChanged: (tab) {
                setState(() {
                  _tab = tab;
                });
              },
            ),
            Expanded(
              child: _buildBody(visibleItems),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<OrderHistoryItem> visibleItems) {
    if (_loading) {
      return const _LoadingState();
    }

    if (_error != null) {
      return _ErrorState(
        message: _error!,
        onRetry: _loadInitial,
      );
    }

    if (_items.isEmpty) {
      return _EmptyState(
        onRefresh: _refresh,
      );
    }

    if (visibleItems.isEmpty) {
      return const _FilteredEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        itemCount: visibleItems.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index >= visibleItems.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final item = visibleItems[index];
          return OrderHistoryCard(
            item: item,
            onDetailsTap: () => _openOrderDetails(item),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onBackTap,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 28,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'История заказов',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
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
      (OrderHistoryTab.completed, 'Завершённые'),
      (OrderHistoryTab.canceled, 'Отменённые'),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = items[index];
          final active = item.$1 == current;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(item.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF489F2A) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(
            Icons.receipt_long_rounded,
            size: 74,
            color: Color(0xFF489F2A),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'У вас пока нет заказов',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Сделайте первый заказ',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7A7A7A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'В этой вкладке пока нет заказов',
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF7A7A7A),
          fontWeight: FontWeight.w600,
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF489F2A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => Container(
        height: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}