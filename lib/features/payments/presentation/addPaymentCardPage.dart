import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';

class AddPaymentCardPage extends StatelessWidget {
  const AddPaymentCardPage({super.key});

  static const Color _green = Color(0xFF489F2A);
  static const Color _background = Color(0xFFF7FAF5);

  void _showProviderNotice(BuildContext context, PaymentStrings strings) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.providerPendingAction)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = PaymentStrings.of(context);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          strings.addCard,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4E9E1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded, color: _green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.secureProviderHint,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF5F685D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _PreviewField(
              label: strings.cardNumber,
              value: '0000 0000 0000 0000',
              trailing: const Icon(Icons.credit_card_rounded),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PreviewField(
                    label: strings.expiry,
                    value: 'MM/YY',
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _PreviewField(
                    label: 'CVV',
                    value: '•••',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PreviewField(
              label: strings.cardholderName,
              value: 'IVAN IVANOV',
            ),
            const SizedBox(height: 12),
            Text(
              strings.providerPendingHint,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF7A8378),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showProviderNotice(context, strings),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  strings.saveCard,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

class _PreviewField extends StatelessWidget {
  const _PreviewField({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E7DE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A8378),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F271E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
