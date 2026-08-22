import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/notifications/domain/notificationItem.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.item,
    required this.isOrderNotification,
    required this.onTap,
  });

  final NotificationItem item;
  final bool isOrderNotification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasOrder = (item.orderId ?? '').trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE7E7E7)
                  : const Color(0xFF489F2A),
              width: item.isRead ? 1 : 1.4,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationLeading(
                isRead: item.isRead,
                type: item.type,
                isOrderNotification: isOrderNotification,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NotificationContent(
                  item: item,
                  hasOrder: hasOrder,
                  onOpenOrderTap: onTap,
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF489F2A),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({
    required this.item,
    required this.hasOrder,
    required this.onOpenOrderTap,
  });

  final NotificationItem item;
  final bool hasOrder;
  final VoidCallback onOpenOrderTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDateTime(item.createdAt),
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          item.body,
          style: const TextStyle(
            color: Color(0xFF2B2B2B),
            fontSize: 14,
            height: 1.35,
          ),
        ),
        if (hasOrder) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              _OpenOrderButton(onTap: onOpenOrderTap),
            ],
          ),
        ],
      ],
    );
  }
}

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({
    required this.isRead,
    required this.type,
    required this.isOrderNotification,
  });

  final bool isRead;
  final String type;
  final bool isOrderNotification;

  IconData _pickIcon() {
    final normalized = type.trim().toUpperCase();

    if (isOrderNotification) {
      switch (normalized) {
        case 'ORDER_DELIVERED':
          return Icons.check_circle_rounded;
        case 'ORDER_CANCELED':
          return Icons.cancel_rounded;
        case 'ORDER_ACCEPTED':
        case 'ORDER_READY':
        case 'ORDER_ON_THE_WAY':
          return Icons.receipt_long_rounded;
        default:
          return Icons.local_shipping_rounded;
      }
    }

    return Icons.local_offer_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _pickIcon();

    final backgroundColor =
        isOrderNotification ? const Color(0xFFEAF7E5) : const Color(0xFFFFF4DB);

    final iconColor =
        isOrderNotification ? const Color(0xFF2E7D32) : const Color(0xFFB7791F);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: isRead ? iconColor.withValues(alpha: 0.78) : iconColor,
        size: 22,
      ),
    );
  }
}

class _OpenOrderButton extends StatelessWidget {
  const _OpenOrderButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF489F2A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Text(
            'Открыть заказ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final now = DateTime.now();
  final local = value.toLocal();

  final isToday = now.year == local.year &&
      now.month == local.month &&
      now.day == local.day;

  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');

  if (isToday) {
    return '$hh:$mm';
  }

  final dd = local.day.toString().padLeft(2, '0');
  final mo = local.month.toString().padLeft(2, '0');

  return '$dd.$mo $hh:$mm';
}
