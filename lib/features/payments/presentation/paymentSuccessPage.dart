import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/features/orders/presentation/ordersHistoryPage.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({
    super.key,
    required this.orderId,
    this.cardSaveStatus,
  });

  final String orderId;
  final String? cardSaveStatus;

  @override
  Widget build(BuildContext context) {
    final isKk = AppLocalizationScope.of(context).language == AppLanguage.kk;
    final title = isKk ? 'Тапсырысыңыз төленді' : 'Ваш заказ оплачен';
    final hint = isKk
        ? 'Тапсырыс мәртебесін «Менің тапсырыстарым» бөлімінен көре аласыз.'
        : 'Посмотреть статус заказа можно в разделе «Мои заказы».';
    final ordersLabel = isKk ? 'Менің тапсырыстарым' : 'Мои заказы';
    final homeLabel = isKk ? 'Басты бетке' : 'На главную';
    final normalizedCardSaveStatus = (cardSaveStatus ?? '').toUpperCase();
    final cardSaveHint = switch (normalizedCardSaveStatus) {
      'FAILED' => isKk
          ? 'Төлем өтті, бірақ картаны сақтау мүмкін болмады.'
          : 'Оплата прошла, но карту сохранить не удалось.',
      'REQUESTED' => isKk
          ? 'Төлем өтті. Картаны сақтау әлі аяқталып жатыр.'
          : 'Оплата прошла. Сохранение карты ещё завершается.',
      _ => null,
    };

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
                if (cardSaveHint != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    cardSaveHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7A5A00),
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
                            initialOrderId:
                                orderId.trim().isEmpty ? null : orderId.trim(),
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
}
