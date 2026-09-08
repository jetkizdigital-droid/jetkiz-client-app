from pathlib import Path

path = Path('lib/features/checkout/presentation/checkoutPage.dart')
text = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected 1 match, got {count}')
    text = text.replace(old, new, 1)


replace_once(
    "  final PaymentPendingStore _paymentPendingStore = PaymentPendingStore();\n\n"
    "  String? _selectedCardId;",
    "  final PaymentPendingStore _paymentPendingStore = PaymentPendingStore();\n\n"
    "  PendingPaymentReference? _recoverablePayment;\n"
    "  String? _recoverableCheckoutUrl;\n"
    "  String? _paymentRecoveryError;\n"
    "  bool _isPaymentRecoveryLoading = true;\n"
    "  String? _activeCheckoutOrderId;\n\n"
    "  String? _selectedCardId;",
    'recovery state fields',
)

replace_once(
    "    _loadDeliveryFee();\n"
    "    _loadSavedCards();\n",
    "    _loadDeliveryFee();\n"
    "    _loadSavedCards();\n"
    "    _recoverPendingPayment();\n",
    'recover on init',
)

anchor = """  Future<void> _changeAddress() async {\n"""
methods = r'''  Future<void> _recoverPendingPayment({bool showResolvedNotice = true}) async {
    if (mounted) {
      setState(() {
        _isPaymentRecoveryLoading = true;
        _paymentRecoveryError = null;
      });
    }

    final strings = PaymentStrings.of(context);

    try {
      final pending = await _paymentPendingStore.read();
      if (!mounted) return;

      if (pending == null) {
        setState(() {
          _recoverablePayment = null;
          _recoverableCheckoutUrl = null;
          _paymentRecoveryError = null;
          _isPaymentRecoveryLoading = false;
        });
        return;
      }

      try {
        final state = await _paymentCheckoutApi.getOrderPaymentState(
          pending.orderId,
        );
        if (!mounted) return;

        if (state.isSecuredCardPayment) {
          await _paymentPendingStore.clear();
          if (!mounted) return;
          setState(() {
            _recoverablePayment = null;
            _recoverableCheckoutUrl = null;
            _paymentRecoveryError = null;
            _isPaymentRecoveryLoading = false;
          });
          if (showResolvedNotice) {
            _showPaymentNotice(strings.previousPaymentConfirmed);
          }
          return;
        }

        if (state.isFailed || state.isTerminalWithoutSuccess) {
          await _paymentPendingStore.clear();
          if (!mounted) return;
          setState(() {
            _recoverablePayment = null;
            _recoverableCheckoutUrl = null;
            _paymentRecoveryError = null;
            _isPaymentRecoveryLoading = false;
          });
          if (showResolvedNotice) {
            _showPaymentNotice(strings.previousPaymentFailed);
          }
          return;
        }

        final checkoutUri = state.secureCheckoutUri;
        setState(() {
          _recoverablePayment = pending;
          _recoverableCheckoutUrl = checkoutUri?.toString();
          _paymentRecoveryError =
              checkoutUri == null ? strings.recoveryCheckError : null;
          _isPaymentRecoveryLoading = false;
        });
      } on PaymentCheckoutException {
        if (!mounted) return;
        setState(() {
          _recoverablePayment = pending;
          _recoverableCheckoutUrl = null;
          _paymentRecoveryError = strings.recoveryCheckError;
          _isPaymentRecoveryLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recoverablePayment = null;
        _recoverableCheckoutUrl = null;
        _paymentRecoveryError = strings.recoveryCheckError;
        _isPaymentRecoveryLoading = false;
      });
    }
  }

  void _showPaymentNotice(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  Future<void> _resumePendingPayment() async {
    if (_isSubmitting || _isPaymentRecoveryLoading) return;

    final pending = _recoverablePayment;
    if (pending == null) {
      await _recoverPendingPayment();
      return;
    }

    final strings = PaymentStrings.of(context);
    setState(() => _isSubmitting = true);

    try {
      final state = await _paymentCheckoutApi.getOrderPaymentState(
        pending.orderId,
      );
      if (!mounted) return;

      if (state.isSecuredCardPayment) {
        await _paymentPendingStore.clear();
        if (!mounted) return;
        if (_activeCheckoutOrderId == pending.orderId) {
          _cartRepository.clear();
        }
        setState(() {
          _recoverablePayment = null;
          _recoverableCheckoutUrl = null;
          _paymentRecoveryError = null;
          _createdOrder = _CreatedOrderView(
            id: pending.orderId,
            pickupCode: null,
          );
          _orderPlaced = true;
        });
        return;
      }

      if (state.isFailed || state.isTerminalWithoutSuccess) {
        await _paymentPendingStore.clear();
        if (!mounted) return;
        setState(() {
          _recoverablePayment = null;
          _recoverableCheckoutUrl = null;
          _paymentRecoveryError = null;
        });
        _showPaymentNotice(strings.previousPaymentFailed);
        return;
      }

      final checkoutUri = state.secureCheckoutUri;
      if (checkoutUri == null) {
        setState(() {
          _recoverableCheckoutUrl = null;
          _paymentRecoveryError = strings.recoveryCheckError;
        });
        return;
      }

      setState(() {
        _recoverableCheckoutUrl = checkoutUri.toString();
        _paymentRecoveryError = null;
      });

      final result = await Navigator.of(context).push<PaymentReturnResult>(
        MaterialPageRoute(
          builder: (_) => PaymentReturnPage(
            orderId: pending.orderId,
            checkoutUrl: checkoutUri.toString(),
          ),
        ),
      );
      if (!mounted) return;

      if (result == PaymentReturnResult.secured) {
        if (_activeCheckoutOrderId == pending.orderId) {
          _cartRepository.clear();
        }
        setState(() {
          _recoverablePayment = null;
          _recoverableCheckoutUrl = null;
          _paymentRecoveryError = null;
          _createdOrder = _CreatedOrderView(
            id: pending.orderId,
            pickupCode: null,
          );
          _orderPlaced = true;
        });
        return;
      }

      await _recoverPendingPayment(showResolvedNotice: false);
    } on PaymentCheckoutException {
      if (!mounted) return;
      setState(() {
        _paymentRecoveryError = strings.recoveryCheckError;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _changeAddress() async {
'''
replace_once(anchor, methods, 'recovery methods')

replace_once(
    "    if (_isSubmitting || _orderPlaced) return;\n\n"
    "    if (!_isPickup && _hasDeliveryError) {",
    "    if (_isSubmitting || _orderPlaced || _isPaymentRecoveryLoading) return;\n\n"
    "    if (_recoverablePayment != null || _paymentRecoveryError != null) {\n"
    "      await _resumePendingPayment();\n"
    "      return;\n"
    "    }\n\n"
    "    if (!_isPickup && _hasDeliveryError) {",
    'block duplicate order while recovery unresolved',
)

replace_once(
    "      if (orderId.isEmpty) {\n"
    "        throw const _CheckoutBlockedException(\n"
    "          'Сервер не вернул номер созданного заказа',\n"
    "        );\n"
    "      }\n\n"
    "      final checkout = await _paymentCheckoutApi.createCheckout(",
    "      if (orderId.isEmpty) {\n"
    "        throw const _CheckoutBlockedException(\n"
    "          'Сервер не вернул номер созданного заказа',\n"
    "        );\n"
    "      }\n"
    "      _activeCheckoutOrderId = orderId;\n\n"
    "      final checkout = await _paymentCheckoutApi.createCheckout(",
    'track runtime checkout order',
)

replace_once(
    "      if (paymentResult != PaymentReturnResult.secured) {\n"
    "        return;\n"
    "      }",
    "      if (paymentResult != PaymentReturnResult.secured) {\n"
    "        await _recoverPendingPayment(showResolvedNotice: false);\n"
    "        return;\n"
    "      }",
    'capture pending result for resume',
)

old_build = """    final paymentStrings = PaymentStrings.of(context);\n\n    final isConfirmDisabled = cartState.isEmpty ||\n        (!_isPickup && address == null) ||\n        (!_isPickup && _hasDeliveryError) ||\n        _isCardsLoading ||\n        (!_useNewCard && _selectedCardId == null) ||\n        _isDeliveryLoading ||\n        _isSubmitting;\n"""
new_build = """    final paymentStrings = PaymentStrings.of(context);\n    final hasPaymentRecoveryAction =\n        _recoverablePayment != null || _paymentRecoveryError != null;\n    final canResumeHostedCheckout =\n        _recoverablePayment != null && _recoverableCheckoutUrl != null;\n\n    final normalCheckoutDisabled = cartState.isEmpty ||\n        (!_isPickup && address == null) ||\n        (!_isPickup && _hasDeliveryError) ||\n        _isCardsLoading ||\n        (!_useNewCard && _selectedCardId == null) ||\n        _isDeliveryLoading;\n    final isConfirmDisabled = _isPaymentRecoveryLoading ||\n        _isSubmitting ||\n        (!hasPaymentRecoveryAction && normalCheckoutDisabled);\n    final primaryActionLabel = hasPaymentRecoveryAction\n        ? (canResumeHostedCheckout\n            ? paymentStrings.resumePayment\n            : paymentStrings.verifyPreviousPayment)\n        : null;\n"""
replace_once(old_build, new_build, 'build recovery action state')

list_anchor = """                children: [\n                  const _CheckoutSectionTitle(title: 'Способ получения'),\n"""
list_replacement = """                children: [\n                  if (hasPaymentRecoveryAction) ...[\n                    _PendingPaymentBanner(\n                      hasCheckoutUrl: canResumeHostedCheckout,\n                      errorMessage: _paymentRecoveryError,\n                      isBusy: _isSubmitting || _isPaymentRecoveryLoading,\n                      onAction: _resumePendingPayment,\n                    ),\n                    const SizedBox(height: 18),\n                  ],\n                  const _CheckoutSectionTitle(title: 'Способ получения'),\n"""
replace_once(list_anchor, list_replacement, 'recovery banner')

replace_once(
    "                    enabled: !_isSubmitting,",
    "                    enabled: !_isSubmitting && !hasPaymentRecoveryAction,",
    'disable fulfillment during unresolved payment',
)

# Card selections and new-card consent remain visible for context but cannot be
# changed while a previous charge is unresolved.
text = text.replace(
    "                            if (_isSubmitting) return;\n                            setState(() {\n                              _useNewCard = false;",
    "                            if (_isSubmitting || hasPaymentRecoveryAction) {\n                              return;\n                            }\n                            setState(() {\n                              _useNewCard = false;",
    1,
)
text = text.replace(
    "                        if (_isSubmitting) return;\n                        setState(() {\n                          _useNewCard = true;",
    "                        if (_isSubmitting || hasPaymentRecoveryAction) {\n                          return;\n                        }\n                        setState(() {\n                          _useNewCard = true;",
    1,
)
replace_once(
    "                        onChanged: _isSubmitting\n                            ? null",
    "                        onChanged: (_isSubmitting || hasPaymentRecoveryAction)\n                            ? null",
    'disable save-card toggle during recovery',
)

replace_once(
    "          _CheckoutBottomBar(\n"
    "            total: total,\n"
    "            isLoading: _isSubmitting,\n"
    "            isDisabled: isConfirmDisabled,\n"
    "            onConfirm: _handleConfirmOrder,\n"
    "          ),",
    "          _CheckoutBottomBar(\n"
    "            total: total,\n"
    "            actionLabel: primaryActionLabel,\n"
    "            showTotal: !hasPaymentRecoveryAction,\n"
    "            isLoading: _isSubmitting || _isPaymentRecoveryLoading,\n"
    "            isDisabled: isConfirmDisabled,\n"
    "            onConfirm: hasPaymentRecoveryAction\n"
    "                ? _resumePendingPayment\n"
    "                : _handleConfirmOrder,\n"
    "          ),",
    'bottom bar recovery action',
)

widget_anchor = """class _CheckoutSectionTitle extends StatelessWidget {\n"""
recovery_widget = r'''class _PendingPaymentBanner extends StatelessWidget {
  const _PendingPaymentBanner({
    required this.hasCheckoutUrl,
    required this.errorMessage,
    required this.isBusy,
    required this.onAction,
  });

  final bool hasCheckoutUrl;
  final String? errorMessage;
  final bool isBusy;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final strings = PaymentStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1D9A6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Color(0xFF956313),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.unfinishedPaymentTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5D4317),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.unfinishedPaymentHint,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF765A2A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Color(0xFF9B3A2D),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isBusy ? null : onAction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF956313),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: Icon(
                hasCheckoutUrl
                    ? Icons.open_in_browser_rounded
                    : Icons.refresh_rounded,
              ),
              label: Text(
                hasCheckoutUrl
                    ? strings.resumePayment
                    : strings.verifyPreviousPayment,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSectionTitle extends StatelessWidget {
'''
replace_once(widget_anchor, recovery_widget, 'recovery banner widget')

replace_once(
    "  const _CheckoutBottomBar({\n"
    "    required this.total,\n"
    "    required this.isLoading,\n"
    "    required this.isDisabled,\n"
    "    required this.onConfirm,\n"
    "  });\n\n"
    "  final int total;\n"
    "  final bool isLoading;",
    "  const _CheckoutBottomBar({\n"
    "    required this.total,\n"
    "    required this.actionLabel,\n"
    "    required this.showTotal,\n"
    "    required this.isLoading,\n"
    "    required this.isDisabled,\n"
    "    required this.onConfirm,\n"
    "  });\n\n"
    "  final int total;\n"
    "  final String? actionLabel;\n"
    "  final bool showTotal;\n"
    "  final bool isLoading;",
    'bottom bar fields',
)

old_button_children = """                    children: [\n                      const LocalizedText(\n                        'Оплатить',\n                        style: TextStyle(\n                          fontSize: 16,\n                          fontWeight: FontWeight.w800,\n                        ),\n                      ),\n                      const SizedBox(width: 8),\n                      LocalizedText(\n                        '$total ₸',\n                        style: const TextStyle(\n                          fontSize: 16,\n                          fontWeight: FontWeight.w800,\n                        ),\n                      ),\n                    ],\n"""
new_button_children = """                    children: [\n                      if (actionLabel == null)\n                        const LocalizedText(\n                          'Оплатить',\n                          style: TextStyle(\n                            fontSize: 16,\n                            fontWeight: FontWeight.w800,\n                          ),\n                        )\n                      else\n                        Text(\n                          actionLabel!,\n                          style: const TextStyle(\n                            fontSize: 16,\n                            fontWeight: FontWeight.w800,\n                          ),\n                        ),\n                      if (showTotal) ...[\n                        const SizedBox(width: 8),\n                        LocalizedText(\n                          '$total ₸',\n                          style: const TextStyle(\n                            fontSize: 16,\n                            fontWeight: FontWeight.w800,\n                          ),\n                        ),\n                      ],\n                    ],\n"""
replace_once(old_button_children, new_button_children, 'bottom bar dynamic label')

path.write_text(text, encoding='utf-8')
print('Interrupted payment recovery patch applied')
