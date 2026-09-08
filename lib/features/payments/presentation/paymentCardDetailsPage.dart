import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentMethodsRepository.dart';
import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';

class PaymentCardDetailsPage extends StatefulWidget {
  const PaymentCardDetailsPage({
    super.key,
    required this.card,
  });

  final SavedPaymentCard card;

  @override
  State<PaymentCardDetailsPage> createState() => _PaymentCardDetailsPageState();
}

class _PaymentCardDetailsPageState extends State<PaymentCardDetailsPage> {
  final PaymentMethodsRepository _repository =
      PaymentMethodsRepository.instance;

  late SavedPaymentCard _card;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
  }

  Future<void> _makeDefault() async {
    if (_isBusy || _card.isDefault) return;
    setState(() => _isBusy = true);

    try {
      await _repository.setDefaultCard(_card.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PaymentMethodsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _delete() async {
    if (_isBusy) return;
    final strings = PaymentStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteCardQuestion),
        content: Text(
          strings.deleteCardDescription(
              '${_card.brandLabel} ${_card.maskedNumber}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isBusy = true);

    try {
      await _repository.deleteCard(_card.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PaymentMethodsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      setState(() => _isBusy = false);
    }
  }

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
                  '${_card.brandLabel} ${_card.maskedNumber}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_card.issuerBank != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${strings.issuerBank}: ${_card.issuerBank}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF697267),
                    ),
                  ),
                ],
                if (_card.expiryLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${strings.expiry} ${_card.expiryLabel}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF697267),
                    ),
                  ),
                ],
                if (_card.isDefault) ...[
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
          if (!_card.isDefault) ...[
            FilledButton.icon(
              onPressed: _isBusy ? null : _makeDefault,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(strings.makeDefault),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF489F2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _delete,
            icon: _isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
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
