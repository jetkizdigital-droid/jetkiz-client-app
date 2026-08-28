import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentMethodsRepository.dart';
import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';
import 'package:jetkiz_mobile/features/payments/presentation/addPaymentCardPage.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentCardDetailsPage.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  static const Color _green = Color(0xFF489F2A);
  static const Color _background = Color(0xFFF7FAF5);

  final PaymentMethodsRepository _repository = PaymentMethodsRepository.instance;

  bool _isLoading = true;
  List<SavedPaymentCard> _cards = const [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await _repository.getSavedCards();
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  Future<void> _openAddCard() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const AddPaymentCardPage()),
    );
    if (mounted) {
      await _loadCards();
    }
  }

  Future<void> _openCard(SavedPaymentCard card) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PaymentCardDetailsPage(card: card)),
    );
  }

  Future<void> _showDeleteDialog(SavedPaymentCard card) async {
    final strings = PaymentStrings.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.deleteCardQuestion),
          content: Text(
            strings.deleteCardDescription(
              '${card.brandLabel} ${card.maskedNumber}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.providerPendingAction)),
                );
              },
              child: Text(strings.delete),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(PaymentStrings strings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: _green,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.noSavedCards,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              strings.cardsProviderHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Color(0xFF667064),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openAddCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  strings.addCard,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(SavedPaymentCard card, PaymentStrings strings) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openCard(card),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4E9E1)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.credit_card_rounded, color: _green),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${card.brandLabel} ${card.maskedNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (card.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              strings.defaultBadge,
                              style: const TextStyle(
                                color: _green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (card.expiryLabel != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${strings.expiry} ${card.expiryLabel}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7C857A),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showDeleteDialog(card),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: strings.deleteCard,
              ),
            ],
          ),
        ),
      ),
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
          strings.paymentMethods,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _cards.isEmpty
              ? _buildEmptyState(strings)
              : RefreshIndicator(
                  onRefresh: _loadCards,
                  color: _green,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    children: [
                      ..._cards.map((card) => _buildCard(card, strings)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _openAddCard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: _green),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          strings.addCard,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
