import 'package:jetkiz_mobile/core/config/appConfig.dart';

class RestaurantReviewPageData {
  const RestaurantReviewPageData({
    required this.items,
    required this.total,
    required this.reactionSummary,
  });

  final List<RestaurantReview> items;
  final int total;
  final List<ReviewReactionSummaryItem> reactionSummary;

  factory RestaurantReviewPageData.fromJson(Map<String, dynamic> json) {
    final itemsRaw = _extractList(json, const ['items']) ??
        _extractList(json, const ['data', 'items']) ??
        _extractList(json, const ['result', 'items']) ??
        const [];

    final summaryRaw = _extractList(json, const ['reactionSummary']) ??
        _extractList(json, const ['data', 'reactionSummary']) ??
        const [];

    return RestaurantReviewPageData(
      items: itemsRaw
          .whereType<Map>()
          .map((e) => RestaurantReview.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: _readInt(json, const ['total']) ??
          _readInt(json, const ['data', 'total']) ??
          _readInt(json, const ['meta', 'total']) ??
          itemsRaw.length,
      reactionSummary: summaryRaw
          .whereType<Map>()
          .map(
            (e) => ReviewReactionSummaryItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class RestaurantReview {
  const RestaurantReview({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.text,
    this.foodRating,
    this.deliveryRating,
    this.packingRating,
    this.valueRating,
    this.accuracyRating,
    this.pros = const [],
    this.cons = const [],
    this.isHidden = false,
    this.user,
    this.order,
    this.media = const [],
    this.reactions = const [],
    this.reactionsSummary = const [],
    this.currentUserReaction,
    this.response,
  });

  final String id;
  final int rating;
  final DateTime createdAt;
  final String? text;

  final int? foodRating;
  final int? deliveryRating;
  final int? packingRating;
  final int? valueRating;
  final int? accuracyRating;

  final List<String> pros;
  final List<String> cons;
  final bool isHidden;

  final ReviewUser? user;
  final ReviewOrder? order;
  final List<ReviewMediaItem> media;
  final List<ReviewReactionItem> reactions;
  final List<ReviewReactionSummaryItem> reactionsSummary;
  final String? currentUserReaction;
  final ReviewResponse? response;

  bool get hasText => (text ?? '').trim().isNotEmpty;
  bool get hasMedia => media.isNotEmpty;
  bool get hasResponse => response != null;
  bool get hasPros => pros.isNotEmpty;
  bool get hasCons => cons.isNotEmpty;

  factory RestaurantReview.fromJson(Map<String, dynamic> json) {
    final mediaRaw = _extractList(json, const ['media']) ?? const [];
    final reactionsRaw = _extractList(json, const ['reactions']) ?? const [];

    return RestaurantReview(
      id: _readString(json, const ['id']),
      rating: _readInt(json, const ['rating']) ?? 0,
      createdAt: _readDateTime(json, const ['createdAt']) ?? DateTime.now(),
      text: _readNullableString(json, const ['text']),
      foodRating: _readInt(json, const ['foodRating']),
      deliveryRating: _readInt(json, const ['deliveryRating']),
      packingRating: _readInt(json, const ['packingRating']),
      valueRating: _readInt(json, const ['valueRating']),
      accuracyRating: _readInt(json, const ['accuracyRating']),
      pros: _readStringList(json, const ['pros']),
      cons: _readStringList(json, const ['cons']),
      isHidden: _readBool(json, const ['isHidden']),
      user: _readMap(json, const ['user']) == null
          ? null
          : ReviewUser.fromJson(_readMap(json, const ['user'])!),
      order: _readMap(json, const ['order']) == null
          ? null
          : ReviewOrder.fromJson(_readMap(json, const ['order'])!),
      media: mediaRaw
          .whereType<Map>()
          .map((e) => ReviewMediaItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      reactions: reactionsRaw
          .whereType<Map>()
          .map((e) => ReviewReactionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      reactionsSummary: _readReactionSummary(json),
      currentUserReaction:
          _readNullableString(json, const ['currentUserReaction']),
      response: _readMap(json, const ['response']) == null
          ? null
          : ReviewResponse.fromJson(_readMap(json, const ['response'])!),
    );
  }
}

class ReviewUser {
  const ReviewUser({
    required this.id,
    this.phone,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  final String id;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;

  String get displayName {
    final full = [
      if ((firstName ?? '').trim().isNotEmpty) firstName!.trim(),
      if ((lastName ?? '').trim().isNotEmpty) lastName!.trim(),
    ].join(' ').trim();

    if (full.isNotEmpty) return full;
    if ((phone ?? '').trim().isNotEmpty) return phone!.trim();
    return 'Пользователь';
  }

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: _readString(json, const ['id']),
      phone: _readNullableString(json, const ['phone']),
      firstName: _readNullableString(json, const ['firstName']),
      lastName: _readNullableString(json, const ['lastName']),
      avatarUrl: _normalizeNullableUrl(
        _readNullableString(json, const ['avatarUrl']),
      ),
    );
  }
}

class ReviewOrder {
  const ReviewOrder({
    required this.id,
    this.number,
    this.status,
    this.total,
    this.createdAt,
    this.deliveredAt,
  });

  final String id;
  final int? number;
  final String? status;
  final int? total;
  final DateTime? createdAt;
  final DateTime? deliveredAt;

  factory ReviewOrder.fromJson(Map<String, dynamic> json) {
    return ReviewOrder(
      id: _readString(json, const ['id']),
      number: _readInt(json, const ['number']),
      status: _readNullableString(json, const ['status']),
      total: _readInt(json, const ['total']),
      createdAt: _readDateTime(json, const ['createdAt']),
      deliveredAt: _readDateTime(json, const ['deliveredAt']),
    );
  }
}

class ReviewMediaItem {
  const ReviewMediaItem({
    required this.id,
    required this.type,
    required this.url,
    this.previewUrl,
    this.createdAt,
  });

  final String id;
  final String type;
  final String url;
  final String? previewUrl;
  final DateTime? createdAt;

  bool get isImage {
    final normalized = type.trim().toLowerCase();
    return normalized == 'image' ||
        normalized.contains('image') ||
        normalized == 'jpg' ||
        normalized == 'jpeg' ||
        normalized == 'png' ||
        normalized == 'webp';
  }

  bool get isVideo {
    final normalized = type.trim().toLowerCase();
    return normalized == 'video' ||
        normalized.contains('video') ||
        normalized == 'mp4' ||
        normalized == 'mov' ||
        normalized == 'm4v' ||
        normalized == 'webm';
  }

  bool get isAudio {
    final normalized = type.trim().toLowerCase();
    return normalized == 'audio' ||
        normalized.contains('audio') ||
        normalized == 'mp3' ||
        normalized == 'm4a' ||
        normalized == 'aac' ||
        normalized == 'wav' ||
        normalized == 'ogg';
  }

  factory ReviewMediaItem.fromJson(Map<String, dynamic> json) {
    return ReviewMediaItem(
      id: _readString(json, const ['id']),
      type: _readString(json, const ['type']),
      url: _normalizeUrl(_readString(json, const ['url'])),
      previewUrl: _normalizeNullableUrl(
        _readNullableString(json, const ['previewUrl']),
      ),
      createdAt: _readDateTime(json, const ['createdAt']),
    );
  }
}

class ReviewReactionItem {
  const ReviewReactionItem({
    required this.id,
    required this.userId,
    required this.type,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final DateTime? createdAt;

  factory ReviewReactionItem.fromJson(Map<String, dynamic> json) {
    return ReviewReactionItem(
      id: _readString(json, const ['id']),
      userId: _readString(json, const ['userId']),
      type: _readString(json, const ['type']),
      createdAt: _readDateTime(json, const ['createdAt']),
    );
  }
}

class ReviewReactionSummaryItem {
  const ReviewReactionSummaryItem({
    required this.type,
    required this.count,
  });

  final String type;
  final int count;

  factory ReviewReactionSummaryItem.fromJson(Map<String, dynamic> json) {
    return ReviewReactionSummaryItem(
      type: _readString(json, const ['type']),
      count: _readInt(json, const ['count']) ?? 0,
    );
  }
}

class ReviewResponse {
  const ReviewResponse({
    required this.id,
    required this.reviewId,
    required this.restaurantId,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.text,
    this.isHidden = false,
    this.createdByUser,
    this.media = const [],
    this.reactions = const [],
    this.reactionsSummary = const [],
    this.currentUserReaction,
  });

  final String id;
  final String reviewId;
  final String restaurantId;
  final String createdByUserId;
  final String? text;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReviewUser? createdByUser;
  final List<ReviewMediaItem> media;
  final List<ReviewReactionItem> reactions;
  final List<ReviewReactionSummaryItem> reactionsSummary;
  final String? currentUserReaction;

  bool get hasText => (text ?? '').trim().isNotEmpty;
  bool get hasMedia => media.isNotEmpty;

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    final mediaRaw = _extractList(json, const ['media']) ?? const [];
    final reactionsRaw = _extractList(json, const ['reactions']) ?? const [];

    return ReviewResponse(
      id: _readString(json, const ['id']),
      reviewId: _readString(json, const ['reviewId']),
      restaurantId: _readString(json, const ['restaurantId']),
      createdByUserId: _readString(json, const ['createdByUserId']),
      text: _readNullableString(json, const ['text']),
      isHidden: _readBool(json, const ['isHidden']),
      createdAt: _readDateTime(json, const ['createdAt']) ?? DateTime.now(),
      updatedAt: _readDateTime(json, const ['updatedAt']) ?? DateTime.now(),
      createdByUser: _readMap(json, const ['createdByUser']) == null
          ? null
          : ReviewUser.fromJson(_readMap(json, const ['createdByUser'])!),
      media: mediaRaw
          .whereType<Map>()
          .map((e) => ReviewMediaItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      reactions: reactionsRaw
          .whereType<Map>()
          .map((e) => ReviewReactionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      reactionsSummary: _readReactionSummary(json),
      currentUserReaction:
          _readNullableString(json, const ['currentUserReaction']),
    );
  }
}

List<ReviewReactionSummaryItem> _readReactionSummary(
  Map<String, dynamic> json,
) {
  final raw = _readMap(json, const ['reactionsSummary']);
  if (raw == null) return const [];

  return raw.entries
      .map(
        (entry) => ReviewReactionSummaryItem(
          type: entry.key,
          count: _parseIntValue(entry.value) ?? 0,
        ),
      )
      .where((item) => item.count > 0)
      .toList();
}

List<dynamic>? _extractList(Map<String, dynamic> json, List<String> path) {
  dynamic current = json;

  for (final part in path) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return null;
    }
  }

  return current is List ? current : null;
}

Map<String, dynamic>? _readMap(Map<String, dynamic> json, List<String> path) {
  dynamic current = json;

  for (final part in path) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return null;
    }
  }

  if (current is Map<String, dynamic>) return current;
  if (current is Map) return Map<String, dynamic>.from(current);
  return null;
}

String _readString(Map<String, dynamic> json, List<String> path) {
  dynamic current = json;

  for (final part in path) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return '';
    }
  }

  return current?.toString() ?? '';
}

String? _readNullableString(Map<String, dynamic> json, List<String> path) {
  final value = _readString(json, path).trim();
  return value.isEmpty ? null : value;
}

int? _readInt(Map<String, dynamic> json, List<String> path) {
  dynamic current = json;

  for (final part in path) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return null;
    }
  }

  if (current is int) return current;
  if (current is String) return int.tryParse(current);
  if (current is num) return current.toInt();
  return null;
}

int? _parseIntValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _readBool(Map<String, dynamic> json, List<String> path) {
  dynamic current = json;

  for (final part in path) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return false;
    }
  }

  return current == true;
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> path) {
  dynamic current = json;

  for (final part in path) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return null;
    }
  }

  if (current is DateTime) return current;
  if (current == null) return null;
  return DateTime.tryParse(current.toString());
}

List<String> _readStringList(Map<String, dynamic> json, List<String> path) {
  dynamic current = json;

  for (final part in path) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return const [];
    }
  }

  if (current is List) {
    return current
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  return const [];
}

String _normalizeUrl(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return '';

  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }

  final base = AppConfig.baseUrl.trim().replaceAll(RegExp(r'/$'), '');

  if (raw.startsWith('/')) {
    return '$base$raw';
  }

  return '$base/$raw';
}

String? _normalizeNullableUrl(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;
  return _normalizeUrl(raw);
}
