import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:jetkiz_mobile/features/orders/domain/orderHistoryItem.dart';
import 'package:jetkiz_mobile/features/orders/presentation/widgets/orderStatusChip.dart';

class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({
    super.key,
    required this.item,
    required this.onDetailsTap,
  });

  final OrderHistoryItem item;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    final previewText = item.previewItems.isEmpty
        ? 'Состав заказа недоступен'
        : item.previewItems
            .take(2)
            .map((e) => '${e.title} x${e.quantity}')
            .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LocalizedText(
                    'Заказ №${item.number}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                OrderStatusChip(
                  status: item.status,
                  fulfillmentType: item.fulfillmentType,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _RestaurantImage(url: item.restaurant.coverImageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: LocalizedText(
                    item.restaurant.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LocalizedText(
              _formatDate(item.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A7A7A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            LocalizedText(
              previewText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A4A4A),
                height: 1.35,
              ),
            ),
            if (item.isPickup) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const _MetaChip(
                    icon: Icons.shopping_bag_outlined,
                    text: 'Самовывоз',
                  ),
                  if (item.canShowPickupCode)
                    _MetaChip(
                      icon: Icons.pin_rounded,
                      text: 'Код: ${item.pickupCode!.trim()}',
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: LocalizedText(
                    '${item.total} ₸',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: onDetailsTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF489F2A),
                    side: const BorderSide(color: Color(0xFF489F2A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: const LocalizedText(
                    'Подробнее',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}  ${two(value.hour)}:${two(value.minute)}';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 5),
          LocalizedText(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final raw = (url ?? '').trim();
    if (raw.isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        raw,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: Color(0xFF489F2A),
      ),
    );
  }
}
