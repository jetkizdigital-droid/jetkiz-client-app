import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/addresses/data/addressRepository.dart';
import 'package:jetkiz_mobile/features/addresses/domain/address.dart';
import 'package:jetkiz_mobile/features/addresses/presentation/addressesPage.dart';
import 'package:jetkiz_mobile/features/checkout/presentation/checkoutPage.dart';
import 'package:jetkiz_mobile/features/menu/data/financeConfigApi.dart';

import '../data/cartRepository.dart';
import '../domain/cartItem.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const Color _green = Color(0xFF489F2A);
  static const Color _bg = Color(0xFFF9FAFB);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  final CartRepository _cart = CartRepository.instance;
  final AddressRepository _addressRepository = AddressRepository.instance;

  late final ApiClient _apiClient;
  late final FinanceConfigApi _financeConfigApi;

  int _deliveryFee = 0;
  bool _isDeliveryLoading = true;
  bool _isCheckoutStarting = false;

  bool get _requiresAddressBeforeCheckout => false;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient();
    _financeConfigApi = FinanceConfigApi(_apiClient);

    _cart.addListener(_handleCartChanged);
    _addressRepository.addListener(_handleAddressChanged);

    _loadDeliveryFee();
    _trackCartView();
  }

  @override
  void dispose() {
    _cart.removeListener(_handleCartChanged);
    _addressRepository.removeListener(_handleAddressChanged);
    super.dispose();
  }

  void _handleCartChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleAddressChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadDeliveryFee() async {
    setState(() {
      _isDeliveryLoading = true;
    });

    try {
      final config = await _financeConfigApi.getFinanceConfig();

      if (!mounted) return;

      setState(() {
        _deliveryFee = config.activeDeliveryFee;
        _isDeliveryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _deliveryFee = 0;
        _isDeliveryLoading = false;
      });

      _showSnackBar('Не удалось загрузить стоимость доставки');
    }
  }

  Future<void> _trackCartView() async {
    try {
      await _apiClient.dio.post(
        '/client-events',
        data: {
          'eventName': 'screen_view',
          'metadata': {
            'source': 'cart_page',
            'screen': 'cart',
            'restaurantId': _cart.restaurantId,
            'itemsCount': _cart.totalQuantity,
            'subtotal': _cart.subtotal,
          },
        },
      );
    } catch (_) {}
  }

  Future<void> _trackCheckoutStart({
    Address? address,
    required int subtotal,
    required int deliveryFee,
    required int total,
  }) async {
    try {
      await _apiClient.dio.post(
        '/client-events',
        data: {
          'eventName': 'checkout_start',
          'metadata': {
            'source': 'cart_page',
            'restaurantId': _cart.restaurantId,
            if (address != null) 'addressId': address.id,
            'itemsCount': _cart.totalQuantity,
            'subtotal': subtotal,
            'deliveryFee': deliveryFee,
            'total': total,
          },
        },
      );
    } catch (_) {}
  }

  Future<void> _openAddressPicker() async {
    final selected = await Navigator.of(context).push<Address>(
      MaterialPageRoute(
        builder: (_) => AddressesPage(
          selectionMode: true,
          initialSelectedAddressId: _addressRepository.selectedAddressId,
        ),
      ),
    );

    if (selected == null || !mounted) return;

    _addressRepository.setSelectedAddress(selected);
  }

  Future<void> _confirmRemove(CartItem item) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить товар?'),
          content: Text('Удалить "${item.title}" из корзины?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Нет'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      _cart.remove(item.productId);
    }
  }

  Future<void> _confirmClearCart() async {
    if (_cart.isEmpty) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Очистить корзину?'),
          content: const Text('Все товары будут удалены из корзины.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      _cart.clear();
    }
  }

  void _goToHomeTab() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _handleCheckout() async {
    if (_cart.isEmpty || _isCheckoutStarting) return;

    if (_isDeliveryLoading) {
      _showSnackBar('Подождите, загружается стоимость доставки');
      return;
    }

    final selectedAddress = _addressRepository.selectedAddress;

    if (_requiresAddressBeforeCheckout && selectedAddress == null) {
      _showSnackBar('Сначала выберите адрес доставки');
      await _openAddressPicker();
      return;
    }

    final restaurantId = _cart.restaurantId?.trim() ?? '';
    if (restaurantId.isEmpty) {
      _showSnackBar('Не удалось определить ресторан');
      return;
    }

    final subtotal = _cart.subtotal;
    final total = subtotal + _deliveryFee;

    setState(() {
      _isCheckoutStarting = true;
    });

    await _trackCheckoutStart(
      address: selectedAddress,
      subtotal: subtotal,
      deliveryFee: _deliveryFee,
      total: total,
    );

    if (!mounted) return;

    setState(() {
      _isCheckoutStarting = false;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CheckoutPage(),
      ),
    );
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;
    final selectedAddress = _addressRepository.selectedAddress;
    final subtotal = _cart.subtotal;
    final total = subtotal + _deliveryFee;
    final isEmpty = _cart.isEmpty;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Корзина',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isEmpty)
            IconButton(
              onPressed: _confirmClearCart,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Очистить корзину',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDeliveryFee,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: _CartAddressCard(
                selectedAddress: selectedAddress,
                onTap: _openAddressPicker,
              ),
            ),
            Expanded(
              child: isEmpty
                  ? _EmptyCart(
                      onGoHome: _goToHomeTab,
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return _CartItemCard(
                          item: item,
                          onMinus: () => _cart.decrement(item.productId),
                          onPlus: () => _cart.increment(item.productId),
                          onRemove: () => _confirmRemove(item),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: items.length,
                    ),
            ),
            _CartSummary(
              subtotal: subtotal,
              deliveryFee: _deliveryFee,
              total: total,
              isLoading: _isDeliveryLoading,
              isCheckoutStarting: _isCheckoutStarting,
              isDisabled: isEmpty || _isDeliveryLoading,
              onCheckout: _handleCheckout,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartAddressCard extends StatelessWidget {
  const _CartAddressCard({
    required this.selectedAddress,
    required this.onTap,
  });

  final Address? selectedAddress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAddress = selectedAddress != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF45A049),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A4CAF50),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: hasAddress
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedAddress!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedAddress!.fullSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Адрес доставки',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Укажите адрес доставки',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                size: 26,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if ((item.description ?? '').trim().isNotEmpty) item.description!.trim(),
      if ((item.weight ?? '').trim().isNotEmpty) item.weight!.trim(),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 96,
              height: 96,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (subtitleParts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitleParts.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.2,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.totalPrice} ₸',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _QuantityControl(
                        quantity: item.quantity,
                        onMinus: onMinus,
                        onPlus: onPlus,
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onRemove,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(
          Icons.fastfood_rounded,
          color: Color(0xFF9CA3AF),
          size: 28,
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantitySquareButton(
            icon: Icons.remove,
            onTap: onMinus,
            filled: false,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF111827),
              ),
            ),
          ),
          _QuantitySquareButton(
            icon: Icons.add,
            onTap: onPlus,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _QuantitySquareButton extends StatelessWidget {
  const _QuantitySquareButton({
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : const Color(0xFF374151),
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.isLoading,
    required this.isCheckoutStarting,
    required this.isDisabled,
    required this.onCheckout,
  });

  final int subtotal;
  final int deliveryFee;
  final int total;
  final bool isLoading;
  final bool isCheckoutStarting;
  final bool isDisabled;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final deliveryValue = isLoading ? '...' : '$deliveryFee ₸';
    final totalValue = isLoading ? '...' : '$total ₸';
    final disabled = isDisabled || isCheckoutStarting;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CompactSummaryRow(
              label: 'Сумма',
              value: '$subtotal ₸',
            ),
            const SizedBox(height: 6),
            _CompactSummaryRow(
              label: 'Доставка',
              value: deliveryValue,
            ),
            const SizedBox(height: 14),
            Opacity(
              opacity: disabled ? 0.55 : 1,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: disabled ? null : onCheckout,
                  borderRadius: BorderRadius.circular(20),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4CAF50),
                          Color(0xFF45A049),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A4CAF50),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCheckoutStarting) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          isCheckoutStarting
                              ? 'Переходим...'
                              : 'Оформить заказ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            totalValue,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactSummaryRow extends StatelessWidget {
  const _CompactSummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({
    required this.onGoHome,
  });

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 70, 16, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 40,
                  color: Color(0xFFB0B7C3),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Корзина пуста',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Добавьте блюда из меню',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGoHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF489F2A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'На главную',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
