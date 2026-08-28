import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';

class PaymentReturnPage extends StatelessWidget {
  const PaymentReturnPage({
    super.key,
    required this.orderId,
  });

  final String orderId;

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
          strings.paymentCheck,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF489F2A)),
              const SizedBox(height: 18),
              Text(
                strings.paymentCheckHint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
