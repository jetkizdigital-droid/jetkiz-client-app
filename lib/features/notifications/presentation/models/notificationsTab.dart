enum NotificationsTab {
  orders,
  promos,
}

extension NotificationsTabX on NotificationsTab {
  String get key {
    switch (this) {
      case NotificationsTab.orders:
        return 'orders';
      case NotificationsTab.promos:
        return 'promos';
    }
  }

  String get label {
    switch (this) {
      case NotificationsTab.orders:
        return 'Заказы';
      case NotificationsTab.promos:
        return 'Акции';
    }
  }

  String get screenName {
    switch (this) {
      case NotificationsTab.orders:
        return 'notifications_orders';
      case NotificationsTab.promos:
        return 'notifications_promos';
    }
  }

  String get title {
    switch (this) {
      case NotificationsTab.orders:
        return 'Уведомления: заказы';
      case NotificationsTab.promos:
        return 'Уведомления: акции';
    }
  }

  String get emptyTitle {
    switch (this) {
      case NotificationsTab.orders:
        return 'Пока нет уведомлений по заказам';
      case NotificationsTab.promos:
        return 'Пока нет акций и общих уведомлений';
    }
  }

  String get emptySubtitle {
    switch (this) {
      case NotificationsTab.orders:
        return 'Статусы заказов будут появляться здесь автоматически.';
      case NotificationsTab.promos:
        return 'На данный момент уведомлений нет.';
    }
  }
}
