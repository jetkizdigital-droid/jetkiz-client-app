import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/notifications/data/notificationsApi.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/notificationsPage.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/widgets/notificationBadge.dart';

class NotificationsBellButton extends StatefulWidget {
  const NotificationsBellButton({
    super.key,
    this.onOpenOrder,
    this.iconColor = Colors.black,
    this.iconSize = 26,
    this.pollInterval = const Duration(seconds: 20),
  });

  final void Function(String orderId, int? orderNumber)? onOpenOrder;
  final Color iconColor;
  final double iconSize;
  final Duration pollInterval;

  @override
  State<NotificationsBellButton> createState() =>
      _NotificationsBellButtonState();
}

class _NotificationsBellButtonState extends State<NotificationsBellButton>
    with WidgetsBindingObserver {
  late final NotificationsApi _api;

  Timer? _timer;
  bool _loading = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _api = NotificationsApi(ApiClient());
    _load();
    _timer = Timer.periodic(widget.pollInterval, (_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading) return;

    _loading = true;

    try {
      final result = await _api.getNotifications(limit: 50);

      if (!mounted) return;

      setState(() {
        _unreadCount = result.unreadCount;
      });
    } catch (_) {
      // silent by design
    } finally {
      _loading = false;
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          onOpenOrder: widget.onOpenOrder,
        ),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _open,
      icon: NotificationBadge(
        count: _unreadCount,
        child: Icon(
          Icons.notifications_none_rounded,
          size: widget.iconSize,
          color: widget.iconColor,
        ),
      ),
    );
  }
}