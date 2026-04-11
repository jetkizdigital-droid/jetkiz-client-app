import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import '../domain/createReviewModels.dart';

class CreateReviewApi {
  final ApiClient _client;

  CreateReviewApi(this._client);

  Future<void> createReview(CreateReviewRequest request) async {
    await _client.dio.post<void>(
      '/restaurants/reviews',
      data: request.toJson(),
      options: Options(
        contentType: Headers.jsonContentType,
      ),
    );
  }
}