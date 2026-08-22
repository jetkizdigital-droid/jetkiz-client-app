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

  final OpenOrderFromNotification? onOpenOrder;
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
  bool _isAppActive = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _api = NotificationsApi(ApiClient());

    _load();
    _startPolling();
  }

  @override
  void didUpdateWidget(covariant NotificationsBellButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pollInterval != widget.pollInterval) {
      _stopPolling();
      _startPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isActive = state == AppLifecycleState.resumed;

    if (_isAppActive == isActive) {
      return;
    }

    _isAppActive = isActive;

    if (_isAppActive) {
      _load();
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    if (!_isAppActive) return;
    if (widget.pollInterval <= Duration.zero) return;
    if (_timer?.isActive == true) return;

    _timer = Timer.periodic(
      widget.pollInterval,
      (_) => _load(),
    );
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _load() async {
    if (_loading) return;

    _loading = true;

    try {
      final result = await _api.getNotifications(limit: 50);

      if (!mounted) return;

      if (_unreadCount != result.unreadCount) {
        setState(() {
          _unreadCount = result.unreadCount;
        });
      }
    } catch (_) {
      // Silent by design: badge must not break the current screen.
    } finally {
      _loading = false;
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          onOpenOrder: widget.onOpenOrder,
          source: 'notifications_bell',
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
      tooltip: 'Уведомления',
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
