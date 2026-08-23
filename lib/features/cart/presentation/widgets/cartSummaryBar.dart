import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';

/// Jetkiz mobile
/// Shared bottom cart summary bar.
///
/// Used on:
/// - restaurant menu page
/// - category/product listing pages
///
/// Important:
/// - This widget is UI-only.
/// - It must not create orders.
/// - It must not send prices/totals to backend.
/// - Checkout/order creation is handled later in CheckoutPage.
class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({
    super.key,
    required this.itemsCount,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.onNextTap,
    this.deliveryLabel = 'Доставка',
    this.basketLabelPrefix = 'В корзине',
    this.nextButtonLabel = 'Далее',
    this.isLoading = false,
    this.isDisabled = false,
  });

  final int itemsCount;
  final int itemsTotal;
  final int deliveryFee;
  final VoidCallback onNextTap;

  final String deliveryLabel;
  final String basketLabelPrefix;
  final String nextButtonLabel;

  final bool isLoading;
  final bool isDisabled;

  int get safeItemsCount => itemsCount < 0 ? 0 : itemsCount;

  int get safeItemsTotal => itemsTotal < 0 ? 0 : itemsTotal;

  int get safeDeliveryFee => deliveryFee < 0 ? 0 : deliveryFee;

  int get grandTotal => safeItemsTotal + safeDeliveryFee;

  bool get _canProceed {
    return !isLoading && !isDisabled && safeItemsCount > 0;
  }

  String _formatPrice(int value) {
    if (value <= 0) {
      return '0 ₸';
    }

    return '$value ₸';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            bottomInset > 0 ? 12 : 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryRow(
                label: deliveryLabel,
                value: isLoading ? '...' : _formatPrice(safeDeliveryFee),
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: '$basketLabelPrefix ($safeItemsCount)',
                value: _formatPrice(safeItemsTotal),
              ),
              const SizedBox(height: 16),
              _NextButton(
                label: nextButtonLabel,
                totalText: isLoading ? '...' : _formatPrice(grandTotal),
                enabled: _canProceed,
                isLoading: isLoading,
                onTap: onNextTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LocalizedText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        LocalizedText(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.label,
    required this.totalText,
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final String totalText;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SizedBox(
        width: double.infinity,
        height: 53,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF489F2A),
            disabledBackgroundColor: const Color(0xFF489F2A),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                LocalizedText(
                  label,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: LocalizedText(
                    totalText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
