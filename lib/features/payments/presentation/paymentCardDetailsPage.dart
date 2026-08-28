import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';

class PaymentCardDetailsPage extends StatelessWidget {
  const PaymentCardDetailsPage({
    super.key,
    required this.card,
  });

  final SavedPaymentCard card;

  @override
  Widget build(BuildContext context) {
    final strings = PaymentStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          strings.card,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4E9E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.credit_card_rounded,
                  color: Color(0xFF489F2A),
                  size: 34,
                ),
                const SizedBox(height: 18),
                Text(
                  '${card.brandLabel} ${card.maskedNumber}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (card.expiryLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${strings.expiry} ${card.expiryLabel}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF697267),
                    ),
                  ),
                ],
                if (card.isDefault) ...[
                  const SizedBox(height: 14),
                  Text(
                    strings.defaultCard,
                    style: const TextStyle(
                      color: Color(0xFF489F2A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.providerPendingAction)),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(strings.deleteCard),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD33A2C),
              side: const BorderSide(color: Color(0xFFE6B4AE)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
