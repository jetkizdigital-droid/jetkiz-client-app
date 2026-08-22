import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/addresses/domain/address.dart';

/// Shared selected address state for the client app.
///
/// Current consumers:
/// - HomePage
/// - CartPage
/// - Checkout flow
///
/// This repository stores selected address in memory.
/// Later it can be extended with local persistence without changing UI screens.
class AddressRepository extends ChangeNotifier {
  AddressRepository._();

  static final AddressRepository instance = AddressRepository._();

  Address? _selectedAddress;

  Address? get selectedAddress => _selectedAddress;

  String? get selectedAddressId => _selectedAddress?.id;

  bool get hasSelectedAddress => _selectedAddress != null;

  void setSelectedAddress(Address address) {
    if (!address.isValid) return;

    if (_selectedAddress?.id == address.id &&
        _selectedAddress?.updatedAt == address.updatedAt) {
      return;
    }

    _selectedAddress = address;
    notifyListeners();
  }

  void clearSelectedAddress() {
    if (_selectedAddress == null) return;

    _selectedAddress = null;
    notifyListeners();
  }

  void clearIfSelected(String addressId) {
    final id = addressId.trim();

    if (id.isEmpty) return;
    if (_selectedAddress?.id != id) return;

    clearSelectedAddress();
  }

  void syncSelectedFromList(List<Address> addresses) {
    final currentId = _selectedAddress?.id;

    if (currentId == null || currentId.trim().isEmpty) {
      return;
    }

    Address? updated;

    for (final address in addresses) {
      if (address.id == currentId) {
        updated = address;
        break;
      }
    }

    if (updated == null) {
      clearSelectedAddress();
      return;
    }

    setSelectedAddress(updated);
  }
}