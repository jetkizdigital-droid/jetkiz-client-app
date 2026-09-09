import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/orders/presentation/ordersHistoryPage.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentCheckoutApi.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentPendingStore.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentSuccessPage.dart';

class PaymentReturnRecoveryPage extends StatefulWidget {
  const PaymentReturnRecoveryPage({
    super.key,
    this.providerResult,
  });

  final String? providerResult;

  @override
  State<PaymentReturnRecoveryPage> createState() =>
      _PaymentReturnRecoveryPageState();
}

class _PaymentReturnRecoveryPageState extends State<PaymentReturnRecoveryPage> {
  static const Duration _pollInterval = Duration(seconds: 2);
  static const Duration _maxWait = Duration(minutes: 1);

  final PaymentPendingStore _pendingStore = PaymentPendingStore();
  late final PaymentCheckoutApi _payments;

  Timer? _pollTimer;
  DateTime? _startedAt;
  PendingPaymentReference? _pending;
  bool _checking = true;
  bool _failed = false;
  bool _timedOut = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _payments = PaymentCheckoutApi(ApiClient());
    _begin();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _begin() async {
    try {
      final pending = await _pendingStore.read();
      if (!mounted) return;

      if (pending == null) {
        setState(() {
          _checking = false;
          _error = null;
        });
        return;
      }

      _pending = pending;
      _startedAt = DateTime.now();
      await _check();
      if (!mounted || _failed || _timedOut) return;

      _pollTimer = Timer.periodic(_pollInterval, (_) => _check());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = 'PAYMENT_RECOVERY_UNAVAILABLE';
      });
    }
  }

  Future<void> _check() async {
    final pending = _pending;
    if (pending == null || !mounted) return;

    final startedAt = _startedAt;
    if (startedAt != null && DateTime.now().difference(startedAt) > _maxWait) {
      _pollTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _checking = false;
        _timedOut = true;
      });
      return;
    }

    try {
      final state = await _payments.getOrderPaymentState(pending.orderId);
      if (!mounted) return;

      if (state.isSecuredCardPayment) {
        _pollTimer?.cancel();
        await _pendingStore.clear();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(orderId: pending.orderId),
          ),
          (route) => false,
        );
        return;
      }

      if (state.isFailed || state.isTerminalWithoutSuccess) {
        _pollTimer?.cancel();
        await _pendingStore.clear();
        if (!mounted) return;
        setState(() {
          _checking = false;
          _failed = true;
          _error = null;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _checking = true;
          _error = null;
        });
      }
    } on PaymentCheckoutException catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKk = AppLocalizationScope.of(context).language == AppLanguage.kk;
    final noPending = _pending == null && !_checking && !_failed;

    String title;
    String hint;
    IconData icon;
    Color iconColor;

    if (_failed) {
      title = isKk ? 'Төлем расталмады' : 'Оплата не подтверждена';
      hint = isKk
          ? 'Төлем аяқталмады. Қайта төлем жасамас бұрын тапсырыстарды тексеріңіз.'
          : 'Платёж не завершён. Перед повторной оплатой проверьте свои заказы.';
      icon = Icons.error_outline_rounded;
      iconColor = const Color(0xFFD33A2C);
    } else if (_timedOut || _error != null) {
      title = isKk ? 'Төлемді тексеріп жатырмыз' : 'Проверяем оплату';
      hint = isKk
          ? 'Нәтиже әлі алынбады. Қайта тексеріңіз немесе тапсырыстар бөлімін ашыңыз.'
          : 'Результат пока не получен. Проверьте ещё раз или откройте раздел заказов.';
      icon = Icons.schedule_rounded;
      iconColor = const Color(0xFF956313);
    } else if (noPending) {
      title = isKk ? 'Төлем өңделді' : 'Платёж уже обработан';
      hint = isKk
          ? 'Тапсырыс мәртебесін «Менің тапсырыстарым» бөлімінен тексеріңіз.'
          : 'Проверьте статус заказа в разделе «Мои заказы».';
      icon = Icons.receipt_long_rounded;
      iconColor = const Color(0xFF489F2A);
    } else {
      title = isKk ? 'Төлемді тексеріп жатырмыз' : 'Проверяем оплату';
      hint = isKk
          ? 'Банк төлемін JETKIZ серверімен салыстырып жатырмыз. Бірнеше секунд күтіңіз.'
          : 'Сверяем оплату банка с сервером JETKIZ. Подождите несколько секунд.';
      icon = Icons.shield_outlined;
      iconColor = const Color(0xFF489F2A);
    }

    return PopScope(
      canPop: !_checking,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF5),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: _checking
                      ? Padding(
                          padding: const EdgeInsets.all(29),
                          child: CircularProgressIndicator(
                            color: iconColor,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(icon, size: 44, color: iconColor),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
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
                    height: 1.45,
                    color: Color(0xFF657063),
                  ),
                ),
                const Spacer(),
                if (!_checking && _pending != null && !_failed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _checking = true;
                          _timedOut = false;
                          _error = null;
                          _startedAt = DateTime.now();
                        });
                        _check();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF489F2A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        isKk ? 'Қайта тексеру' : 'Проверить снова',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (!_checking)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrdersHistoryPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: Text(
                        isKk ? 'Менің тапсырыстарым' : 'Мои заказы',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF489F2A),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
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
}
