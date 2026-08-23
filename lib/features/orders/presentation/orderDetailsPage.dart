import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/support/supportLauncher.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';
import 'package:jetkiz_mobile/features/orders/data/ordersApi.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderDetailsData.dart';
import 'package:jetkiz_mobile/features/menu/presentation/restaurantMenuPage.dart';
import 'package:jetkiz_mobile/features/reviews/presentation/createReviewPage.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  static const _green = Color(0xFF489F2A);
  static const _bg = Color(0xFFF9FAFB);
  static const _cardBorder = Color(0xFFF3F4F6);
  static const _textMain = Color(0xFF1F2937);
  static const _textMuted = Color(0xFF6B7280);
  static const _textLight = Color(0xFF9CA3AF);

  late final OrdersApi _ordersApi;

  OrderDetailsData? _order;
  bool _isLoading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _ordersApi = OrdersApi(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final order = await _ordersApi.getOrderById(widget.orderId);

      if (!mounted) return;

      setState(() {
        _order = order;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText =
            'Не удалось загрузить детали заказа';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _repeatOrder() async {
    final order = _order;
    if (order == null) return;

    final restaurantId = order.restaurant?.id ?? '';
    if (restaurantId.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
              'Не удалось определить ресторан заказа'),
        ),
      );
      return;
    }

    final cart = CartRepository.instance;
    if (cart.hasRestaurant && !cart.belongsToRestaurant(restaurantId)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Заменить товары в корзине?'),
          content: const Text('В корзине уже есть блюда другого ресторана.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Заменить'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (replace != true) return;
      cart.clear();
    }

    var addedCount = 0;
    for (final item in order.items) {
      final result = cart.addItem(
        productId: item.productId,
        restaurantId: restaurantId,
        title: item.title,
        price: item.price,
        quantity: item.quantity,
      );
      if (result == CartAddResult.added || result == CartAddResult.updated) {
        addedCount++;
      }
    }

    if (addedCount == 0) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Не удалось повторить заказ')),
      );
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text(
            'Добавлено в корзину'),
      ),
    );

    Navigator.of(context).pushNamed('/cart');
  }

  Future<void> _leaveReview() async {
    final order = _order;
    if (order == null) return;

    final restaurantName = order.restaurant?.nameRu.trim().isNotEmpty == true
        ? order.restaurant!.nameRu
        : 'Ресторан';

    final firstItem = order.items.isNotEmpty ? order.items.first : null;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateReviewPage(
          orderId: order.id,
          restaurantName: restaurantName,
          restaurantImageUrl: order.restaurant?.resolvedCoverImageUrl,
          orderItemTitle: firstItem?.title,
          orderItemPrice: firstItem?.price,
        ),
      ),
    );

    if (created == true && mounted) {
      await _load();
    }
  }

  void _openRestaurant() {
    final restaurant = _order?.restaurant;
    if (restaurant == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantMenuPage(
          restaurantId: restaurant.id,
          restaurantName: restaurant.nameRu,
          restaurantImageUrl: restaurant.resolvedCoverImageUrl,
        ),
      ),
    );
  }

  Future<void> _openSupport() async {
    await SupportLauncher.openWhatsApp(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _OrderDetailsLoadingView();
    }

    if (_errorText != null) {
      return _OrderDetailsErrorView(
        message: _errorText!,
        onRetry: _load,
      );
    }

    final order = _order;
    if (order == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text(
            'Заказ не найден',
            style: TextStyle(
              color: _textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final statusUi = _resolveStatusUi(
      order.status,
      fulfillmentType: order.fulfillmentType,
    );

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _DetailsHeader(
              number: order.number,
              onBackTap: () => Navigator.of(context).maybePop(),
              onSupportTap: _openSupport,
            ),
            Expanded(
              child: RefreshIndicator(
                color: _green,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    _StatusBlock(
                      statusUi: statusUi,
                      orderDateText: _formatDateTime(order.createdAt),
                      paymentStatusText:
                          _paymentStatusLabel(order.paymentStatus),
                    ),
                    const SizedBox(height: 16),
                    if (order.restaurant != null) ...[
                      _RestaurantBlock(
                        restaurant: order.restaurant!,
                        onOpenRestaurant: _openRestaurant,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _DeliveryInfoBlock(order: order),
                    const SizedBox(height: 16),
                    if (order.isPickup) ...[
                      _PickupCodeBlock(order: order),
                      const SizedBox(height: 16),
                    ],
                    _OrderItemsBlock(items: order.items),
                    const SizedBox(height: 16),
                    _PriceSummaryBlock(order: order),
                    const SizedBox(height: 18),
                    _ActionButtonsBlock(
                      canLeaveReview: order.canLeaveReview,
                      onRepeatOrder: _repeatOrder,
                      onLeaveReview: _leaveReview,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    const months = <int, String>{
      1: 'января',
      2: 'февраля',
      3: 'марта',
      4: 'апреля',
      5: 'мая',
      6: 'июня',
      7: 'июля',
      8: 'августа',
      9: 'сентября',
      10: 'октября',
      11: 'ноября',
      12: 'декабря',
    };

    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.day} ${months[value.month] ?? ''} ${value.year} в ${two(value.hour)}:${two(value.minute)}';
  }

  static String _paymentStatusLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'PAID':
        return 'Оплачено';
      case 'PENDING':
        return 'Оплачено';
      case 'FAILED':
        return 'Ошибка оплаты';
      case 'REFUNDED':
        return 'Возврат средств';
      default:
        return raw.trim().isEmpty
            ? 'Статус оплаты неизвестен'
            : raw;
    }
  }

  static _StatusUi _resolveStatusUi(
    String raw, {
    String? fulfillmentType,
  }) {
    final status = raw.toUpperCase();
    final isPickup = fulfillmentType?.trim().toUpperCase() == 'PICKUP';

    if (isPickup && status == 'READY') {
      return const _StatusUi(
        label: 'Можно забирать',
        bgColor: Color(0xFFE6F0FF),
        textColor: Color(0xFF2B6CB0),
        icon: Icons.shopping_bag_outlined,
      );
    }

    if (isPickup && status == 'DELIVERED') {
      return const _StatusUi(
        label: 'Получен',
        bgColor: Color(0xFFF3F4F6),
        textColor: Color(0xFF4B5563),
        icon: Icons.check_circle_rounded,
      );
    }

    if ([
      'CREATED',
      'ACCEPTED',
      'COOKING',
      'READY',
      'ON_THE_WAY',
    ].contains(status)) {
      return const _StatusUi(
        label: 'В пути',
        bgColor: _green,
        textColor: Colors.white,
        icon: Icons.access_time_rounded,
      );
    }

    if (status == 'DELIVERED' || status == 'PAID') {
      return const _StatusUi(
        label: 'Доставлен',
        bgColor: Color(0xFFF3F4F6),
        textColor: Color(0xFF4B5563),
        icon: Icons.check_circle_rounded,
      );
    }

    if (status == 'CANCELED') {
      return const _StatusUi(
        label: 'Отменён',
        bgColor: Color(0xFFFEF2F2),
        textColor: Color(0xFFDC2626),
        icon: Icons.cancel_rounded,
      );
    }

    return const _StatusUi(
      label: 'Статус',
      bgColor: Color(0xFFF3F4F6),
      textColor: Color(0xFF4B5563),
      icon: Icons.info_outline_rounded,
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.number,
    required this.onBackTap,
    required this.onSupportTap,
  });

  final int number;
  final VoidCallback onBackTap;
  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBackTap,
          ),
          Expanded(
            child: Text(
              'Заказ №$number',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _OrderDetailsPageState._textMain,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: onSupportTap,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: _OrderDetailsPageState._textMain,
        ),
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.statusUi,
    required this.orderDateText,
    required this.paymentStatusText,
  });

  final _StatusUi statusUi;
  final String orderDateText;
  final String paymentStatusText;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: statusUi.bgColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusUi.icon,
                    size: 22,
                    color: statusUi.textColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusUi.label,
                    style: TextStyle(
                      color: statusUi.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: _OrderDetailsPageState._textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  orderDateText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _OrderDetailsPageState._textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: _OrderDetailsPageState._green,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  paymentStatusText,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _OrderDetailsPageState._green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestaurantBlock extends StatelessWidget {
  const _RestaurantBlock({
    required this.restaurant,
    required this.onOpenRestaurant,
  });

  final OrderDetailsRestaurant restaurant;
  final VoidCallback onOpenRestaurant;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              _NetworkImageOrPlaceholder(
                imageUrl: restaurant.resolvedCoverImageUrl,
                width: 80,
                height: 80,
                borderRadius: 14,
                placeholderIcon: Icons.storefront_rounded,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.store_rounded,
                          size: 16,
                          color: _OrderDetailsPageState._textLight,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ресторан',
                          style: TextStyle(
                            fontSize: 13,
                            color: _OrderDetailsPageState._textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      restaurant.nameRu,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _OrderDetailsPageState._textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onOpenRestaurant,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF9FAFB),
                foregroundColor: _OrderDetailsPageState._textMain,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Открыть ресторан',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryInfoBlock extends StatelessWidget {
  const _DeliveryInfoBlock({
    required this.order,
  });

  final OrderDetailsData order;

  @override
  Widget build(BuildContext context) {
    final address = order.address;

    return _SectionCard(
      child: Column(
        children: [
          if (order.isPickup)
            _InfoTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _OrderDetailsPageState._green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 20,
                  color: _OrderDetailsPageState._green,
                ),
              ),
              title: 'Самовывоз',
              value:
                  'Самовывоз из ресторана',
            ),
          if (address != null)
            _InfoTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _OrderDetailsPageState._green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: _OrderDetailsPageState._green,
                ),
              ),
              title: 'Адрес доставки',
              value: address.formatted,
            ),
          if (order.comment != null && order.comment!.trim().isNotEmpty) ...[
            if (address != null || order.isPickup) const _ThinDivider(),
            _InfoTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notes_rounded,
                  size: 20,
                  color: _OrderDetailsPageState._textMuted,
                ),
              ),
              title: 'Комментарий',
              value: order.comment!.trim(),
            ),
          ],
          if (order.promisedAt != null) ...[
            if ((address != null) ||
                order.isPickup ||
                (order.comment != null && order.comment!.trim().isNotEmpty))
              const _ThinDivider(),
            _InfoTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: Color(0xFFF97316),
                ),
              ),
              title: 'Время доставки',
              value: _OrderDetailsPageState._formatDateTime(order.promisedAt!),
            ),
          ],
          if (address == null &&
              !order.isPickup &&
              (order.comment == null || order.comment!.trim().isEmpty) &&
              order.promisedAt == null)
            const Text(
              'Информация о доставке недоступна',
              style: TextStyle(
                fontSize: 14,
                color: _OrderDetailsPageState._textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _PickupCodeBlock extends StatelessWidget {
  const _PickupCodeBlock({
    required this.order,
  });

  final OrderDetailsData order;

  @override
  Widget build(BuildContext context) {
    final code = order.pickupCode?.trim() ?? '';
    final value = order.isDelivered
        ? 'Заказ получен'
        : code.isEmpty
            ? 'Код самовывоза недоступен'
            : code;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 20,
                color: _OrderDetailsPageState._green,
              ),
              SizedBox(width: 8),
              Text(
                'Самовывоз',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _OrderDetailsPageState._textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Код самовывоза',
            style: TextStyle(
              fontSize: 13,
              color: _OrderDetailsPageState._textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: code.isEmpty ? 15 : 28,
              color: _OrderDetailsPageState._textMain,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          if (code.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Покажите этот код сотруднику ресторана',
              style: TextStyle(
                fontSize: 13,
                color: _OrderDetailsPageState._textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemsBlock extends StatelessWidget {
  const _OrderItemsBlock({
    required this.items,
  });

  final List<OrderDetailsItem> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _OrderDetailsPageState._green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Состав заказа',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _OrderDetailsPageState._textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Text(
              'Позиции заказа недоступны',
              style: TextStyle(
                fontSize: 14,
                color: _OrderDetailsPageState._textMuted,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  if (index > 0) const _ThinDivider(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            color: _OrderDetailsPageState._textMain,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Количество: ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _OrderDetailsPageState._textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item.lineTotal} ₸',
                        style: const TextStyle(
                          fontSize: 15,
                          color: _OrderDetailsPageState._textMain,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _PriceSummaryBlock extends StatelessWidget {
  const _PriceSummaryBlock({
    required this.order,
  });

  final OrderDetailsData order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _OrderDetailsPageState._green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Детали оплаты',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _OrderDetailsPageState._textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PriceRow(
            title:
                'Стоимость товаров',
            value: '${order.subtotal} ₸',
          ),
          const SizedBox(height: 10),
          _PriceRow(
            title: order.isPickup
                ? 'Самовывоз'
                : 'Доставка',
            value: order.isPickup
                ? '0 ₸'
                : order.deliveryFee == 0
                    ? 'Бесплатно'
                    : '${order.deliveryFee} ₸',
          ),
          if (order.finalDiscount > 0) ...[
            const SizedBox(height: 10),
            _PriceRow(
              title: 'Скидка',
              value: '-${order.finalDiscount} ₸',
              valueColor: _OrderDetailsPageState._green,
              titleColor: _OrderDetailsPageState._green,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: Color(0xFFE5E7EB),
            ),
          ),
          _PriceRow(
            title: 'Итого',
            value: '${order.total} ₸',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _ActionButtonsBlock extends StatelessWidget {
  const _ActionButtonsBlock({
    required this.canLeaveReview,
    required this.onRepeatOrder,
    required this.onLeaveReview,
  });

  final bool canLeaveReview;
  final VoidCallback onRepeatOrder;
  final VoidCallback onLeaveReview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onRepeatOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _OrderDetailsPageState._green,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'Повторить заказ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (canLeaveReview) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onLeaveReview,
              style: OutlinedButton.styleFrom(
                foregroundColor: _OrderDetailsPageState._green,
                side: const BorderSide(
                  color: _OrderDetailsPageState._green,
                  width: 2,
                ),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Оставить отзыв',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _OrderDetailsPageState._cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.leading,
    required this.title,
    required this.value,
  });

  final Widget leading;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _OrderDetailsPageState._textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _OrderDetailsPageState._textMain,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        color: Color(0xFFF3F4F6),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.title,
    required this.value,
    this.titleColor,
    this.valueColor,
    this.isTotal = false,
  });

  final String title;
  final String value;
  final Color? titleColor;
  final Color? valueColor;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 18 : 15,
              color: titleColor ?? _OrderDetailsPageState._textMuted,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 26 : 15,
            color: valueColor ?? _OrderDetailsPageState._textMain,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NetworkImageOrPlaceholder extends StatelessWidget {
  const _NetworkImageOrPlaceholder({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.placeholderIcon,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();

    if (url.isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        placeholderIcon,
        color: const Color(0xFF9CA3AF),
        size: 28,
      ),
    );
  }
}

class _OrderDetailsLoadingView extends StatelessWidget {
  const _OrderDetailsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OrderDetailsPageState._bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: List.generate(
            5,
            (index) => Container(
              height: index == 0 ? 120 : 150,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _OrderDetailsPageState._cardBorder),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderDetailsErrorView extends StatelessWidget {
  const _OrderDetailsErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OrderDetailsPageState._bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _OrderDetailsPageState._textMain,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusUi {
  const _StatusUi({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData icon;
}
