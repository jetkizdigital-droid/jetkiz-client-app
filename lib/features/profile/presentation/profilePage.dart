import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/core/push/pushNotificationService.dart';
import 'package:jetkiz_mobile/core/support/supportLauncher.dart';
import 'package:jetkiz_mobile/features/addresses/data/addressRepository.dart';
import 'package:jetkiz_mobile/features/addresses/presentation/addressesPage.dart';
import 'package:jetkiz_mobile/features/auth/data/authStorage.dart';
import 'package:jetkiz_mobile/features/auth/data/authSessionController.dart';
import 'package:jetkiz_mobile/features/cart/data/cartRepository.dart';
import 'package:jetkiz_mobile/features/favorites/data/favoritesController.dart';
import 'package:jetkiz_mobile/features/orders/presentation/ordersPage.dart';
import 'package:jetkiz_mobile/features/profile/data/profileApi.dart';
import 'package:jetkiz_mobile/features/profile/domain/profileData.dart';
import 'package:jetkiz_mobile/features/profile/presentation/widgets/editProfileSheet.dart';
import 'package:jetkiz_mobile/features/settings/presentation/settingsPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.onLoggedOut,
  });

  final VoidCallback? onLoggedOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _green = Color(0xFF489F2A);
  static const _background = Color(0xFFF9FAFB);
  static const _textLight = Color(0xFF9CA3AF);

  late final ApiClient _apiClient;
  late final ProfileApi _profileApi;

  final ImagePicker _imagePicker = ImagePicker();

  ProfileData? _profile;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _profileApi = ProfileApi(_apiClient);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final profile = await _profileApi.getMe();

      if (!mounted) return;

      setState(() {
        _profile = profile;
      });
    } catch (error) {
      if (!mounted) return;

      if (error is ProfileApiException && error.statusCode == 401) {
        await _clearLocalSessionAndExit();
        return;
      }

      setState(() {
        _errorText = 'Не удалось загрузить профиль. Попробуйте ещё раз.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (picked == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final updatedProfile = await _profileApi.uploadMyAvatar(
        File(picked.path),
      );

      if (!mounted) return;

      setState(() {
        _profile = updatedProfile;
      });

      _showSnack('Фото профиля обновлено');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Не удалось загрузить фото. Попробуйте ещё раз.');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await showEditProfileSheet(
      context: context,
      profile: _profile,
      onSave: (dto) => _profileApi.updateMe(dto),
    );

    if (!mounted || updated == null) return;

    setState(() {
      _profile = updated;
    });

    _showSnack('Данные профиля сохранены');
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await PushNotificationService(_apiClient).unregisterCurrentToken();
      await _profileApi.logout();
    } finally {
      await _clearLocalSessionAndExit();
    }
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    final authStorage = AuthStorage();

    await authStorage.clear();
    await _apiClient.clearAccessToken();
    CartRepository.instance.clear();
    AddressRepository.instance.clearSelectedAddress();
    FavoritesController.instance.reset();
    AuthSessionController.instance.sessionChanged();

    if (!mounted) return;

    widget.onLoggedOut?.call();
  }

  void _showComingSoon(String title) {
    _showSnack('$title скоро будет доступно.');
  }

  Future<void> _openWebPage(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showSnack('Не удалось открыть страницу');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: LocalizedText(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizationScope.of(context).strings;
    final menuItems = <_ProfileMenuItem>[
      _ProfileMenuItem(
        icon: Icons.badge_outlined,
        label: strings.profileMyData,
        iconColor: const Color(0xFF3B82F6),
        onTap: _openEditProfile,
      ),
      _ProfileMenuItem(
        icon: Icons.credit_card_outlined,
        label: strings.profileAddCard,
        iconColor: const Color(0xFF8B5CF6),
        onTap: () => _showComingSoon(strings.profileAddCard),
      ),
      _ProfileMenuItem(
        icon: Icons.settings_outlined,
        label: strings.profileSettings,
        iconColor: const Color(0xFF4B5563),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SettingsPage(),
            ),
          );
        },
      ),
      _ProfileMenuItem(
        icon: Icons.location_on_outlined,
        label: strings.profileAddresses,
        iconColor: const Color(0xFF489F2A),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddressesPage(),
            ),
          );
        },
      ),
      _ProfileMenuItem(
        icon: Icons.history_rounded,
        label: strings.profileOrdersHistory,
        iconColor: const Color(0xFFF59E0B),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OrdersPage(),
            ),
          );
        },
      ),
      _ProfileMenuItem(
        icon: Icons.support_agent_outlined,
        label: strings.profileSupport,
        iconColor: const Color(0xFF06B6D4),
        onTap: () => SupportLauncher.openWhatsApp(context),
      ),
      _ProfileMenuItem(
        icon: Icons.description_outlined,
        label: strings.profilePublicOffer,
        iconColor: const Color(0xFF6366F1),
        onTap: () => _openWebPage('https://jetkiz.asia/privacy'),
      ),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _green,
          onRefresh: _loadProfile,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Center(
                child: LocalizedText(
                  strings.profileTitle,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: _green),
                  ),
                )
              else if (_errorText != null)
                _ProfileErrorCard(
                  message: _errorText!,
                  retryText: strings.retry,
                  onRetry: _loadProfile,
                )
              else ...[
                _ProfileHeaderCard(
                  profile: _profile,
                  isUploadingAvatar: _isUploadingAvatar,
                  onAvatarTap: _pickAndUploadAvatar,
                ),
                const SizedBox(height: 24),
                ...menuItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProfileMenuTile(item: item),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _green,
                            ),
                          )
                        : const Icon(Icons.logout_rounded, size: 24),
                    label: LocalizedText(
                      _isLoggingOut ? strings.loggingOut : strings.logout,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _green, width: 2),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed:
                      _isDeletingAccount ? null : _confirmAndDeleteAccount,
                  icon: _isDeletingAccount
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: LocalizedText(
                    _isDeletingAccount
                        ? strings.deletingAccount
                        : strings.deleteAccount,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: LocalizedText(
                    strings.appVersion,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textLight,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.profile,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
  });

  final ProfileData? profile;
  final bool isUploadingAvatar;
  final VoidCallback onAvatarTap;

  static const _green = Color(0xFF489F2A);
  static const _cardBorder = Color(0xFFF0F1F3);
  static const _textMain = Color(0xFF1F2937);
  static const _textMuted = Color(0xFF6B7280);
  static const _textLight = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizationScope.of(context).strings;
    final avatarUrl = (profile?.resolvedAvatarUrl ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              GestureDetector(
                onTap: isUploadingAvatar ? null : onAvatarTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE5E7EB),
                        border: Border.all(
                          color: _green.withValues(alpha: 0.12),
                          width: 4,
                        ),
                      ),
                      child: ClipOval(
                        child: avatarUrl.isNotEmpty
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return const _AvatarPlaceholder();
                                },
                              )
                            : const _AvatarPlaceholder(),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isUploadingAvatar
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 96,
                child: LocalizedText(
                  strings.profileEditPhoto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    profile?.displayTitle ?? strings.profileDefaultName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textMain,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: _textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: LocalizedText(
                          profile?.displaySubtitle ??
                              strings.profileDefaultSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _ActiveDot(),
                        const SizedBox(width: 6),
                        LocalizedText(
                          strings.profileActive,
                          style: const TextStyle(
                            color: _green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.item,
  });

  final _ProfileMenuItem item;

  static const _cardBorder = Color(0xFFF0F1F3);
  static const _textMain = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: item.iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: LocalizedText(
                  item.label,
                  style: const TextStyle(
                    color: _textMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB9BDC5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE5E7EB),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 42,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _ActiveDot extends StatelessWidget {
  const _ActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF489F2A),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ProfileErrorCard extends StatelessWidget {
  const _ProfileErrorCard({
    required this.message,
    required this.retryText,
    required this.onRetry,
  });

  final String message;
  final String retryText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF0F1F3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 34,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 10),
          LocalizedText(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: LocalizedText(retryText),
          ),
        ],
      ),
    );
  }
}
