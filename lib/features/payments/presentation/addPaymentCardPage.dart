import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';

/// Informational page only.
///
/// PayLink card-on-file tokenization happens as part of a real order payment.
/// JETKIZ deliberately does not render PAN/CVV input fields and does not create
/// zero-value/fake provider transactions just to add a card.
class AddPaymentCardPage extends StatelessWidget {
  const AddPaymentCardPage({super.key});

  static const Color _green = Color(0xFF489F2A);
  static const Color _background = Color(0xFFF7FAF5);

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: _green,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                strings.addCard,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F271E),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                strings.secureProviderHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF5F685D),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.providerPendingHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF7A8378),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    strings.understood,
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
      ),
    );
  }
}
