import 'package:flutter/foundation.dart';

class NotificationsStateController extends ChangeNotifier {
  NotificationsStateController._();

  static final NotificationsStateController instance =
      NotificationsStateController._();

  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  void setUnreadCount(int value) {
    final next = value < 0 ? 0 : value;
    if (_unreadCount == next) return;
    _unreadCount = next;
    notifyListeners();
  }

  void markOneRead() {
    if (_unreadCount <= 0) return;
    _unreadCount -= 1;
    notifyListeners();
  }

  void markAllRead() => setUnreadCount(0);
}
