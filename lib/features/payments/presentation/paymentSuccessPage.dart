import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/orders/presentation/ordersHistoryPage.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentCheckoutApi.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  late final PaymentCheckoutApi _payments;
  PaymentOrderState? _state;
  Timer? _retryTimer;
  int _remainingCardSaveChecks = 30;

  @override
  void initState() {
    super.initState();
    _payments = PaymentCheckoutApi(ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPaymentState());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshPaymentState() async {
    final orderId = widget.orderId.trim();
    if (orderId.isEmpty) return;

    try {
      final next = await _payments.getOrderPaymentState(orderId);
      if (!mounted) return;
      setState(() => _state = next);

      if (next.isCardSavePending && _remainingCardSaveChecks > 0) {
        _remainingCardSaveChecks -= 1;
        _retryTimer?.cancel();
        _retryTimer = Timer(
          const Duration(seconds: 2),
          _refreshPaymentState,
        );
      }
    } catch (_) {
      // Payment success is already server-confirmed before this page opens.
      // A temporary status-refresh failure must not replace the paid screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKk = AppLocalizationScope.of(context).language == AppLanguage.kk;
    final title = isKk ? 'Тапсырысыңыз төленді' : 'Ваш заказ оплачен';
    final hint = isKk
        ? 'Тапсырыс мәртебесін «Менің тапсырыстарым» бөлімінен көре аласыз.'
        : 'Посмотреть статус заказа можно в разделе «Мои заказы».';
    final ordersLabel = isKk ? 'Менің тапсырыстарым' : 'Мои заказы';
    final homeLabel = isKk ? 'Басты бетке' : 'На главную';
    final cardSaveMessage = _cardSaveMessage(isKk);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF5),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF7E4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 64,
                    color: Color(0xFF489F2A),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF172016),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF657063),
                  ),
                ),
                if (cardSaveMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _state?.isCardSaveFailed == true
                          ? const Color(0xFFFFF4E5)
                          : const Color(0xFFF0F7ED),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      cardSaveMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E594C),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrdersHistoryPage(
                            initialOrderId: widget.orderId.trim().isEmpty
                                ? null
                                : widget.orderId.trim(),
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF489F2A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: Text(
                      ordersLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF489F2A),
                      side: const BorderSide(color: Color(0xFFD7EFD0)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      homeLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _cardSaveMessage(bool isKk) {
    final state = _state;
    if (state == null || !state.cardSaveRequested) return null;

    if (state.isCardSaved) {
      return isKk
          ? 'Карта келесі төлемдер үшін сақталды.'
          : 'Карта сохранена для следующих оплат.';
    }
    if (state.isCardSaveFailed) {
      return isKk
          ? 'Төлем өтті, бірақ картаны сақтау мүмкін болмады. Тапсырыс сәтті рәсімделді.'
          : 'Оплата прошла, но сохранить карту не удалось. Заказ успешно оформлен.';
    }

    return isKk
        ? 'Төлем өтті. Картаны сақтау әлі расталып жатыр.'
        : 'Оплата прошла. Сохранение карты ещё подтверждается.';
  }
}
