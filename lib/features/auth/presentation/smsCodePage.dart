import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/auth/data/authApi.dart';
import 'package:jetkiz_mobile/features/auth/data/authPostLoginService.dart';

class SmsCodePage extends StatefulWidget {
  final String phone;
  final DateTime? resendAvailableAt;
  final VoidCallback? onAuthorized;

  const SmsCodePage({
    super.key,
    required this.phone,
    this.resendAvailableAt,
    this.onAuthorized,
  });

  @override
  State<SmsCodePage> createState() => _SmsCodePageState();
}

class _SmsCodePageState extends State<SmsCodePage> {
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 60;

  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  final ApiClient _apiClient = ApiClient();

  late final AuthApi _authApi;
  late final AuthPostLoginService _postLoginService;

  bool _isSubmitting = false;
  bool _isResending = false;
  String? _errorText;

  Timer? _resendTimer;
  int _secondsLeft = _resendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    _authApi = AuthApi(_apiClient);
    _postLoginService = AuthPostLoginService(_apiClient);
    _startResendTimer(resendAvailableAt: widget.resendAvailableAt);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _codeFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  String get _digits => _extractDigits(_codeController.text);

  bool get _canSubmit => _digits.length == _otpLength && !_isSubmitting;

  bool get _canResend => _secondsLeft == 0 && !_isSubmitting && !_isResending;

  String _extractDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _startResendTimer({DateTime? resendAvailableAt}) {
    _resendTimer?.cancel();

    final now = DateTime.now();
    final secondsLeft =
        resendAvailableAt != null && resendAvailableAt.isAfter(now)
            ? resendAvailableAt.difference(now).inSeconds + 1
            : _resendCooldownSeconds;

    setState(() {
      _secondsLeft = secondsLeft;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
        });
        return;
      }

      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  String _formatPhone(String phone) {
    final digits = _extractDigits(phone);

    if (digits.length == 11 && digits.startsWith('7')) {
      return '+${digits[0]} ${digits.substring(1, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9, 11)}';
    }

    if (phone.startsWith('+')) return phone;
    return '+$phone';
  }

  String _formatSeconds(int value) {
    final seconds = value.toString().padLeft(2, '0');
    return '00:$seconds';
  }

  void _onCodeChanged(String value) {
    final digits = _extractDigits(value);
    final safe =
        digits.length > _otpLength ? digits.substring(0, _otpLength) : digits;

    if (safe != value) {
      _codeController.value = TextEditingValue(
        text: safe,
        selection: TextSelection.collapsed(offset: safe.length),
      );
    }

    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    } else {
      setState(() {});
    }

    if (safe.length == _otpLength && !_isSubmitting) {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final code = _digits;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final response = await _authApi.verifySmsCode(
        phone: widget.phone,
        code: code,
      );

      if (response.accessToken.isEmpty) {
        throw Exception('Backend returned empty accessToken');
      }

      if (response.refreshToken.isEmpty) {
        throw Exception('Backend returned empty refreshToken');
      }

      await _apiClient.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      await _postLoginService.syncAfterLogin();

      if (!mounted) return;

      widget.onAuthorized?.call();
      Navigator.of(context).pop();
    } on AuthApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorText = error.userMessage;
        _isSubmitting = false;
      });

      _codeController.clear();
      _codeFocusNode.requestFocus();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Сервис временно недоступен. Попробуйте позже.';
        _isSubmitting = false;
      });

      _codeController.clear();
      _codeFocusNode.requestFocus();
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
      _errorText = null;
    });

    try {
      final response = await _authApi.requestSmsCode(phone: widget.phone);

      if (!mounted) return;

      _codeController.clear();
      _startResendTimer(resendAvailableAt: response.resendAvailableAt);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Код отправлен повторно.'),
        ),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorText = _resendErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Не удалось отправить код. Попробуйте позже.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  String _resendErrorMessage(AuthApiException error) {
    switch (error.type) {
      case AuthApiErrorType.tooManyAttempts:
        return 'Слишком много запросов. Попробуйте позже.';
      case AuthApiErrorType.noInternet:
        return error.userMessage;
      case AuthApiErrorType.invalidCode:
      case AuthApiErrorType.expiredCode:
      case AuthApiErrorType.serverError:
        return 'Не удалось отправить код. Попробуйте позже.';
    }
  }

  Widget _buildCodeBox({
    required int index,
    required String digits,
  }) {
    final bool hasValue = digits.length > index;
    final bool isActive = digits.length == index && !_isSubmitting;
    final bool isFilled = digits.length > index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _codeFocusNode.requestFocus(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _errorText != null
                  ? const Color(0xFFE53935)
                  : isActive
                      ? const Color(0xFF489F2A)
                      : Colors.transparent,
              width: isActive || _errorText != null ? 2 : 1,
            ),
          ),
          child: Text(
            hasValue ? digits[index] : '',
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: isFilled ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedPhone = _formatPhone(widget.phone);
    final digits = _digits;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _codeFocusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const Center(
                                child: Text(
                                  'Подтверждение кода',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SvgPicture.asset(
                          'assets/images/Vector.svg',
                          height: 86,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 34),
                        const Text(
                          'Код был отправлен\nна ваш номер',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          formattedPhone,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 0,
                          height: 0,
                          child: Opacity(
                            opacity: 0,
                            child: TextField(
                              controller: _codeController,
                              focusNode: _codeFocusNode,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(_otpLength),
                              ],
                              onChanged: _onCodeChanged,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                color: Colors.transparent,
                                fontSize: 1,
                              ),
                              cursorColor: Colors.transparent,
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(_otpLength, (index) {
                            return [
                              if (index > 0) const SizedBox(width: 8),
                              _buildCodeBox(index: index, digits: digits),
                            ];
                          }).expand((widgets) => widgets).toList(),
                        ),
                        const SizedBox(height: 22),
                        if (_isSubmitting)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Color(0xFF489F2A),
                              ),
                            ),
                          )
                        else if (_errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _errorText!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (_canResend)
                          TextButton(
                            onPressed: _resendCode,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            child: _isResending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF489F2A),
                                    ),
                                  )
                                : const Text(
                                    'Отправить код повторно',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                          )
                        else
                          Text(
                            'запросить через ${_formatSeconds(_secondsLeft)}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
