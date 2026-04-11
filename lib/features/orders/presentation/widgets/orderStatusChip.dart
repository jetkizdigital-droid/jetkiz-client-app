import 'package:flutter/material.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final ui = _mapStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ui.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ui.label,
        style: TextStyle(
          color: ui.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _OrderStatusUi _mapStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'CREATED':
        return const _OrderStatusUi(
          label: 'Создан',
          backgroundColor: Color(0xFFEAF7E5),
          textColor: Color(0xFF489F2A),
        );
      case 'ACCEPTED':
        return const _OrderStatusUi(
          label: 'Принят',
          backgroundColor: Color(0xFFEAF7E5),
          textColor: Color(0xFF489F2A),
        );
      case 'COOKING':
        return const _OrderStatusUi(
          label: 'Готовится',
          backgroundColor: Color(0xFFFFF4DB),
          textColor: Color(0xFFB7791F),
        );
      case 'READY':
        return const _OrderStatusUi(
          label: 'Готов',
          backgroundColor: Color(0xFFE6F0FF),
          textColor: Color(0xFF2B6CB0),
        );
      case 'ON_THE_WAY':
        return const _OrderStatusUi(
          label: 'В пути',
          backgroundColor: Color(0xFFE6F0FF),
          textColor: Color(0xFF2B6CB0),
        );
      case 'DELIVERED':
        return const _OrderStatusUi(
          label: 'Доставлен',
          backgroundColor: Color(0xFFF0F0F0),
          textColor: Color(0xFF4A5568),
        );
      case 'PAID':
        return const _OrderStatusUi(
          label: 'Оплачен',
          backgroundColor: Color(0xFFF0F0F0),
          textColor: Color(0xFF4A5568),
        );
      case 'CANCELED':
        return const _OrderStatusUi(
          label: 'Отменён',
          backgroundColor: Color(0xFFFDE8E8),
          textColor: Color(0xFFC53030),
        );
      default:
        return _OrderStatusUi(
          label: raw,
          backgroundColor: const Color(0xFFF0F0F0),
          textColor: Colors.black87,
        );
    }
  }
}

class _OrderStatusUi {
  const _OrderStatusUi({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
}