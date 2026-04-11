import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/auth/data/authStorage.dart';
import 'package:jetkiz_mobile/features/auth/presentation/phoneLoginPage.dart';
import 'package:jetkiz_mobile/features/profile/data/profileApi.dart';
import 'package:jetkiz_mobile/features/profile/presentation/profilePage.dart';

/// JETKIZ MOBILE
/// Auth gate for Profile tab.
///
/// RULES:
/// - if there is no token -> open PhoneLoginPage
/// - if token exists -> try GET /users/me
/// - if /users/me fails and refresh also fails -> clear broken session
///   and open PhoneLoginPage
///
/// IMPORTANT:
/// This screen must always use the shared singleton ApiClient.
/// Do not create raw Dio here.
class ProfileEntryPage extends StatefulWidget {
  const ProfileEntryPage({super.key});

  @override
  State<ProfileEntryPage> createState() => _ProfileEntryPageState();
}

class _ProfileEntryPageState extends State<ProfileEntryPage> {
  final AuthStorage _authStorage = AuthStorage();
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _apiClient.init();
      await _apiClient.loadTokensFromStorage();

      final hasToken = await _authStorage.hasAccessToken();

      if (!hasToken) {
        if (!mounted) return;
        setState(() {
          _isAuthorized = false;
          _isLoading = false;
        });
        return;
      }

      final profileApi = ProfileApi(_apiClient);
      await profileApi.getMe();

      if (!mounted) return;
      setState(() {
        _isAuthorized = true;
        _isLoading = false;
      });
    } catch (_) {
      await _apiClient.clearTokens();

      if (!mounted) return;
      setState(() {
        _isAuthorized = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAuthorized() async {
    await _bootstrap();
  }

  Future<void> _handleLoggedOut() async {
    await _apiClient.clearTokens();

    if (!mounted) return;
    setState(() {
      _isAuthorized = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthorized) {
      return ProfilePage(
        onLoggedOut: _handleLoggedOut,
      );
    }

    return PhoneLoginPage(
      onAuthorized: _handleAuthorized,
    );
  }
}