import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/notifications/data/notificationsApi.dart';
import 'package:jetkiz_mobile/features/notifications/domain/notificationItem.dart';

class InAppNotificationsHost extends StatefulWidget {
  const InAppNotificationsHost({
    super.key,
    required this.child,
    required this.onTapNotification,
    this.pollInterval = const Duration(seconds: 15),
  });

  final Widget child;
  final ValueChanged<NotificationItem> onTapNotification;
  final Duration pollInterval;

  @override
  State<InAppNotificationsHost> createState() =>
      _InAppNotificationsHostState();
}

class _InAppNotificationsHostState extends State<InAppNotificationsHost>
    with WidgetsBindingObserver {
  late final NotificationsApi _api;

  Timer? _timer;
  Timer? _overlayTimer;
  OverlayEntry? _overlayEntry;

  bool _initialized = false;
  bool _polling = false;
  bool _isForeground = true;

  final Set<String> _knownIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _api = NotificationsApi(ApiClient());
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _overlayTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
  }

  Future<void> _bootstrap() async {
    await _poll(silent: true);

    if (!mounted) return;

    _timer = Timer.periodic(widget.pollInterval, (_) {
      _poll();
    });
  }

  bool _isOrderNotification(NotificationItem item) {
    final type = item.type.trim().toUpperCase();
    final hasOrderId = (item.orderId ?? '').trim().isNotEmpty;

    return hasOrderId || type.startsWith('ORDER_');
  }

  Future<void> _poll({bool silent = false}) async {
    if (_polling || !_isForeground) return;

    _polling = true;

    try {
      final result = await _api.getNotifications(limit: 50);

      final items = [...result.items]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final currentIds = items.map((e) => e.id).toSet();

      if (!_initialized) {
        _knownIds
          ..clear()
          ..addAll(currentIds);
        _initialized = true;
        return;
      }

      final newItems = items
          .where((item) => !_knownIds.contains(item.id))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _knownIds
        ..clear()
        ..addAll(currentIds);

      if (!silent && mounted && newItems.isNotEmpty) {
        _showPopup(newItems.last);
      }
    } catch (_) {
      // silent by design
    } finally {
      _polling = false;
    }
  }

  void _showPopup(NotificationItem item) {
    _overlayTimer?.cancel();
    _removeOverlay();

    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.lightImpact();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final topInset = MediaQuery.of(context).padding.top + 10;

        return Positioned(
          top: topInset,
          left: 12,
          right: 12,
          child: SafeArea(
            bottom: false,
            child: Material(
              color: Colors.transparent,
              child: _InAppNotificationCard(
                item: item,
                isOrderNotification: _isOrderNotification(item),
                onTap: () async {
                  _removeOverlay();

                  if (!item.isRead) {
                    try {
                      await _api.markAsRead(item.id);
                    } catch (_) {
                      // silent
                    }
                  }

                  if (!mounted) return;
                  widget.onTapNotification(item);
                },
                onClose: _removeOverlay,
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);

    _overlayTimer = Timer(const Duration(seconds: 4), () {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _InAppNotificationCard extends StatelessWidget {
  const _InAppNotificationCard({
    required this.item,
    required this.isOrderNotification,
    required this.onTap,
    required this.onClose,
  });

  final NotificationItem item;
  final bool isOrderNotification;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final accent = isOrderNotification
        ? const Color(0xFF489F2A)
        : const Color(0xFFF59E0B);

    final softBg = isOrderNotification
        ? const Color(0xFFEAF7E5)
        : const Color(0xFFFFF4DB);

    final actionText =
        isOrderNotification ? 'Открыть заказ' : 'Открыть уведомления';

    final categoryText = isOrderNotification ? 'Заказ' : 'Акция';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE6E6E6),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _pickIcon(),
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryText,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2B2B2B),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    if (isOrderNotification &&
                        (item.orderNumber != null || item.status != null)) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (item.orderNumber != null)
                            _MiniChip(label: '№${item.orderNumber}'),
                          if (item.status != null && item.status!.isNotEmpty)
                            _MiniChip(label: item.status!),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      actionText,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                splashRadius: 18,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF7A7A7A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _pickIcon() {
    if (!isOrderNotification) {
      return Icons.local_offer_rounded;
    }

    switch (item.type) {
      case 'ORDER_CREATED':
        return Icons.receipt_long_rounded;
      case 'ORDER_ACCEPTED':
        return Icons.check_circle_rounded;
      case 'ORDER_COOKING':
        return Icons.restaurant_rounded;
      case 'ORDER_READY':
        return Icons.inventory_2_rounded;
      case 'ORDER_ON_THE_WAY':
        return Icons.delivery_dining_rounded;
      case 'ORDER_DELIVERED':
        return Icons.home_filled;
      case 'ORDER_CANCELED':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4B4B4B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}