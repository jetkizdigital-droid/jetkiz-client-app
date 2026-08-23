import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:jetkiz_mobile/features/reviews/domain/restaurantReview.dart';
import 'package:jetkiz_mobile/features/reviews/presentation/widgets/reviewMediaBlocks.dart';
import 'package:jetkiz_mobile/features/reviews/presentation/widgets/reviewReactions.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
  });

  final RestaurantReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewHeader(review: review),
                const SizedBox(height: 12),
                if (review.hasText)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: LocalizedText(
                      review.text!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                if (review.hasMedia) ReviewMediaBlocks(items: review.media),
                if (review.reactions.isNotEmpty ||
                    review.reactionsSummary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ReviewReactions(
                    items: review.reactions,
                    summary: review.reactionsSummary,
                  ),
                ],
              ],
            ),
          ),
          if (review.response != null && !review.response!.isHidden)
            _RestaurantReplySection(
              response: review.response!,
            ),
        ],
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({
    required this.review,
  });

  final RestaurantReview review;

  @override
  Widget build(BuildContext context) {
    final user = review.user;
    final avatarUrl = (user?.avatarUrl ?? '').trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFF3F4F6),
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF6B7280),
                  ),
                )
              : const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF6B7280),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LocalizedText(
                      user?.displayName ?? 'Пользователь',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  LocalizedText(
                    _formatRelativeOrDate(review.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      index < review.rating
                          ? Icons.star_rounded
                          : Icons.star_rounded,
                      size: 18,
                      color: index < review.rating
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatRelativeOrDate(DateTime value) {
    final now = DateTime.now();
    final local = value.toLocal();
    final diff = now.difference(local);

    if (diff.inDays == 0) {
      return 'сегодня';
    }
    if (diff.inDays == 1) {
      return '1 день назад';
    }
    if (diff.inDays < 5) {
      return '${diff.inDays} дня назад';
    }
    if (diff.inDays < 8) {
      return '${diff.inDays} дней назад';
    }

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day.$month.$year';
  }
}

class _RestaurantReplySection extends StatelessWidget {
  const _RestaurantReplySection({
    required this.response,
  });

  final ReviewResponse response;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x0D489F2A),
            Color(0x1A489F2A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          top: BorderSide(
            color: Color(0x33489F2A),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF489F2A),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const LocalizedText(
                  'R',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    const LocalizedText(
                      'Ответ ресторана',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LocalizedText(
                      _formatDate(response.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (response.hasText)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: LocalizedText(
                      response.text!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                if (response.hasMedia) ReviewMediaBlocks(items: response.media),
                if (response.reactions.isNotEmpty ||
                    response.reactionsSummary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ReviewReactions(
                    items: response.reactions,
                    summary: response.reactionsSummary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final d = value.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day.$month.$year';
  }
}
