import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/analytics/analyticsService.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/notifications/data/notificationsApi.dart';
import 'package:jetkiz_mobile/features/notifications/data/notificationsStateController.dart';
import 'package:jetkiz_mobile/features/notifications/domain/notificationItem.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/models/notificationsTab.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/widgets/notificationCard.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/widgets/notificationsEmptyState.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/widgets/notificationsErrorState.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/widgets/notificationsTabs.dart';

typedef OpenOrderFromNotification = FutureOr<void> Function(
  String? orderId,
  int? orderNumber,
);

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.onOpenOrder,
    this.source = 'notifications_page',
  });

  final OpenOrderFromNotification? onOpenOrder;
  final String source;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final ApiClient _apiClient;
  late final NotificationsApi _api;
  late final AnalyticsService _analyticsService;

  bool _loading = true;
  bool _refreshing = false;
  bool _markAllLoading = false;
  String? _error;

  List<NotificationItem> _items = const [];
  int _unreadCount = 0;

  NotificationsTab _selectedTab = NotificationsTab.orders;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient();
    _api = NotificationsApi(_apiClient);
    _analyticsService = AnalyticsService(_apiClient);

    unawaited(
      _analyticsService.trackScreenView(
        screen: 'notifications',
        title: 'Уведомления',
        source: widget.source,
        metadata: {
          'initialTab': _selectedTab.key,
        },
      ),
    );

    unawaited(_load());
  }

  List<NotificationItem> get _orderItems {
    return _items.where(_isOrderNotification).toList();
  }

  List<NotificationItem> get _promoItems {
    return _items.where((item) => !_isOrderNotification(item)).toList();
  }

  List<NotificationItem> get _visibleItems {
    switch (_selectedTab) {
      case NotificationsTab.orders:
        return _orderItems;
      case NotificationsTab.promos:
        return _promoItems;
    }
  }

  int get _ordersUnreadCount {
    return _orderItems.where((item) => !item.isRead).length;
  }

  int get _promosUnreadCount {
    return _promoItems.where((item) => !item.isRead).length;
  }

  bool _isOrderNotification(NotificationItem item) {
    final type = item.type.trim().toUpperCase();
    final orderId = (item.orderId ?? '').trim();

    if (orderId.isNotEmpty) {
      return true;
    }

    if (item.orderNumber != null) {
      return true;
    }

    if (type.startsWith('ORDER_')) {
      return true;
    }

    return false;
  }

  void _selectTab(NotificationsTab tab) {
    if (_selectedTab == tab) {
      return;
    }

    setState(() {
      _selectedTab = tab;
    });

    unawaited(
      _analyticsService.trackScreenView(
        screen: tab.screenName,
        title: tab.title,
        source: 'notifications_tabs',
        metadata: {
          'tab': tab.key,
          'ordersUnreadCount': _ordersUnreadCount,
          'promosUnreadCount': _promosUnreadCount,
          'totalUnreadCount': _unreadCount,
        },
      ),
    );
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _api.getNotifications();

      if (!mounted) return;

      setState(() {
        _items = _sortItems(result.items);
        _unreadCount = result.unreadCount;
      });
      NotificationsStateController.instance.setUnreadCount(result.unreadCount);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Не удалось загрузить уведомления';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;

    setState(() {
      _refreshing = true;
    });

    try {
      final result = await _api.getNotifications();

      if (!mounted) return;

      setState(() {
        _items = _sortItems(result.items);
        _unreadCount = result.unreadCount;
        _error = null;
      });
      NotificationsStateController.instance.setUnreadCount(result.unreadCount);
    } catch (_) {
      if (!mounted) return;

      _showError('Не удалось обновить уведомления');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  List<NotificationItem> _sortItems(List<NotificationItem> source) {
    final sorted = [...source]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sorted;
  }

  Future<void> _markAsRead(NotificationItem item) async {
    if (item.isRead) {
      return;
    }

    final previousItems = _items;
    final previousUnreadCount = _unreadCount;

    setState(() {
      _items = _items.map((current) {
        if (current.id != item.id) {
          return current;
        }

        return _copyNotificationItem(
          current,
          isRead: true,
          readAt: DateTime.now(),
        );
      }).toList();

      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
    });
    NotificationsStateController.instance.setUnreadCount(_unreadCount);

    try {
      await _api.markAsRead(item.id);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _items = previousItems;
        _unreadCount = previousUnreadCount;
      });
      NotificationsStateController.instance.setUnreadCount(previousUnreadCount);

      _showError('Не удалось отметить уведомление как прочитанное');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_markAllLoading || _unreadCount == 0) {
      return;
    }

    final previousItems = _items;
    final previousUnreadCount = _unreadCount;
    final now = DateTime.now();

    setState(() {
      _markAllLoading = true;
      _items = _items
          .map(
            (item) => item.isRead
                ? item
                : _copyNotificationItem(
                    item,
                    isRead: true,
                    readAt: now,
                  ),
          )
          .toList();
      _unreadCount = 0;
    });
    NotificationsStateController.instance.markAllRead();

    try {
      await _api.markAllAsRead();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _items = previousItems;
        _unreadCount = previousUnreadCount;
      });
      NotificationsStateController.instance.setUnreadCount(previousUnreadCount);

      _showError('Не удалось отметить уведомления как прочитанные');
    } finally {
      if (mounted) setState(() => _markAllLoading = false);
    }
  }

  NotificationItem _copyNotificationItem(
    NotificationItem item, {
    required bool isRead,
    required DateTime? readAt,
  }) {
    return NotificationItem(
      id: item.id,
      type: item.type,
      title: item.title,
      body: item.body,
      isRead: isRead,
      createdAt: item.createdAt,
      readAt: readAt,
      data: item.data,
    );
  }

  Future<void> _handleNotificationTap(NotificationItem item) async {
    final isOrderNotification = _isOrderNotification(item);
    final orderId = (item.orderId ?? '').trim();
    final normalizedOrderId = orderId.isEmpty ? null : orderId;
    final orderNumber = item.orderNumber;

    unawaited(
      _analyticsService.trackNotificationOpen(
        notificationId: item.id,
        orderId: normalizedOrderId,
        orderNumber: orderNumber,
        source: 'notifications_${_selectedTab.key}',
      ),
    );

    await _markAsRead(item);

    if (!mounted) return;

    if (isOrderNotification &&
        (normalizedOrderId != null || orderNumber != null)) {
      final handler = widget.onOpenOrder;

      if (handler != null) {
        await handler(normalizedOrderId, orderNumber);
        return;
      }
    }

    if (!isOrderNotification) {
      _showError('Это уведомление не связано с заказом');
    }
  }

  void _showError(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Уведомления${_unreadCount > 0 ? ' ($_unreadCount)' : ''}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllLoading ? null : _markAllAsRead,
              child: _markAllLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Прочитать все'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            NotificationsTabs(
              selectedTab: _selectedTab,
              ordersUnreadCount: _ordersUnreadCount,
              promosUnreadCount: _promosUnreadCount,
              onChanged: _selectTab,
            ),
            Expanded(
              child: _buildBody(visibleItems),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<NotificationItem> visibleItems) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return NotificationsErrorState(
        message: _error!,
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: visibleItems.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                NotificationsEmptyState(
                  title: _selectedTab.emptyTitle,
                  subtitle: _selectedTab.emptySubtitle,
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: visibleItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = visibleItems[index];

                return NotificationCard(
                  item: item,
                  isOrderNotification: _isOrderNotification(item),
                  onTap: () => _handleNotificationTap(item),
                );
              },
            ),
    );
  }
}
