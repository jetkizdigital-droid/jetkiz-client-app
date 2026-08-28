import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentMethodsRepository.dart';
import 'package:jetkiz_mobile/features/payments/domain/savedPaymentCard.dart';
import 'package:jetkiz_mobile/features/payments/presentation/addPaymentCardPage.dart';

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

  Future<void> _showDeleteDialog(SavedPaymentCard card) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const LocalizedText('Удалить карту?'),
          content: LocalizedText('${card.brandLabel} ${card.maskedNumber} будет удалена из способов оплаты.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const LocalizedText('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: LocalizedText('Удаление карты станет доступно после подключения платёжного провайдера'),
                  ),
                );
              },
              child: const LocalizedText('Удалить'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
              child: const Icon(Icons.credit_card_rounded, color: _green, size: 34),
            ),
            const SizedBox(height: 20),
            const LocalizedText(
              'Сохранённых карт пока нет',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const LocalizedText(
              'После подключения платёжного провайдера здесь можно будет управлять сохранёнными способами оплаты.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF667064)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const LocalizedText(
                  'Добавить карту',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(SavedPaymentCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (card.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const LocalizedText(
                          'Основная',
                          style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                if (card.expiryLabel != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Срок действия ${card.expiryLabel}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF7C857A)),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showDeleteDialog(card),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Удалить карту',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const LocalizedText(
          'Способы оплаты',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _cards.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCards,
                  color: _green,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    children: [
                      ..._cards.map(_buildCard),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _openAddCard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: _green),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const LocalizedText(
                          'Добавить карту',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
