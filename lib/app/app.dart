import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/core/navigation/appNavigator.dart';
import 'package:jetkiz_mobile/features/auth/presentation/profileEntryPage.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';
import 'package:jetkiz_mobile/features/cart/presentation/cartPage.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesController.dart';
import 'package:jetkiz_mobile/features/favorites/presentation/favoritesPage.dart';
import 'package:jetkiz_mobile/features/home/presentation/homePage.dart';
import 'package:jetkiz_mobile/features/notifications/domain/notificationItem.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/notificationsPage.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/widgets/inAppNotificationsHost.dart';
import 'package:jetkiz_mobile/features/orders/presentation/orderDetailsPage.dart';
import 'package:jetkiz_mobile/features/orders/presentation/ordersHistoryPage.dart';

class JetkizApp extends StatefulWidget {
  const JetkizApp({super.key});

  @override
  State<JetkizApp> createState() => _JetkizAppState();
}

class _JetkizAppState extends State<JetkizApp> with WidgetsBindingObserver {
  static const _languageKey = 'jetkiz.language';
  AppLanguage _language = AppLanguage.ru;

  void _setLanguage(AppLanguage language) {
    if (_language == language) return;

    setState(() {
      _language = language;
    });
    SharedPreferences.getInstance().then(
      (preferences) => preferences.setString(_languageKey, language.name),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppNavigator.registerPushNavigationHandler(_handlePushNavigation);
    CartRepository.instance.restore();
    _restoreLanguage();
  }

  Future<void> _restoreLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_languageKey);
    if (!mounted) return;
    final language = saved == AppLanguage.kk.name
        ? AppLanguage.kk
        : AppLanguage.ru;
    if (_language != language) setState(() => _language = language);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppNavigator.clearPushNavigationHandler();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        CartRepository.instance.isNotEmpty) {
      CartRepository.instance.syncWithServer();
    }
  }

  Future<void> _handleNotificationTap(NotificationItem item) async {
    final orderId = (item.orderId ?? '').trim();
    final orderNumber = item.orderNumber;

    if (orderId.isNotEmpty || orderNumber != null) {
      await _openOrderFromNotification(
        orderId.isEmpty ? null : orderId,
        orderNumber,
      );
      return;
    }

    await _openNotificationsPage();
  }

  Future<void> _handlePushNavigation(Map<String, String> data) async {
    final app = _readStringFromData(
      data,
      const ['app', 'targetApp', 'application'],
    ).toLowerCase();

    if (app.isNotEmpty && app != 'client' && app != 'auto') {
      return;
    }

    final screen = _readStringFromData(
      data,
      const ['screen', 'route', 'target', 'type'],
    ).toLowerCase();

    final orderId = _readStringFromData(
      data,
      const ['orderId', 'order_id', 'orderID'],
    );

    if (screen.isEmpty && orderId.isNotEmpty) {
      await _openOrderFromPush(data);
      return;
    }

    switch (screen) {
      case 'home':
      case 'main':
        _openMainTab(0);
        return;

      case 'favorites':
      case 'favourites':
        _openMainTab(1);
        return;

      case 'cart':
      case 'basket':
        _openMainTab(2);
        return;

      case 'profile':
      case 'account':
        _openMainTab(3);
        return;

      case 'order':
      case 'orders':
      case 'order_details':
      case 'orderDetails':
      case 'order-detail':
        await _openOrderFromPush(data);
        return;

      case 'orders_history':
      case 'ordersHistory':
      case 'order_history':
      case 'orderHistory':
        await _openOrdersHistoryFromPush(data);
        return;

      case 'notifications':
      case 'notification':
        await _openNotificationsPage();
        return;

      default:
        await _openNotificationsPage();
        return;
    }
  }

  void _openMainTab(int index) {
    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainNavigationPage(initialIndex: index),
      ),
      (route) => false,
    );
  }

  Future<void> _openNotificationsPage() async {
    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator == null) return;

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          onOpenOrder: _openOrderFromNotification,
        ),
      ),
    );
  }

  Future<void> _openOrdersHistoryFromPush(Map<String, String> data) async {
    final orderId = _readStringFromData(
      data,
      const ['orderId', 'order_id', 'orderID'],
    );

    final orderNumber = _readIntFromData(
      data,
      const ['orderNumber', 'order_number', 'number'],
    );

    await _openOrdersHistory(
      orderId: orderId.isEmpty ? null : orderId,
      orderNumber: orderNumber,
    );
  }

  Future<void> _openOrderFromPush(Map<String, String> data) async {
    final orderId = _readStringFromData(
      data,
      const ['orderId', 'order_id', 'orderID'],
    );

    final orderNumber = _readIntFromData(
      data,
      const ['orderNumber', 'order_number', 'number'],
    );

    await _openOrderFromNotification(
      orderId.isEmpty ? null : orderId,
      orderNumber,
    );
  }

  Future<void> _openOrderFromNotification(
    String? orderId,
    int? orderNumber,
  ) async {
    final normalizedOrderId = orderId?.trim() ?? '';

    if (normalizedOrderId.isNotEmpty) {
      await _openOrderDetails(normalizedOrderId);
      return;
    }

    if (orderNumber != null) {
      await _openOrdersHistory(orderNumber: orderNumber);
      return;
    }

    await _openNotificationsPage();
  }

  Future<void> _openOrderDetails(String orderId) async {
    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator == null) return;

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(orderId: orderId),
      ),
    );
  }

  Future<void> _openOrdersHistory({
    String? orderId,
    int? orderNumber,
  }) async {
    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator == null) return;

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => OrdersHistoryPage(
          initialOrderId: orderId,
          initialOrderNumber: orderNumber,
        ),
      ),
    );
  }

  String _readStringFromData(
    Map<String, String> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key]?.trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  int? _readIntFromData(
    Map<String, String> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = data[key]?.trim() ?? '';
      if (raw.isEmpty) continue;

      final parsed = int.tryParse(raw);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppLocalizationScope(
      language: _language,
      onLanguageChanged: _setLanguage,
      child: InAppNotificationsHost(
        onTapNotification: _handleNotificationTap,
        child: MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF489F2A),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          routes: {
            '/cart': (_) => const MainNavigationPage(initialIndex: 2),
            '/notifications': (_) => NotificationsPage(
                  onOpenOrder: _openOrderFromNotification,
                ),
          },
          home: const MainNavigationPage(),
        ),
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late int _currentIndex;

  late final List<Widget> _pages = [
    const HomePage(),
    const FavoritesPage(),
    const CartPage(),
    const ProfileEntryPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant MainNavigationPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      FavoritesController.instance.refreshIfStale();
    }

    if (index == 2) {
      CartRepository.instance.syncWithServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizationScope.of(context).strings;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDDF2D6),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: strings.navFavorites,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: strings.navCart,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: strings.navProfile,
          ),
        ],
      ),
    );
  }
}
