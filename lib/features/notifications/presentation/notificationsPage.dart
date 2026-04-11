import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/notifications/data/notificationsApi.dart';
import 'package:jetkiz_mobile/features/notifications/domain/notificationItem.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.onOpenOrder,
  });

  final void Function(String orderId, int? orderNumber)? onOpenOrder;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

enum _NotificationsTab {
  orders,
  promos,
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsApi _api;

  bool _loading = true;
  bool _markTabLoading = false;
  String? _error;

  List<NotificationItem> _items = const [];
  int _unreadCount = 0;

  _NotificationsTab _selectedTab = _NotificationsTab.orders;

  @override
  void initState() {
    super.initState();
    _api = NotificationsApi(ApiClient());
    _load();
  }

  List<NotificationItem> get _orderItems =>
      _items.where(_isOrderNotification).toList();

  List<NotificationItem> get _promoItems =>
      _items.where((item) => !_isOrderNotification(item)).toList();

  List<NotificationItem> get _visibleItems {
    switch (_selectedTab) {
      case _NotificationsTab.orders:
        return _orderItems;
      case _NotificationsTab.promos:
        return _promoItems;
    }
  }

  int get _ordersUnreadCount => _orderItems.where((e) => !e.isRead).length;

  int get _promosUnreadCount => _promoItems.where((e) => !e.isRead).length;

  bool _isOrderNotification(NotificationItem item) {
    final type = item.type.trim().toUpperCase();
    final hasOrderId = (item.orderId ?? '').trim().isNotEmpty;

    if (hasOrderId) return true;
    if (type.startsWith('ORDER_')) return true;

    return false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _api.getNotifications();

      if (!mounted) return;

      final sorted = [...result.items]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _items = sorted;
        _unreadCount = result.unreadCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить уведомления';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final result = await _api.getNotifications();

      if (!mounted) return;

      final sorted = [...result.items]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _items = sorted;
        _unreadCount = result.unreadCount;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось обновить уведомления';
      });
    }
  }

  Future<void> _markAsRead(NotificationItem item) async {
    if (item.isRead) return;

    final previousItems = _items;
    final previousUnread = _unreadCount;

    setState(() {
      _items = _items.map((e) {
        if (e.id != item.id) return e;
        return NotificationItem(
          id: e.id,
          type: e.type,
          title: e.title,
          body: e.body,
          isRead: true,
          createdAt: e.createdAt,
          readAt: DateTime.now(),
          data: e.data,
        );
      }).toList();

      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
    });

    try {
      await _api.markAsRead(item.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = previousItems;
        _unreadCount = previousUnread;
      });
      _showError('Не удалось отметить уведомление как прочитанное');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_markTabLoading || _unreadCount == 0) {
      return;
    }

    setState(() {
      _markTabLoading = true;
    });

    try {
      await _api.markAllAsRead();

      if (!mounted) return;

      await _load();
    } catch (_) {
      if (!mounted) return;
      _showError('Не удалось отметить уведомления как прочитанные');
    } finally {
      if (!mounted) return;
      setState(() {
        _markTabLoading = false;
      });
    }
  }

  Future<void> _handleTap(NotificationItem item) async {
    await _markAsRead(item);

    if (_isOrderNotification(item)) {
      final orderId = item.orderId;
      if (orderId != null && orderId.isNotEmpty) {
        widget.onOpenOrder?.call(orderId, item.orderNumber);
      }
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
              onPressed: _markTabLoading ? null : _markAllAsRead,
              child: _markTabLoading
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
            _NotificationsTabs(
              selectedTab: _selectedTab,
              ordersUnreadCount: _ordersUnreadCount,
              promosUnreadCount: _promosUnreadCount,
              onChanged: (tab) {
                setState(() {
                  _selectedTab = tab;
                });
              },
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _NotificationsErrorState(
                          message: _error!,
                          onRetry: _load,
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: visibleItems.isEmpty
                              ? _NotificationsEmptyState(
                                  title: _selectedTab == _NotificationsTab.orders
                                      ? 'Пока нет уведомлений по заказам'
                                      : 'Пока нет акций и общих уведомлений',
                                  subtitle: _selectedTab ==
                                          _NotificationsTab.orders
                                      ? 'Статусы заказов будут появляться здесь автоматически.'
                                      : 'На данный момент уведомлений нет.',
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    24,
                                  ),
                                  itemCount: visibleItems.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = visibleItems[index];
                                    final isOrderNotification =
                                        _isOrderNotification(item);

                                    return _NotificationCard(
                                      item: item,
                                      isOrderNotification: isOrderNotification,
                                      onTap: () => _handleTap(item),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsTabs extends StatelessWidget {
  const _NotificationsTabs({
    required this.selectedTab,
    required this.ordersUnreadCount,
    required this.promosUnreadCount,
    required this.onChanged,
  });

  final _NotificationsTab selectedTab;
  final int ordersUnreadCount;
  final int promosUnreadCount;
  final ValueChanged<_NotificationsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _NotificationsTabButton(
              label: 'Заказы',
              unreadCount: ordersUnreadCount,
              selected: selectedTab == _NotificationsTab.orders,
              onTap: () => onChanged(_NotificationsTab.orders),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _NotificationsTabButton(
              label: 'Акции',
              unreadCount: promosUnreadCount,
              selected: selectedTab == _NotificationsTab.promos,
              onTap: () => onChanged(_NotificationsTab.promos),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsTabButton extends StatelessWidget {
  const _NotificationsTabButton({
    required this.label,
    required this.unreadCount,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int unreadCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFEAF7E5) : Colors.white;
    final border =
        selected ? const Color(0xFF489F2A) : const Color(0xFFE0E0E0);
    final text = selected ? const Color(0xFF2E7D32) : const Color(0xFF444444);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF489F2A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.isOrderNotification,
    required this.onTap,
  });

  final NotificationItem item;
  final bool isOrderNotification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasOrder = (item.orderId ?? '').trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE7E7E7)
                  : const Color(0xFF489F2A),
              width: item.isRead ? 1 : 1.4,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationLeading(
                isRead: item.isRead,
                type: item.type,
                isOrderNotification: isOrderNotification,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: item.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateTime(item.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: Color(0xFF2B2B2B),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    if (hasOrder) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Spacer(),
                          _OpenOrderButton(onTap: onTap),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF489F2A),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({
    required this.isRead,
    required this.type,
    required this.isOrderNotification,
  });

  final bool isRead;
  final String type;
  final bool isOrderNotification;

  IconData _pickIcon() {
    final normalized = type.trim().toUpperCase();

    if (isOrderNotification) {
      switch (normalized) {
        case 'ORDER_DELIVERED':
          return Icons.check_circle_rounded;
        case 'ORDER_CANCELED':
          return Icons.cancel_rounded;
        case 'ORDER_ACCEPTED':
        case 'ORDER_READY':
        case 'ORDER_ON_THE_WAY':
          return Icons.receipt_long_rounded;
        default:
          return Icons.local_shipping_rounded;
      }
    }

    return Icons.local_offer_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _pickIcon();
    final bg = isOrderNotification
        ? const Color(0xFFEAF7E5)
        : const Color(0xFFFFF4DB);
    final color = isOrderNotification
        ? const Color(0xFF2E7D32)
        : const Color(0xFFB7791F);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: isRead ? color.withOpacity(0.78) : color,
        size: 22,
      ),
    );
  }
}

class _OpenOrderButton extends StatelessWidget {
  const _OpenOrderButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF489F2A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Text(
            'Открыть заказ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        const Icon(
          Icons.notifications_none_rounded,
          size: 68,
          color: Color(0xFF489F2A),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF7A7A7A),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _NotificationsErrorState extends StatelessWidget {
  const _NotificationsErrorState({
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

String _formatDateTime(DateTime value) {
  final now = DateTime.now();
  final local = value.toLocal();

  final isToday = now.year == local.year &&
      now.month == local.month &&
      now.day == local.day;

  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');

  if (isToday) {
    return '$hh:$mm';
  }

  final dd = local.day.toString().padLeft(2, '0');
  final mo = local.month.toString().padLeft(2, '0');

  return '$dd.$mo $hh:$mm';
}