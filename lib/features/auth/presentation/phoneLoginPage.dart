import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/core/localization/appLanguage.dart';
import 'package:jetkiz_mobile/core/localization/appLocalizationScope.dart';
import 'package:jetkiz_mobile/features/auth/data/authApi.dart';
import 'package:jetkiz_mobile/features/auth/presentation/smsCodePage.dart';
import 'package:url_launcher/url_launcher.dart';

/// PhoneLoginPage
///
/// Контекст для будущих сессий ChatGPT:
/// - Это первый экран auth flow Jetkiz mobile.
/// - Он открывается внутри вкладки Profile через ProfileEntryPage,
///   если клиент ещё не авторизован.
/// - Этот экран НЕ должен становиться главным экраном всего приложения.
/// - Остальное приложение должно работать без регистрации.
/// - Этот экран не должен сам логинить пользователя и не должен сохранять token.
/// - Token должен сохраняться только после успешного подтверждения SMS-кода
///   на следующем экране SmsCodePage.
///
/// Подтверждённый backend contract:
/// - POST /auth/request-code
/// - body: { phone }
/// - response: { success, phone, expiresAt, resendAvailableAt }
///
/// Куда ставить API:
/// - API уже вынесен в lib/features/auth/data/authApi.dart
/// - UI здесь не работает с Dio напрямую
/// - используется только AuthApi + ApiClient
///
/// Auth flow: request-code -> SmsCodePage -> verify-code -> save token.
class PhoneLoginPage extends StatefulWidget {
  final VoidCallback? onAuthorized;

  const PhoneLoginPage({
    super.key,
    this.onAuthorized,
  });

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({
    required this.language,
    required this.onChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _item('RU', AppLanguage.ru),
          _item('ҚАЗ', AppLanguage.kk),
        ],
      ),
    );
  }

  Widget _item(String label, AppLanguage value) {
    final selected = language == value;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF489F2A) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: LocalizedText(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final TextEditingController _phoneController = TextEditingController();

  static final Uri _termsUri = Uri.parse('https://jetkiz.asia/offer');
  static final Uri _privacyUri = Uri.parse('https://jetkiz.asia/privacy');

  Future<void> _openLegalDocument(Uri uri) async {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  late final AuthApi _authApi;

  bool _isAgreementAccepted = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _authApi = AuthApi(ApiClient());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final digits = _extractDigits(_phoneController.text);
    return _isAgreementAccepted && digits.length == 10 && !_isSubmitting;
  }

  String _extractDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _onPhoneChanged(String value) {
    final digits = _extractDigits(value);
    final safe = digits.length > 10 ? digits.substring(0, 10) : digits;
    final formatted = _formatRuPhone(safe);

    if (formatted != value) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    setState(() {});
  }

  String _formatRuPhone(String digits) {
    if (digits.isEmpty) return '';

    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 3) buffer.write(') ');
      if (i == 6 || i == 8) buffer.write('-');
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final localDigits = _extractDigits(_phoneController.text);
    final normalizedPhone = '+7$localDigits';

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _authApi.requestSmsCode(
        phone: normalizedPhone,
      );

      if (!mounted) return;

      if (!response.success) {
        throw Exception('Backend returned success=false');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SmsCodePage(
            phone: normalizedPhone,
            resendAvailableAt: response.resendAvailableAt,
            onAuthorized: widget.onAuthorized,
          ),
        ),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(_requestCodeErrorMessage(error)),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(
            AppLocalizationScope.of(context).strings.loginCodeSendFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _requestCodeErrorMessage(AuthApiException error) {
    final strings = AppLocalizationScope.of(context).strings;
    switch (error.type) {
      case AuthApiErrorType.tooManyAttempts:
        return strings.loginTooManyAttempts;
      case AuthApiErrorType.noInternet:
        return error.userMessage;
      case AuthApiErrorType.invalidCode:
      case AuthApiErrorType.expiredCode:
      case AuthApiErrorType.serverError:
        return strings.loginCodeSendFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizationScope.of(context);
    final strings = localization.strings;
    const primaryGreen = Color(0xFF489F2A);
    const lightGreenBorder = Color(0xFF7DC963);
    const lightGray = Color(0xFFF2F2F2);
    const subtitleGray = Color(0xFF737373);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SvgPicture.asset(
                      'assets/images/Vector.svg',
                      height: 68,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                _LanguageSwitch(
                  language: localization.language,
                  onChanged: localization.onLanguageChanged,
                ),
              ],
            ),
            const SizedBox(height: 56),
            LocalizedText(
              strings.loginPhoneTitle,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: lightGreenBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const LocalizedText(
                    '+7',
                    style: TextStyle(
                      color: subtitleGray,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: lightGreenBorder.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: _onPhoneChanged,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        hintText: '(700) 000-00-00',
                        hintStyle: TextStyle(
                          color: Color(0xFF9A9A9A),
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAgreementAccepted = !_isAgreementAccepted;
                    });
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: _isAgreementAccepted ? primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: lightGreenBorder,
                        width: 1.4,
                      ),
                    ),
                    child: _isAgreementAccepted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LocalizedText.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: strings.loginConsentPrefix,
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => _openLegalDocument(_termsUri),
                            child: LocalizedText(
                              strings.loginTerms,
                              style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        TextSpan(text: strings.loginConsentMiddle),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => _openLegalDocument(_privacyUri),
                            child: LocalizedText(
                              strings.loginPrivacy,
                              style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        TextSpan(text: strings.loginConsentSuffix),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canSubmit ? primaryGreen : const Color(0xFFE5E5E5),
                  foregroundColor: _canSubmit ? Colors.white : Colors.black45,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : LocalizedText(
                        strings.loginSendCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
