import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentMethodsPage.dart';

/// Temporary preview entry for local QA before a real provider is connected.
/// It intentionally performs no payment or card provisioning operations.
class PaymentFoundationPreviewPage extends StatelessWidget {
  const PaymentFoundationPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const LocalizedText(
          'Оплата',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4E9E1)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    'Фундамент платежей готов',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  LocalizedText(
                    'Сейчас доступны только безопасные макеты управления картами. Реальные реквизиты не принимаются, а платёжный провайдер ещё не подключён.',
                    style: TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF667064)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF489F2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.credit_card_rounded),
              label: const LocalizedText(
                'Открыть способы оплаты',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
