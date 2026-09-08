import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/addresses/data/addressRepository.dart';
import 'package:jetkiz_mobile/features/addresses/domain/address.dart';
import 'package:jetkiz_mobile/features/addresses/presentation/addressesPage.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';
import 'package:jetkiz_mobile/features/cart/domain/cartItem.dart';
import 'package:jetkiz_mobile/features/menu/data/financeConfigApi.dart';
import 'package:jetkiz_mobile/features/orders/data/orderApi.dart';
import 'package:jetkiz_mobile/features/orders/domain/createOrderPayload.dart';
import 'package:jetkiz_mobile/features/profile/data/profileApi.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentCheckoutApi.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentMethodsRepository.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentPendingStore.dart';
import 'package:jetkiz_mobile/features/payments/domain/paymentFlowState.dart';
import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentReturnPage.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const Color _green = Color(0xFF489F2A);
  static const Color _bg = Color(0xFFF7FAF5);

  final CartRepository _cartRepository = CartRepository.instance;
  final AddressRepository _addressRepository = AddressRepository.instance;

  late final FinanceConfigApi _financeConfigApi;
  late final ProfileApi _profileApi;
  late final OrderApi _orderApi;
  late final PaymentCheckoutApi _paymentCheckoutApi;
  final PaymentMethodsRepository _paymentMethodsRepository =
      PaymentMethodsRepository.instance;
  final PaymentPendingStore _paymentPendingStore = PaymentPendingStore();

  String? _selectedCardId;
  List<SavedPaymentCard> _savedCards = const [];
  bool _useNewCard = true;
  bool _saveNewCard = false;
  bool _isCardsLoading = true;
  String? _cardsError;
  int _deliveryFee = 0;
  bool _isDeliveryLoading = true;
  bool _hasDeliveryError = false;
  bool _isSubmitting = false;
  bool _orderPlaced = false;
  OrderFulfillmentType _fulfillmentType = OrderFulfillmentType.delivery;
  _CreatedOrderView? _createdOrder;
  String? _pendingOrderKey;
  String? _pendingOrderFingerprint;

  bool get _isPickup => _fulfillmentType == OrderFulfillmentType.pickup;

  int get _effectiveDeliveryFee => _isPickup ? 0 : _deliveryFee;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();
    _financeConfigApi = FinanceConfigApi(apiClient);
    _profileApi = ProfileApi(apiClient);
    _orderApi = OrderApi(apiClient);
    _paymentCheckoutApi = PaymentCheckoutApi(apiClient);

    _cartRepository.addListener(_handleExternalStateChanged);
    _addressRepository.addListener(_handleExternalStateChanged);
    _loadDeliveryFee();
    _loadSavedCards();
  }

  @override
  void dispose() {
    _cartRepository.removeListener(_handleExternalStateChanged);
    _addressRepository.removeListener(_handleExternalStateChanged);
    super.dispose();
  }

  void _handleExternalStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadDeliveryFee() async {
    try {
      final config = await _financeConfigApi.getFinanceConfig();

      if (!mounted) return;

      setState(() {
        _deliveryFee = config.activeDeliveryFee;
        _isDeliveryLoading = false;
        _hasDeliveryError = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isDeliveryLoading = false;
        _hasDeliveryError = true;
      });
    }
  }

  Future<void> _loadSavedCards() async {
    if (mounted) {
      setState(() {
        _isCardsLoading = true;
        _cardsError = null;
      });
    }

    try {
      final cards = await _paymentMethodsRepository.getSavedCards();
      if (!mounted) return;

      String? preferredId;
      for (final card in cards) {
        if (card.isDefault) {
          preferredId = card.id;
          break;
        }
      }
      preferredId ??= cards.isNotEmpty ? cards.first.id : null;

      setState(() {
        _savedCards = cards;
        _selectedCardId = preferredId;
        _useNewCard = cards.isEmpty;
        _isCardsLoading = false;
      });
    } on PaymentMethodsException catch (error) {
      if (!mounted) return;
      setState(() {
        _savedCards = const [];
        _selectedCardId = null;
        _useNewCard = true;
        _cardsError = error.message;
        _isCardsLoading = false;
      });
    }
  }

  Future<void> _changeAddress() async {
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

  Future<void> _handleConfirmOrder() async {
    final address = _addressRepository.selectedAddress;
    final cartState = _cartRepository.state;

    if (_isSubmitting || _orderPlaced) return;

    if (!_isPickup && _hasDeliveryError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: LocalizedText('Не удалось рассчитать доставку')),
      );
      return;
    }

    if (cartState.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('Корзина пуста')),
      );
      return;
    }

    if (!_isPickup && address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('Выберите адрес доставки')),
      );
      return;
    }

    if (!_useNewCard && _selectedCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('Выберите карту для оплаты')),
      );
      return;
    }

    final restaurantId = cartState.restaurantId;
    if (restaurantId == null || restaurantId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: LocalizedText('Не удалось определить ресторан заказа')),
      );
      return;
    }

    final addressId = _addressRepository.selectedAddressId;
    if (!_isPickup && (addressId == null || addressId.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: LocalizedText('Не удалось определить адрес доставки')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final syncResult = await _cartRepository.syncWithServer();

      if (syncResult.failed) {
        throw const _CheckoutBlockedException(
          'Не удалось обновить корзину. Проверьте интернет.',
        );
      }

      if (syncResult.priceChanged) {
        _cartRepository.consumePendingPriceUpdateNotification();

        if (mounted) {
          await _showPriceUpdatedDialog();
        }

        return;
      }

      if (_cartRepository.hasBlockingItems) {
        if (mounted) {
          await _showCartBlockedDialog();
        }

        return;
      }

      final profile = await _profileApi.getMe();

      final phone = profile.phone.trim();
      if (phone.isEmpty) {
        throw Exception('Phone is empty');
      }

      final orderItems = _cartRepository.toOrderItemsJson();

      final payload = CreateOrderPayload(
        restaurantId: restaurantId,
        fulfillmentType: _fulfillmentType,
        addressId: _isPickup ? null : addressId,
        phone: phone,
        leaveAtDoor: false,
        comment: null,
        promoCode: null,
        items: orderItems
            .map(
              (item) => CreateOrderItemPayload(
                productId: item['productId']?.toString() ?? '',
                quantity: item['quantity'] is int
                    ? item['quantity'] as int
                    : int.tryParse(item['quantity']?.toString() ?? '') ?? 0,
              ),
            )
            .toList(),
      );

      final fingerprint = payload.toJson().toString();
      if (_pendingOrderFingerprint != fingerprint || _pendingOrderKey == null) {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = Random.secure().nextInt(1 << 32);
        _pendingOrderFingerprint = fingerprint;
        _pendingOrderKey = 'client-order-$timestamp-$random';
      }

      final order = await _orderApi.createOrder(
        payload,
        idempotencyKey: _pendingOrderKey,
      );
      final createdOrder = _CreatedOrderView.fromJson(order);
      final orderId = createdOrder.id?.trim() ?? '';
      if (orderId.isEmpty) {
        throw const _CheckoutBlockedException(
          'Сервер не вернул номер созданного заказа',
        );
      }

      final checkout = await _paymentCheckoutApi.createCheckout(
        orderId: orderId,
        savedPaymentMethodId: _useNewCard ? null : _selectedCardId,
        saveCard: _useNewCard && _saveNewCard,
      );
      if (checkout.secureCheckoutUri == null || checkout.checkoutUrl.isEmpty) {
        throw const _CheckoutBlockedException(
          'Не удалось получить безопасную ссылку оплаты',
        );
      }

      await _paymentPendingStore.save(
        PendingPaymentReference(
          orderId: orderId,
          paymentId: checkout.paymentId,
        ),
      );

      if (!mounted) return;
      final paymentResult =
          await Navigator.of(context).push<PaymentReturnResult>(
        MaterialPageRoute(
          builder: (_) => PaymentReturnPage(
            orderId: orderId,
            checkoutUrl: checkout.checkoutUrl,
          ),
        ),
      );

      if (paymentResult != PaymentReturnResult.secured) {
        return;
      }

      _cartRepository.clear();
      if (!mounted) return;

      setState(() {
        _createdOrder = createdOrder;
        _orderPlaced = true;
      });
    } on _CheckoutBlockedException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: LocalizedText(error.message)),
      );
    } on PaymentCheckoutException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: LocalizedText(error.message)),
      );
    } on CreateOrderException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: LocalizedText(error.message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText('Не удалось создать заказ'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _showPriceUpdatedDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const LocalizedText('Цены обновились'),
          content: const LocalizedText('Цены на некоторые позиции изменились.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const LocalizedText('Понятно'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCartBlockedDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const LocalizedText('Не все блюда доступны'),
          content: const LocalizedText(
            'Удалите недоступные позиции из корзины, чтобы продолжить.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const LocalizedText('Понятно'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_orderPlaced) {
      return _CheckoutSuccessScreen(
        order: _createdOrder,
        onGoHome: _goHome,
      );
    }

    final cartState = _cartRepository.state;
    final items = cartState.items;
    final address = _addressRepository.selectedAddress;

    final subtotal = cartState.subtotal;
    final deliveryFee = _effectiveDeliveryFee;
    final total = subtotal + deliveryFee;
    final paymentStrings = PaymentStrings.of(context);

    final isConfirmDisabled = cartState.isEmpty ||
        (!_isPickup && address == null) ||
        (!_isPickup && _hasDeliveryError) ||
        _isCardsLoading ||
        (!_useNewCard && _selectedCardId == null) ||
        _isDeliveryLoading ||
        _isSubmitting;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Container(
            color: _green,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 18,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _isSubmitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Expanded(
                  child: LocalizedText(
                    'Оформление заказа',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  const _CheckoutSectionTitle(title: 'Способ получения'),
                  const SizedBox(height: 10),
                  _FulfillmentSelector(
                    value: _fulfillmentType,
                    enabled: !_isSubmitting,
                    onChanged: (value) {
                      setState(() {
                        _fulfillmentType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_isPickup) ...[
                    const _PickupInfoCard(),
                  ] else ...[
                    const _CheckoutSectionTitle(title: 'Адрес доставки'),
                    const SizedBox(height: 10),
                    _CheckoutAddressCard(
                      address: address,
                      onTap: _changeAddress,
                    ),
                  ],
                  const SizedBox(height: 18),
                  const _CheckoutSectionTitle(title: 'Ваш заказ'),
                  const SizedBox(height: 10),
                  _CheckoutItemsCard(items: items),
                  const SizedBox(height: 18),
                  const _CheckoutSectionTitle(title: 'Способ оплаты'),
                  const SizedBox(height: 10),
                  if (_isCardsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: CircularProgressIndicator(color: _green),
                      ),
                    )
                  else ...[
                    if (_cardsError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF0D9AD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF9A6A18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                paymentStrings.cardsLoadError,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B4A12),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadSavedCards,
                              child: Text(paymentStrings.retry),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ..._savedCards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CheckoutCardTile(
                          card: card,
                          isSelected:
                              !_useNewCard && _selectedCardId == card.id,
                          onTap: () {
                            if (_isSubmitting) return;
                            setState(() {
                              _useNewCard = false;
                              _selectedCardId = card.id;
                              _saveNewCard = false;
                            });
                          },
                        ),
                      ),
                    ),
                    _AddNewCardTile(
                      isSelected: _useNewCard,
                      onTap: () {
                        if (_isSubmitting) return;
                        setState(() {
                          _useNewCard = true;
                          _selectedCardId = null;
                        });
                      },
                    ),
                    if (_useNewCard) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _saveNewCard,
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                setState(() {
                                  _saveNewCard = value == true;
                                });
                              },
                        contentPadding: EdgeInsets.zero,
                        activeColor: _green,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          paymentStrings.saveCardForFuture,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          paymentStrings.secureProviderHint,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 18),
                  const _CheckoutSectionTitle(title: 'Итого'),
                  const SizedBox(height: 10),
                  _CheckoutSummaryCard(
                    subtotal: subtotal,
                    deliveryFee: deliveryFee,
                    total: total,
                    isDeliveryLoading: _isDeliveryLoading,
                  ),
                  if (!_isPickup && _hasDeliveryError) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isDeliveryLoading ? null : _loadDeliveryFee,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const LocalizedText('Повторить расчёт доставки'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _CheckoutBottomBar(
            total: total,
            isLoading: _isSubmitting,
            isDisabled: isConfirmDisabled,
            onConfirm: _handleConfirmOrder,
          ),
        ],
      ),
    );
  }
}

class _CheckoutBlockedException implements Exception {
  const _CheckoutBlockedException(this.message);

  final String message;
}

class _CheckoutSectionTitle extends StatelessWidget {
  const _CheckoutSectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return LocalizedText(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _FulfillmentSelector extends StatelessWidget {
  const _FulfillmentSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final OrderFulfillmentType value;
  final bool enabled;
  final ValueChanged<OrderFulfillmentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<OrderFulfillmentType>(
      segments: const [
        ButtonSegment(
          value: OrderFulfillmentType.delivery,
          icon: Icon(Icons.delivery_dining_rounded),
          label: LocalizedText('Доставка'),
        ),
        ButtonSegment(
          value: OrderFulfillmentType.pickup,
          icon: Icon(Icons.shopping_bag_outlined),
          label: LocalizedText('Самовывоз'),
        ),
      ],
      selected: {value},
      onSelectionChanged:
          enabled ? (selected) => onChanged(selected.first) : null,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: const Color(0xFFEAF7E4),
        selectedForegroundColor: const Color(0xFF489F2A),
      ),
    );
  }
}

class _PickupInfoCard extends StatelessWidget {
  const _PickupInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: Color(0xFF489F2A),
          ),
          SizedBox(width: 12),
          Expanded(
            child: LocalizedText(
              'Вы заберёте заказ из ресторана',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutAddressCard extends StatelessWidget {
  const _CheckoutAddressCard({
    required this.address,
    required this.onTap,
  });

  final Address? address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address != null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7E4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF489F2A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hasAddress
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText(
                            address!.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          LocalizedText(
                            address!.fullSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              height: 1.3,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText(
                            'Адрес не выбран',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 6),
                          LocalizedText(
                            'Нажмите, чтобы выбрать адрес доставки',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Color(0xFF489F2A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutItemsCard extends StatelessWidget {
  const _CheckoutItemsCard({
    required this.items,
  });

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const LocalizedText(
          'Корзина пуста',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _CheckoutItemRow(item: items[i]),
            if (i != items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutItemRow extends StatelessWidget {
  const _CheckoutItemRow({
    required this.item,
  });

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LocalizedText(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LocalizedText(
              '${item.totalPrice} ₸',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            LocalizedText(
              '${item.quantity} × ${item.price} ₸',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckoutCardTile extends StatelessWidget {
  const _CheckoutCardTile({
    required this.card,
    required this.isSelected,
    required this.onTap,
  });

  final SavedPaymentCard card;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF489F2A);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF2FAEE) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? green : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected ? green : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      card.brandLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    LocalizedText(
                      card.issuerBank == null
                          ? card.maskedNumber
                          : '${card.maskedNumber} • ${card.issuerBank}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? green : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? green : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: SizedBox(
                          width: 8,
                          height: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddNewCardTile extends StatelessWidget {
  const _AddNewCardTile({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFF2FAEE) : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF489F2A)
                  : const Color(0xFFD1D5DB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                color: Color(0xFF6B7280),
              ),
              SizedBox(width: 8),
              LocalizedText(
                'Добавить новую карту',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutSummaryCard extends StatelessWidget {
  const _CheckoutSummaryCard({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.isDeliveryLoading,
  });

  final int subtotal;
  final int deliveryFee;
  final int total;
  final bool isDeliveryLoading;

  @override
  Widget build(BuildContext context) {
    final deliveryText = isDeliveryLoading ? '...' : '$deliveryFee ₸';
    final totalText = isDeliveryLoading ? '...' : '$total ₸';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _CheckoutSummaryRow(
            label: 'Стоимость товаров',
            value: '$subtotal ₸',
          ),
          const SizedBox(height: 10),
          _CheckoutSummaryRow(
            label: 'Доставка',
            value: deliveryText,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _CheckoutSummaryRow(
            label: 'К оплате',
            value: totalText,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _CheckoutSummaryRow extends StatelessWidget {
  const _CheckoutSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LocalizedText(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? const Color(0xFF111827) : const Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        LocalizedText(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            color: isTotal ? const Color(0xFF489F2A) : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  const _CheckoutBottomBar({
    required this.total,
    required this.isLoading,
    required this.isDisabled,
    required this.onConfirm,
  });

  final int total;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isDisabled ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF489F2A),
              disabledBackgroundColor: const Color(0xFFBFC7BC),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LocalizedText(
                        'Оплатить',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      LocalizedText(
                        '$total ₸',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutSuccessScreen extends StatefulWidget {
  const _CheckoutSuccessScreen({
    required this.order,
    required this.onGoHome,
  });

  final _CreatedOrderView? order;
  final VoidCallback onGoHome;

  @override
  State<_CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<_CheckoutSuccessScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(seconds: 3),
      widget.onGoHome,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickupCode = widget.order?.pickupCode?.trim();
    final hasPickupCode = pickupCode != null && pickupCode.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7E4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 70,
                  color: Color(0xFF489F2A),
                ),
              ),
              const SizedBox(height: 20),
              const LocalizedText(
                'Заказ оформлен',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              const LocalizedText(
                'Ожидайте звонка от ресторана для подтверждения',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              if (hasPickupCode) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD7EFD0)),
                  ),
                  child: Column(
                    children: [
                      LocalizedText(
                        'Код самовывоза: $pickupCode',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const LocalizedText(
                        'Покажите этот код сотруднику ресторана',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: widget.onGoHome,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF489F2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const LocalizedText(
                  'На главную',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatedOrderView {
  const _CreatedOrderView({
    required this.id,
    required this.pickupCode,
  });

  final String? id;
  final String? pickupCode;

  factory _CreatedOrderView.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim() ?? '';
    final rawPickup = json['pickupCode']?.toString().trim() ?? '';

    return _CreatedOrderView(
      id: rawId.isEmpty || rawId.toLowerCase() == 'null' ? null : rawId,
      pickupCode: rawPickup.isEmpty || rawPickup.toLowerCase() == 'null'
          ? null
          : rawPickup,
    );
  }
}
