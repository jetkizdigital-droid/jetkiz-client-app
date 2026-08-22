class CreateReviewRequest {
  final String orderId;
  final int rating;
  final String? text;

  final int? foodRating;
  final int? deliveryRating;
  final int? packingRating;
  final int? valueRating;
  final int? accuracyRating;

  final List<String>? pros;
  final List<String>? cons;

  final List<CreateReviewMediaInput> media;

  CreateReviewRequest({
    required this.orderId,
    required this.rating,
    this.text,
    this.foodRating,
    this.deliveryRating,
    this.packingRating,
    this.valueRating,
    this.accuracyRating,
    this.pros,
    this.cons,
    required this.media,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'rating': rating,
      'text': text,
      'foodRating': foodRating,
      'deliveryRating': deliveryRating,
      'packingRating': packingRating,
      'valueRating': valueRating,
      'accuracyRating': accuracyRating,
      'pros': pros,
      'cons': cons,
      'media': media.map((e) => e.toJson()).toList(),
    };
  }
}

class CreateReviewMediaInput {
  final String type; // IMAGE | VIDEO | AUDIO
  final String url;
  final String? previewUrl;

  CreateReviewMediaInput({
    required this.type,
    required this.url,
    this.previewUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'previewUrl': previewUrl,
    };
  }
}

class UploadReviewMediaResponse {
  final String type;
  final String url;
  final String? previewUrl;
  final String originalName;
  final String originalMimeType;
  final int size;

  UploadReviewMediaResponse({
    required this.type,
    required this.url,
    this.previewUrl,
    required this.originalName,
    required this.originalMimeType,
    required this.size,
  });

  factory UploadReviewMediaResponse.fromJson(Map<String, dynamic> json) {
    return UploadReviewMediaResponse(
      type: json['type'],
      url: json['url'],
      previewUrl: json['previewUrl'],
      originalName: json['originalName'],
      originalMimeType: json['originalMimeType'],
      size: json['size'],
    );
  }
}
