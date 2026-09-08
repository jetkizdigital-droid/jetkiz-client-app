from pathlib import Path

checkout_path = Path('lib/features/checkout/presentation/checkoutPage.dart')
text = checkout_path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly 1 match, got {count}')
    text = text.replace(old, new, 1)


replace_once(
    "import 'package:jetkiz_mobile/core/localization/localizedText.dart';\nimport 'package:flutter/foundation.dart';\nimport 'package:jetkiz_mobile/core/network/apiClient.dart';",
    "import 'package:jetkiz_mobile/core/localization/localizedText.dart';\nimport 'package:jetkiz_mobile/core/network/apiClient.dart';",
    'remove debug/release stub import',
)

replace_once(
    "import 'package:jetkiz_mobile/features/profile/data/profileApi.dart';",
    "import 'package:jetkiz_mobile/features/profile/data/profileApi.dart';\n"
    "import 'package:jetkiz_mobile/features/payments/data/paymentCheckoutApi.dart';\n"
    "import 'package:jetkiz_mobile/features/payments/data/paymentMethodsRepository.dart';\n"
    "import 'package:jetkiz_mobile/features/payments/data/paymentPendingStore.dart';\n"
    "import 'package:jetkiz_mobile/features/payments/domain/paymentFlowState.dart';\n"
    "import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';\n"
    "import 'package:jetkiz_mobile/features/payments/presentation/paymentReturnPage.dart';\n"
    "import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';",
    'payment imports',
)

replace_once(
    "  late final FinanceConfigApi _financeConfigApi;\n"
    "  late final ProfileApi _profileApi;\n"
    "  late final OrderApi _orderApi;\n\n"
    "  int? _selectedCardId;",
    "  late final FinanceConfigApi _financeConfigApi;\n"
    "  late final ProfileApi _profileApi;\n"
    "  late final OrderApi _orderApi;\n"
    "  late final PaymentCheckoutApi _paymentCheckoutApi;\n"
    "  final PaymentMethodsRepository _paymentMethodsRepository =\n"
    "      PaymentMethodsRepository.instance;\n"
    "  final PaymentPendingStore _paymentPendingStore = PaymentPendingStore();\n\n"
    "  String? _selectedCardId;\n"
    "  List<SavedPaymentCard> _savedCards = const [];\n"
    "  bool _useNewCard = true;\n"
    "  bool _saveNewCard = false;\n"
    "  bool _isCardsLoading = true;\n"
    "  String? _cardsError;",
    'payment fields',
)

hardcoded_cards = """\n  final List<_CheckoutCard> _savedCards = const [\n    _CheckoutCard(\n      id: 1,\n      maskedNumber: '**** **** **** 4242',\n      type: 'Visa',\n      expiry: '12/25',\n    ),\n    _CheckoutCard(\n      id: 2,\n      maskedNumber: '**** **** **** 8888',\n      type: 'Mastercard',\n      expiry: '08/26',\n    ),\n  ];\n"""
replace_once(hardcoded_cards, "\n", 'remove fake cards')

replace_once(
    "    _orderApi = OrderApi(apiClient);\n\n"
    "    _selectedCardId = _savedCards.isNotEmpty ? _savedCards.first.id : null;\n"
    "    _cartRepository.addListener(_handleExternalStateChanged);",
    "    _orderApi = OrderApi(apiClient);\n"
    "    _paymentCheckoutApi = PaymentCheckoutApi(apiClient);\n\n"
    "    _cartRepository.addListener(_handleExternalStateChanged);",
    'init payment api',
)

replace_once(
    "    _loadDeliveryFee();\n  }",
    "    _loadDeliveryFee();\n"
    "    _loadSavedCards();\n"
    "  }",
    'load saved cards in init',
)

load_fee_anchor = """  Future<void> _changeAddress() async {\n"""
load_cards_method = """  Future<void> _loadSavedCards() async {\n    if (mounted) {\n      setState(() {\n        _isCardsLoading = true;\n        _cardsError = null;\n      });\n    }\n\n    try {\n      final cards = await _paymentMethodsRepository.getSavedCards();\n      if (!mounted) return;\n\n      String? preferredId;\n      for (final card in cards) {\n        if (card.isDefault) {\n          preferredId = card.id;\n          break;\n        }\n      }\n      preferredId ??= cards.isNotEmpty ? cards.first.id : null;\n\n      setState(() {\n        _savedCards = cards;\n        _selectedCardId = preferredId;\n        _useNewCard = cards.isEmpty;\n        _isCardsLoading = false;\n      });\n    } on PaymentMethodsException catch (error) {\n      if (!mounted) return;\n      setState(() {\n        _savedCards = const [];\n        _selectedCardId = null;\n        _useNewCard = true;\n        _cardsError = error.message;\n        _isCardsLoading = false;\n      });\n    }\n  }\n\n  Future<void> _changeAddress() async {\n"""
replace_once(load_fee_anchor, load_cards_method, 'saved cards loader')

release_stub = """    // Never allow the temporary client-side payment stub to create a real\n    // unpaid order in a production build.\n    if (kReleaseMode) {\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(\n          content: LocalizedText('Оплата временно недоступна'),\n        ),\n      );\n      return;\n    }\n\n"""
replace_once(release_stub, '', 'remove release payment block')

replace_once(
    "    if (_selectedCardId == null) {\n"
    "      ScaffoldMessenger.of(context).showSnackBar(\n"
    "        const SnackBar(content: LocalizedText('Выберите карту для оплаты')),\n"
    "      );\n"
    "      return;\n"
    "    }",
    "    if (!_useNewCard && _selectedCardId == null) {\n"
    "      ScaffoldMessenger.of(context).showSnackBar(\n"
    "        const SnackBar(content: LocalizedText('Выберите карту для оплаты')),\n"
    "      );\n"
    "      return;\n"
    "    }",
    'payment selection validation',
)

fake_delay = """      /// ВАЖНО:\n      /// Payment provider/backend пока не подключён.\n      /// Здесь временно используется client-side positive payment stub,\n      /// после которого создаётся реальный заказ через POST /orders.\n      ///\n      /// Когда backend payment flow будет подтверждён, этот участок нужно\n      /// заменить на:\n      /// 1. create payment session / intent\n      /// 2. confirm payment\n      /// 3. create order после успешного payment result\n      await Future<void>.delayed(const Duration(milliseconds: 800));\n\n"""
replace_once(fake_delay, '', 'remove fake payment delay')

old_post_order = """      final order = await _orderApi.createOrder(\n        payload,\n        idempotencyKey: _pendingOrderKey,\n      );\n\n      _cartRepository.clear();\n\n      if (!mounted) return;\n\n      setState(() {\n        _createdOrder = _CreatedOrderView.fromJson(order);\n        _orderPlaced = true;\n      });\n"""
new_post_order = """      final order = await _orderApi.createOrder(\n        payload,\n        idempotencyKey: _pendingOrderKey,\n      );\n      final createdOrder = _CreatedOrderView.fromJson(order);\n      final orderId = createdOrder.id?.trim() ?? '';\n      if (orderId.isEmpty) {\n        throw const _CheckoutBlockedException(\n          'Сервер не вернул номер созданного заказа',\n        );\n      }\n\n      final checkout = await _paymentCheckoutApi.createCheckout(\n        orderId: orderId,\n        savedPaymentMethodId: _useNewCard ? null : _selectedCardId,\n        saveCard: _useNewCard && _saveNewCard,\n      );\n      if (checkout.secureCheckoutUri == null || checkout.checkoutUrl.isEmpty) {\n        throw const _CheckoutBlockedException(\n          'Не удалось получить безопасную ссылку оплаты',\n        );\n      }\n\n      await _paymentPendingStore.save(\n        PendingPaymentReference(\n          orderId: orderId,\n          paymentId: checkout.paymentId,\n        ),\n      );\n\n      if (!mounted) return;\n      final paymentResult = await Navigator.of(context).push<PaymentReturnResult>(\n        MaterialPageRoute(\n          builder: (_) => PaymentReturnPage(\n            orderId: orderId,\n            checkoutUrl: checkout.checkoutUrl,\n          ),\n        ),\n      );\n\n      if (paymentResult != PaymentReturnResult.secured) {\n        return;\n      }\n\n      _cartRepository.clear();\n      if (!mounted) return;\n\n      setState(() {\n        _createdOrder = createdOrder;\n        _orderPlaced = true;\n      });\n"""
replace_once(old_post_order, new_post_order, 'real checkout flow')

replace_once(
    "    } on CreateOrderException catch (error) {",
    "    } on PaymentCheckoutException catch (error) {\n"
    "      if (!mounted) return;\n"
    "      ScaffoldMessenger.of(context).showSnackBar(\n"
    "        SnackBar(content: LocalizedText(error.message)),\n"
    "      );\n"
    "    } on CreateOrderException catch (error) {",
    'payment checkout exception handling',
)

replace_once(
    "    final total = subtotal + deliveryFee;\n\n"
    "    final isConfirmDisabled = cartState.isEmpty ||",
    "    final total = subtotal + deliveryFee;\n"
    "    final paymentStrings = PaymentStrings.of(context);\n\n"
    "    final isConfirmDisabled = cartState.isEmpty ||",
    'payment strings in build',
)

replace_once(
    "        _selectedCardId == null ||\n"
    "        _isDeliveryLoading ||",
    "        _isCardsLoading ||\n"
    "        (!_useNewCard && _selectedCardId == null) ||\n"
    "        _isDeliveryLoading ||",
    'confirm disable rule',
)

old_card_ui = """                  const _CheckoutSectionTitle(title: 'Выбор карты'),\n                  const SizedBox(height: 10),\n                  ..._savedCards.map(\n                    (card) => Padding(\n                      padding: const EdgeInsets.only(bottom: 10),\n                      child: _CheckoutCardTile(\n                        card: card,\n                        isSelected: _selectedCardId == card.id,\n                        onTap: () {\n                          if (_isSubmitting) return;\n                          setState(() {\n                            _selectedCardId = card.id;\n                          });\n                        },\n                      ),\n                    ),\n                  ),\n                  _AddNewCardTile(\n                    onTap: () {\n                      ScaffoldMessenger.of(context).showSnackBar(\n                        const SnackBar(\n                          content: LocalizedText(\n                            'Экран добавления карты подключим после подтверждения payment flow',\n                          ),\n                        ),\n                      );\n                    },\n                  ),\n"""
new_card_ui = """                  const _CheckoutSectionTitle(title: 'Способ оплаты'),\n                  const SizedBox(height: 10),\n                  if (_isCardsLoading)\n                    const Padding(\n                      padding: EdgeInsets.symmetric(vertical: 18),\n                      child: Center(\n                        child: CircularProgressIndicator(color: _green),\n                      ),\n                    )\n                  else ...[\n                    if (_cardsError != null) ...[\n                      Container(\n                        padding: const EdgeInsets.all(12),\n                        decoration: BoxDecoration(\n                          color: const Color(0xFFFFF6E8),\n                          borderRadius: BorderRadius.circular(14),\n                          border: Border.all(color: const Color(0xFFF0D9AD)),\n                        ),\n                        child: Row(\n                          children: [\n                            const Icon(\n                              Icons.info_outline_rounded,\n                              color: Color(0xFF9A6A18),\n                            ),\n                            const SizedBox(width: 10),\n                            Expanded(\n                              child: Text(\n                                paymentStrings.cardsLoadError,\n                                style: const TextStyle(\n                                  fontSize: 13,\n                                  color: Color(0xFF6B4A12),\n                                ),\n                              ),\n                            ),\n                            TextButton(\n                              onPressed: _loadSavedCards,\n                              child: Text(paymentStrings.retry),\n                            ),\n                          ],\n                        ),\n                      ),\n                      const SizedBox(height: 10),\n                    ],\n                    ..._savedCards.map(\n                      (card) => Padding(\n                        padding: const EdgeInsets.only(bottom: 10),\n                        child: _CheckoutCardTile(\n                          card: card,\n                          isSelected: !_useNewCard &&\n                              _selectedCardId == card.id,\n                          onTap: () {\n                            if (_isSubmitting) return;\n                            setState(() {\n                              _useNewCard = false;\n                              _selectedCardId = card.id;\n                              _saveNewCard = false;\n                            });\n                          },\n                        ),\n                      ),\n                    ),\n                    _AddNewCardTile(\n                      isSelected: _useNewCard,\n                      onTap: () {\n                        if (_isSubmitting) return;\n                        setState(() {\n                          _useNewCard = true;\n                          _selectedCardId = null;\n                        });\n                      },\n                    ),\n                    if (_useNewCard) ...[\n                      const SizedBox(height: 8),\n                      CheckboxListTile(\n                        value: _saveNewCard,\n                        onChanged: _isSubmitting\n                            ? null\n                            : (value) {\n                                setState(() {\n                                  _saveNewCard = value == true;\n                                });\n                              },\n                        contentPadding: EdgeInsets.zero,\n                        activeColor: _green,\n                        controlAffinity: ListTileControlAffinity.leading,\n                        title: Text(\n                          paymentStrings.saveCardForFuture,\n                          style: const TextStyle(\n                            fontSize: 14,\n                            fontWeight: FontWeight.w700,\n                          ),\n                        ),\n                        subtitle: Text(\n                          paymentStrings.secureProviderHint,\n                          style: const TextStyle(\n                            fontSize: 12,\n                            height: 1.35,\n                            color: Color(0xFF6B7280),\n                          ),\n                        ),\n                      ),\n                    ],\n                  ],\n"""
replace_once(old_card_ui, new_card_ui, 'checkout payment method UI')

replace_once(
    "  final _CheckoutCard card;",
    "  final SavedPaymentCard card;",
    'saved card tile model',
)

replace_once(
    "                    LocalizedText(\n                      card.type,",
    "                    LocalizedText(\n                      card.brandLabel,",
    'saved card brand label',
)

replace_once(
    "                    LocalizedText(\n                      '${card.maskedNumber} • ${card.expiry}',\n                      style: const TextStyle(",
    "                    LocalizedText(\n                      card.issuerBank == null\n                          ? card.maskedNumber\n                          : '${card.maskedNumber} • ${card.issuerBank}',\n                      style: const TextStyle(",
    'saved card detail line',
)

replace_once(
    "class _AddNewCardTile extends StatelessWidget {\n"
    "  const _AddNewCardTile({\n"
    "    required this.onTap,\n"
    "  });\n\n"
    "  final VoidCallback onTap;",
    "class _AddNewCardTile extends StatelessWidget {\n"
    "  const _AddNewCardTile({\n"
    "    required this.isSelected,\n"
    "    required this.onTap,\n"
    "  });\n\n"
    "  final bool isSelected;\n"
    "  final VoidCallback onTap;",
    'new card tile signature',
)

replace_once(
    "      color: Colors.transparent,\n      borderRadius: BorderRadius.circular(18),",
    "      color: isSelected ? const Color(0xFFF2FAEE) : Colors.transparent,\n      borderRadius: BorderRadius.circular(18),",
    'new card tile selected background',
)

replace_once(
    "            border: Border.all(\n              color: const Color(0xFFD1D5DB),\n              style: BorderStyle.solid,\n            ),",
    "            border: Border.all(\n              color: isSelected\n                  ? const Color(0xFF489F2A)\n                  : const Color(0xFFD1D5DB),\n              width: isSelected ? 1.5 : 1,\n            ),",
    'new card tile selected border',
)

replace_once(
    "                      const LocalizedText(\n                        'Подтвердить заказ',",
    "                      const LocalizedText(\n                        'Оплатить',",
    'payment button label',
)

old_created = """class _CreatedOrderView {\n  const _CreatedOrderView({\n    required this.pickupCode,\n  });\n\n  final String? pickupCode;\n\n  factory _CreatedOrderView.fromJson(Map<String, dynamic> json) {\n    final raw = json['pickupCode']?.toString().trim() ?? '';\n\n    return _CreatedOrderView(\n      pickupCode: raw.isEmpty || raw.toLowerCase() == 'null' ? null : raw,\n    );\n  }\n}\n\nclass _CheckoutCard {\n  const _CheckoutCard({\n    required this.id,\n    required this.maskedNumber,\n    required this.type,\n    required this.expiry,\n  });\n\n  final int id;\n  final String maskedNumber;\n  final String type;\n  final String expiry;\n}\n"""
new_created = """class _CreatedOrderView {\n  const _CreatedOrderView({\n    required this.id,\n    required this.pickupCode,\n  });\n\n  final String? id;\n  final String? pickupCode;\n\n  factory _CreatedOrderView.fromJson(Map<String, dynamic> json) {\n    final rawId = json['id']?.toString().trim() ?? '';\n    final rawPickup = json['pickupCode']?.toString().trim() ?? '';\n\n    return _CreatedOrderView(\n      id: rawId.isEmpty || rawId.toLowerCase() == 'null' ? null : rawId,\n      pickupCode: rawPickup.isEmpty || rawPickup.toLowerCase() == 'null'\n          ? null\n          : rawPickup,\n    );\n  }\n}\n"""
replace_once(old_created, new_created, 'created order id and remove fake card class')

checkout_path.write_text(text, encoding='utf-8')

api_path = Path('lib/core/network/apiClient.dart')
api = api_path.read_text(encoding='utf-8')
old = """        if (lowerKey.contains('token') ||\n            lowerKey.contains('password') ||\n            lowerKey == 'code' ||\n            lowerKey == 'otp' ||\n            lowerKey == 'smscode') {\n"""
new = """        if (lowerKey.contains('token') ||\n            lowerKey.contains('password') ||\n            lowerKey.contains('checkouturl') ||\n            lowerKey.contains('paymenturl') ||\n            lowerKey.contains('authorizationurl') ||\n            lowerKey == 'code' ||\n            lowerKey == 'otp' ||\n            lowerKey == 'smscode') {\n"""
if api.count(old) != 1:
    raise SystemExit(f'api log redaction: expected exactly 1 match, got {api.count(old)}')
api = api.replace(old, new, 1)
api_path.write_text(api, encoding='utf-8')

readme = Path('lib/features/payments/README.md')
readme.write_text('''# Payment client\n\nJETKIZ mobile remains provider-agnostic: Flutter talks only to the JETKIZ backend.\n\n## Security boundaries\n\n- PayLink API keys and merchant credentials exist only on backend.\n- PAN/CVV are entered only on the PayLink hosted HTTPS page and never pass through Flutter or JETKIZ backend.\n- Saved-card provider tokens never leave backend and are encrypted at rest there. Flutter receives only display metadata such as brand, last4 and issuer bank.\n- Hosted checkout URLs are treated as sensitive session data: they are redacted from app debug logging and are not persisted locally.\n- A PayLink redirect/browser return is never proof of payment. Flutter accepts success only after `GET /payments/orders/:orderId` returns `fundsSecured=true`.\n\n## Production checkout flow\n\n1. Sync cart and revalidate prices/availability.\n2. Create a CARD order with an idempotency key.\n3. Call `POST /payments` with the order ID and either `savedPaymentMethodId` or explicit `saveCard=true` for a new card.\n4. Open only an HTTPS checkout URL returned by JETKIZ backend.\n5. Poll JETKIZ backend for the payment state after returning from PayLink.\n6. Treat `AUTHORIZED` (or `PAID`) as secured funds; restaurant acceptance triggers backend CAPTURE.\n7. Keep the cart when payment fails/pends; clear it only after backend confirms secured funds.\n8. Persist only order/payment IDs for interrupted-flow recovery.\n\n## Saved cards\n\n- `GET /payments/methods` lists display-safe methods.\n- `PATCH /payments/methods/:id/default` changes the default method.\n- `DELETE /payments/methods/:id` removes a method.\n- New cards are tokenized during a real PayLink checkout. JETKIZ intentionally does not implement a fake/zero-amount standalone add-card transaction.\n''', encoding='utf-8')

print('PayLink Flutter production patch applied')
