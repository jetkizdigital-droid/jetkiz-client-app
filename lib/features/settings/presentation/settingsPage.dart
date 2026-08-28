import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/core/push/pushNotificationService.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/features/addresses/data/addressRepository.dart';
import 'package:jetkiz_mobile/features/auth/data/authSessionController.dart';
import 'package:jetkiz_mobile/features/auth/data/authStorage.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesController.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentMethodsPage.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';
import 'package:jetkiz_mobile/features/profile/data/profileApi.dart';

/// SettingsPage
///
/// Контекст для будущих сессий ChatGPT:
/// - Это отдельный экран настроек из ProfilePage.
/// - Язык меняется ГЛОБАЛЬНО на уровне всего приложения через
///   AppLocalizationScope.
/// - Удаление аккаунта доступно здесь как отдельное явное действие и
///   дополнительно остаётся доступным в ProfilePage.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool _isDeletingAccount = false;

  late final ApiClient _apiClient;
  late final ProfileApi _profileApi;

  static const _background = Color(0xFFF5F5F5);
  static const _tileColor = Color(0xFFD9D9D9);
  static const _green = Color(0xFF489F2A);
  static const _danger = Color(0xFFD92D20);

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _profileApi = ProfileApi(_apiClient);
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      notificationsEnabled =
          preferences.getBool(PushNotificationService.preferenceKey) ?? true;
    });
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    setState(() => notificationsEnabled = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(PushNotificationService.preferenceKey, value);

    final service = PushNotificationService(_apiClient);
    if (value) {
      await service.init();
    } else {
      await service.unregisterCurrentToken();
    }
  }

  Future<void> _openPrivacy() async {
    final opened = await launchUrl(
      Uri.parse('https://jetkiz.asia/privacy'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('Не удалось открыть страницу')),
      );
    }
  }

  Future<void> _openPaymentMethods() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
    );
  }

  Future<void> _confirmAndDeleteAccount() async {
    if (_isDeletingAccount) return;

    final strings = AppLocalizationScope.of(context).strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: LocalizedText(strings.deleteAccountTitle),
        content: LocalizedText(strings.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: LocalizedText(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: LocalizedText(strings.deleteForever),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);

    try {
      await PushNotificationService(_apiClient).unregisterCurrentToken();
      await _profileApi.deleteMyAccount();
      await _clearLocalSessionAndExit();
    } on ProfileApiException catch (error) {
      if (!mounted) return;
      final message = error.statusCode == 409
          ? strings.accountDeleteBlocked
          : strings.accountDeleteFailed;
      _showSnack(message);
    } catch (_) {
      if (mounted) _showSnack(strings.accountDeleteFailed);
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  Future<void> _clearLocalSessionAndExit() async {
    await AuthStorage().clear();
    await _apiClient.clearAccessToken();
    CartRepository.instance.clear();
    AddressRepository.instance.clearSelectedAddress();
    FavoritesController.instance.reset();
    AuthSessionController.instance.sessionChanged();

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: LocalizedText(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppLocalizationScope.of(context);
    final strings = scope.strings;
    final language = scope.language;
    final paymentStrings = PaymentStrings.of(context);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  LocalizedText(
                    strings.settingsTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SvgPicture.asset(
                'assets/images/Vector.svg',
                height: 40,
              ),
            ),
            const SizedBox(height: 30),
            _tile(
              child: Row(
                children: [
                  _icon(Icons.security),
                  const SizedBox(width: 14),
                  Expanded(child: LocalizedText(strings.settingsSecurity)),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _openPrivacy,
            ),
            const SizedBox(height: 10),
            _tile(
              child: Row(
                children: [
                  _icon(Icons.notifications),
                  const SizedBox(width: 14),
                  Expanded(
                    child: LocalizedText(strings.settingsNotifications),
                  ),
                  Switch(
                    value: notificationsEnabled,
                    activeThumbColor: _green,
                    onChanged: _setNotificationsEnabled,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _tile(
              child: Row(
                children: [
                  _icon(Icons.language),
                  const SizedBox(width: 14),
                  Expanded(child: LocalizedText(strings.settingsLanguage)),
                  _languageButton(
                    label: 'Рус',
                    selected: language == AppLanguage.ru,
                    onTap: () => scope.onLanguageChanged(AppLanguage.ru),
                  ),
                  const SizedBox(width: 6),
                  _languageButton(
                    label: 'Қаз',
                    selected: language == AppLanguage.kk,
                    onTap: () => scope.onLanguageChanged(AppLanguage.kk),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _tile(
              child: Row(
                children: [
                  _icon(Icons.credit_card_rounded),
                  const SizedBox(width: 14),
                  Expanded(child: Text(paymentStrings.paymentMethods)),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _openPaymentMethods,
            ),
            const SizedBox(height: 24),
            _tile(
              child: Row(
                children: [
                  _dangerIcon(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: LocalizedText(
                      _isDeletingAccount
                          ? strings.deletingAccount
                          : strings.deleteAccount,
                      style: const TextStyle(
                        color: _danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_isDeletingAccount)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _danger,
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right,
                      color: _danger,
                    ),
                ],
              ),
              onTap: _isDeletingAccount ? null : _confirmAndDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({required Widget child, VoidCallback? onTap}) {
    return Material(
      color: _tileColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _icon(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: _green),
    );
  }

  Widget _dangerIcon() {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        size: 19,
        color: _danger,
      ),
    );
  }

  Widget _languageButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: LocalizedText(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
