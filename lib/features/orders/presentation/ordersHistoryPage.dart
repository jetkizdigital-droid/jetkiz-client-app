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
  static const Color _green = Color(0xFF489F2A);
  static const Color _bg = Color(0xFFF8F8F8);

  late final ApiClient _apiClient;
  late final OrdersApi _ordersApi;
  late final ScrollController _scrollController;

  final List<OrderHistoryItem> _items = <OrderHistoryItem>[];

  bool _loading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _hasMore = true;
  bool _initialOrderOpened = false;
  bool _screenViewTracked = false;

  String? _error;

  int _page = 1;
  int _total = 0;
  OrderHistoryTab _tab = OrderHistoryTab.all;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient();
    _ordersApi = OrdersApi(_apiClient);
    _scrollController = ScrollController()..addListener(_onScroll);

    _loadInitial();
    _trackScreenViewOnce();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _trackScreenViewOnce() async {
    if (_screenViewTracked) return;
    _screenViewTracked = true;

    try {
      await _apiClient.dio.post(
        '/client-events',
        data: {
          'eventName': 'screen_view',
          'metadata': {
            'source': 'orders_history_page',
            'screen': 'orders_history',
            'initialOrderId': widget.initialOrderId,
            'initialOrderNumber': widget.initialOrderNumber,
          },
        },
      );
    } catch (_) {}
  }

  Future<void> _loadInitial() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final data = await _ordersApi.getMyOrders(
        page: 1,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(_dedupeItems(data.items));
        _total = data.total;
        _hasMore = _items.length < _total;
      });

      _tryOpenInitialOrder();
    } on OrdersApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
      });
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
    if (_refreshing) return;

    setState(() {
      _refreshing = true;
    });

    try {
      final data = await _ordersApi.getMyOrders(
        page: 1,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _page = 1;
        _items
          ..clear()
          ..addAll(_dedupeItems(data.items));
        _total = data.total;
        _hasMore = _items.length < _total;
        _error = null;
      });

      _tryOpenInitialOrder();
    } on OrdersApiException catch (error) {
      if (!mounted) return;

      _showSnack(error.message);
    } catch (_) {
      if (!mounted) return;

      _showSnack('Не удалось обновить историю заказов');
    } finally {
      if (!mounted) return;

      setState(() {
        _refreshing = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading || _refreshing) return;

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
        _mergeItems(data.items);
        _total = data.total;
        _hasMore = _items.length < _total;
      });

      _tryOpenInitialOrder();
    } catch (_) {
      if (!mounted) return;

      _showSnack('Не удалось загрузить ещё заказы');
    } finally {
      if (!mounted) return;

      setState(() {
        _loadingMore = false;
      });
    }
  }

  void _mergeItems(List<OrderHistoryItem> nextItems) {
    final seenIds = _items.map((item) => item.id).toSet();

    for (final item in nextItems) {
      final id = item.id.trim();
      if (id.isEmpty || seenIds.contains(id)) {
        continue;
      }

      _items.add(item);
      seenIds.add(id);
    }
  }

  List<OrderHistoryItem> _dedupeItems(List<OrderHistoryItem> source) {
    final seenIds = <String>{};
    final result = <OrderHistoryItem>[];

    for (final item in source) {
      final id = item.id.trim();
      if (id.isEmpty || seenIds.contains(id)) {
        continue;
      }

      result.add(item);
      seenIds.add(id);
    }

    return result;
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
        return _items.where((item) => item.isActive).toList();
      case OrderHistoryTab.completed:
        return _items.where((item) => item.isCompleted).toList();
      case OrderHistoryTab.canceled:
        return _items.where((item) => item.isCanceled).toList();
    }
  }

  void _changeTab(OrderHistoryTab tab) {
    if (_tab == tab) return;

    setState(() {
      _tab = tab;
    });

    if (_filteredItems.isEmpty && _hasMore && !_loadingMore) {
      _loadMore();
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

    final targetTab = _tabForItem(match);
    if (_tab != targetTab) {
      setState(() {
        _tab = targetTab;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openOrderDetails(match!);
    });
  }

  OrderHistoryTab _tabForItem(OrderHistoryItem item) {
    if (item.isActive) {
      return OrderHistoryTab.active;
    }

    if (item.isCompleted) {
      return OrderHistoryTab.completed;
    }

    if (item.isCanceled) {
      return OrderHistoryTab.canceled;
    }

    return OrderHistoryTab.all;
  }

  void _openOrderDetails(OrderHistoryItem item) {
    final orderId = item.id.trim();
    if (orderId.isEmpty) {
      _showSnack('Не удалось открыть заказ');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(orderId: orderId),
      ),
    );
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBackTap: () => Navigator.of(context).maybePop(),
            ),
            _Tabs(
              current: _tab,
              onChanged: _changeTab,
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
      return _FilteredEmptyState(
        onRefresh: _refresh,
        onLoadMore: _hasMore && !_loadingMore ? _loadMore : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: _green,
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
                child: CircularProgressIndicator(color: _green),
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
  const _Header({
    required this.onBackTap,
  });

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
    final items = <_OrderHistoryTabItem>[
      const _OrderHistoryTabItem(OrderHistoryTab.all, 'Все'),
      const _OrderHistoryTabItem(OrderHistoryTab.active, 'Активные'),
      const _OrderHistoryTabItem(OrderHistoryTab.completed, 'Завершённые'),
      const _OrderHistoryTabItem(OrderHistoryTab.canceled, 'Отменённые'),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = items[index];
          final active = item.tab == current;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(item.tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    active ? const Color(0xFF489F2A) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  item.label,
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

class _OrderHistoryTabItem {
  const _OrderHistoryTabItem(
    this.tab,
    this.label,
  );

  final OrderHistoryTab tab;
  final String label;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF489F2A),
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
  const _FilteredEmptyState({
    required this.onRefresh,
    required this.onLoadMore,
  });

  final Future<void> Function() onRefresh;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF489F2A),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          const Center(
            child: Text(
              'В этой вкладке пока нет заказов',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF7A7A7A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onLoadMore != null) ...[
            const SizedBox(height: 14),
            Center(
              child: OutlinedButton(
                onPressed: onLoadMore,
                child: const Text('Загрузить ещё'),
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
