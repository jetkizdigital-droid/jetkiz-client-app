import 'package:flutter/foundation.dart';
import 'package:jetkiz_mobile/features/auth/data/authStorage.dart';

class AuthSessionController extends ChangeNotifier {
  AuthSessionController._();

  static final AuthSessionController instance = AuthSessionController._();

  Future<bool> isAuthorized() => AuthStorage().hasAccessToken();

  void sessionChanged() => notifyListeners();
}
