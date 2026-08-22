import 'package:dio/dio.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/addresses/domain/address.dart';

/// API layer for saved client addresses.
///
/// Endpoints:
/// - GET /addresses/my
/// - POST /addresses
/// - PUT /addresses/:id
/// - DELETE /addresses/:id
///
/// Do not call Dio directly from UI.
/// All address requests must go through this API layer.
class AddressesApi {
  AddressesApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Address>> getMyAddresses() async {
    final response = await _client.get('/addresses/my');
    final data = response.data;

    final rawItems = _extractList(data);

    return rawItems
        .whereType<Map>()
        .map((item) => Address.fromJson(Map<String, dynamic>.from(item)))
        .where((address) => address.isValid)
        .toList();
  }

  Future<Address> createAddress(SaveAddressPayload payload) async {
    final response = await _client.post(
      '/addresses',
      data: payload.toJson(),
    );

    return _parseAddressResponse(response.data);
  }

  Future<Address> updateAddress(
    String addressId,
    SaveAddressPayload payload,
  ) async {
    final id = addressId.trim();

    if (id.isEmpty) {
      throw ArgumentError('addressId is required');
    }

    final response = await _client.put(
      '/addresses/$id',
      data: payload.toJson(),
    );

    return _parseAddressResponse(response.data);
  }

  Future<void> deleteAddress(String addressId) async {
    final id = addressId.trim();

    if (id.isEmpty) {
      throw ArgumentError('addressId is required');
    }

    await _client.delete('/addresses/$id');
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final items = data['items'] ?? data['addresses'] ?? data['data'];

      if (items is List) {
        return items;
      }
    }

    throw Exception('Invalid addresses response: expected list');
  }

  Address _parseAddressResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Address.fromJson(data);
    }

    if (data is Map) {
      final address = data['address'] ?? data['item'] ?? data['data'];

      if (address is Map) {
        return Address.fromJson(Map<String, dynamic>.from(address));
      }

      return Address.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Invalid address response');
  }

  Dio get _client => _apiClient.dio;
}

class SaveAddressPayload {
  const SaveAddressPayload({
    required this.title,
    required this.address,
    this.floor,
    this.door,
    this.entrance,
    this.intercom,
    this.contactPhone,
    this.comment,
  });

  final String title;
  final String address;
  final String? floor;
  final String? door;
  final String? entrance;
  final String? intercom;
  final String? contactPhone;
  final String? comment;

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'address': address.trim(),
      'floor': _normalizeOptional(floor),
      'door': _normalizeOptional(door),
      'entrance': _normalizeOptional(entrance),
      'intercom': _normalizeOptional(intercom),
      'contactPhone': normalizeKazakhstanPhoneOrNull(contactPhone),
      'comment': _normalizeOptional(comment),
    };
  }

  static String? _normalizeOptional(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

String? normalizeKazakhstanPhoneOrNull(String? value) {
  final raw = value?.trim() ?? '';

  if (raw.isEmpty) {
    return null;
  }

  final digits = raw.replaceAll(RegExp(r'\D'), '');

  if (digits.isEmpty) {
    return null;
  }

  if (digits.length == 10) {
    return '+7$digits';
  }

  if (digits.length == 11 && digits.startsWith('8')) {
    return '+7${digits.substring(1)}';
  }

  if (digits.length == 11 && digits.startsWith('7')) {
    return '+$digits';
  }

  if (digits.length == 12 && digits.startsWith('77')) {
    return '+${digits.substring(1)}';
  }

  return '+$digits';
}
