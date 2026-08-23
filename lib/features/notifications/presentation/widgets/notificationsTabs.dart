import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/notifications/presentation/models/notificationsTab.dart';

class NotificationsTabs extends StatelessWidget {
  const NotificationsTabs({
    super.key,
    required this.selectedTab,
    required this.ordersUnreadCount,
    required this.promosUnreadCount,
    required this.onChanged,
  });

  final NotificationsTab selectedTab;
  final int ordersUnreadCount;
  final int promosUnreadCount;
  final ValueChanged<NotificationsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _NotificationsTabButton(
              label: NotificationsTab.orders.label,
              unreadCount: ordersUnreadCount,
              selected: selectedTab == NotificationsTab.orders,
              onTap: () => onChanged(NotificationsTab.orders),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _NotificationsTabButton(
              label: NotificationsTab.promos.label,
              unreadCount: promosUnreadCount,
              selected: selectedTab == NotificationsTab.promos,
              onTap: () => onChanged(NotificationsTab.promos),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsTabButton extends StatelessWidget {
  const _NotificationsTabButton({
    required this.label,
    required this.unreadCount,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int unreadCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected ? const Color(0xFF489F2A) : Colors.white;
    final borderColor =
        selected ? const Color(0xFF489F2A) : const Color(0xFFE0E0E0);
    final textColor = selected ? Colors.white : const Color(0xFF444444);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF489F2A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
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
