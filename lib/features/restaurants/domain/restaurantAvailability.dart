class RestaurantAvailability {
  const RestaurantAvailability({
    required this.status,
    required this.isInApp,
    required this.isAcceptingOrders,
  });

  final String status;
  final bool isInApp;
  final bool isAcceptingOrders;

  String get _statusUpper => status.trim().toUpperCase();

  bool get isOpen {
    return isInApp && _statusUpper == 'OPEN';
  }

  bool get canOrder {
    return isOpen && isAcceptingOrders;
  }

  String get label {
    if (!isOpen) {
      return '\u0417\u0430\u043a\u0440\u044b\u0442\u043e';
    }

    if (!isAcceptingOrders) {
      return '\u0412\u0440\u0435\u043c\u0435\u043d\u043d\u043e \u043d\u0435 \u043f\u0440\u0438\u043d\u0438\u043c\u0430\u0435\u0442 \u0437\u0430\u043a\u0430\u0437\u044b';
    }

    return '\u041e\u0442\u043a\u0440\u044b\u0442\u043e';
  }

  String get reason {
    if (!isOpen) {
      return '\u0420\u0435\u0441\u0442\u043e\u0440\u0430\u043d \u0441\u0435\u0439\u0447\u0430\u0441 \u0437\u0430\u043a\u0440\u044b\u0442';
    }

    if (!isAcceptingOrders) {
      return '\u0420\u0435\u0441\u0442\u043e\u0440\u0430\u043d \u0432\u0440\u0435\u043c\u0435\u043d\u043d\u043e \u043d\u0435 \u043f\u0440\u0438\u043d\u0438\u043c\u0430\u0435\u0442 \u0437\u0430\u043a\u0430\u0437\u044b';
    }

    return '';
  }
}
