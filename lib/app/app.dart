import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/config/appConfig.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/features/auth/presentation/profileEntryPage.dart';
import 'package:jetkiz_mobile/features/cart/presentation/cartPage.dart';
import 'package:jetkiz_mobile/features/favorites/presentation/favoritesPage.dart';
import 'package:jetkiz_mobile/features/home/presentation/homePage.dart';
import 'package:jetkiz_mobile/features/notifications/domain/notificationItem.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/notificationsPage.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/widgets/inAppNotificationsHost.dart';
import 'package:jetkiz_mobile/features/orders/presentation/ordersHistoryPage.dart';

class JetkizApp extends StatefulWidget {
  const JetkizApp({super.key});

  @override
  State<JetkizApp> createState() => _JetkizAppState();
}

class _JetkizAppState extends State<JetkizApp> {
  AppLanguage _language = AppLanguage.ru;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  void _setLanguage(AppLanguage language) {
    if (_language == language) return;

    setState(() {
      _language = language;
    });
  }

  /// ЕДИНСТВЕННЫЙ обработчик уведомлений во всём приложении
  Future<void> _handleNotificationTap(NotificationItem item) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    final orderId = (item.orderId ?? '').trim();
    final orderNumber = item.orderNumber;

    if (orderId.isNotEmpty || orderNumber != null) {
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => OrdersHistoryPage(
            initialOrderId: orderId.isEmpty ? null : orderId,
            initialOrderNumber: orderNumber,
          ),
        ),
      );
      return;
    }

    navigator.pushNamed('/notifications');
  }

  @override
  Widget build(BuildContext context) {
    return AppLocalizationScope(
      language: _language,
      onLanguageChanged: _setLanguage,
      child: InAppNotificationsHost(
        onTapNotification: _handleNotificationTap,
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF7A00),
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

            /// ВАЖНО: убрали лишнюю логику, оставили чистый переход
            '/notifications': (_) => NotificationsPage(
                  onOpenOrder: (orderId, orderNumber) {
                    final nav = _navigatorKey.currentState;
                    if (nav == null) return;

                    nav.push(
                      MaterialPageRoute(
                        builder: (_) => OrdersHistoryPage(
                          initialOrderId: orderId,
                          initialOrderNumber: orderNumber,
                        ),
                      ),
                    );
                  },
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
    ProfileEntryPage(),
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