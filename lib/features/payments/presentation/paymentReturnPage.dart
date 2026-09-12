import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentCheckoutApi.dart';
import 'package:jetkiz_mobile/features/payments/data/paymentPendingStore.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentReturnBridge.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentSuccessPage.dart';
import 'package:url_launcher/url_launcher.dart';

enum PaymentReturnResult {
  secured,
  failed,
  pending,
}

/// Hosted payment checkout shell.
///
/// Returning from the provider is never treated as proof of payment. This page
/// reports success only after the authenticated JETKIZ backend confirms a CARD
/// order in AUTHORIZED/PAID state with `fundsSecured=true`.
class PaymentReturnPage extends StatefulWidget {
  const PaymentReturnPage({
    super.key,
    required this.orderId,
    required this.checkoutUrl,
    this.openCheckoutOnStart = true,
  });

  final String orderId;
  final String checkoutUrl;
  final bool openCheckoutOnStart;

  @override
  State<PaymentReturnPage> createState() => _PaymentReturnPageState();
}

class _PaymentReturnPageState extends State<PaymentReturnPage>
    with WidgetsBindingObserver {
  static const Color _green = Color(0xFF489F2A);
  static const Duration _pollInterval = Duration(seconds: 2);
  static const Duration _maxForegroundWait = Duration(minutes: 3);
  static const Duration _cardSaveGrace = Duration(seconds: 8);

  late final PaymentCheckoutApi _payments;
  final PaymentPendingStore _pendingStore = PaymentPendingStore();

  Timer? _pollTimer;
  DateTime? _pollStartedAt;
  DateTime? _fundsSecuredAt;
  bool _isOpeningProvider = false;
  bool _isChecking = false;
  PaymentOrderState? _state;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    PaymentReturnSessionRegistry.hostedCheckoutActive = true;
    WidgetsBinding.instance.addObserver(this);
    _payments = PaymentCheckoutApi(ApiClient());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.openCheckoutOnStart) {
        _openProvider();
      }
      _startPolling(resetDeadline: true);
      _checkOnce();
    });
  }

  @override
  void dispose() {
    PaymentReturnSessionRegistry.hostedCheckoutActive = false;
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling(resetDeadline: false);
      _checkOnce();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Uri? get _secureCheckoutUri {
    final uri = Uri.tryParse(widget.checkoutUrl.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.trim().isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  Future<void> _openProvider() async {
    if (_isOpeningProvider) return;
    final uri = _secureCheckoutUri;
    if (uri == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Сервер вернул небезопасную ссылку оплаты';
      });
      return;
    }

    setState(() {
      _isOpeningProvider = true;
      _errorMessage = null;
    });

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        setState(() {
          _errorMessage = 'Не удалось открыть защищённую страницу оплаты';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Не удалось открыть защищённую страницу оплаты';
      });
    } finally {
      if (mounted) setState(() => _isOpeningProvider = false);
    }
  }

  void _startPolling({required bool resetDeadline}) {
    if (resetDeadline || _pollStartedAt == null) {
      _pollStartedAt = DateTime.now();
    }
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkOnce());
  }

  Future<void> _checkOnce() async {
    if (_isChecking || !mounted) return;

    final startedAt = _pollStartedAt;
    if (startedAt != null &&
        DateTime.now().difference(startedAt) > _maxForegroundWait) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final state = await _payments.getOrderPaymentState(widget.orderId);
      if (!mounted) return;
      setState(() => _state = state);

      if (state.isSecuredCardPayment) {
        _fundsSecuredAt ??= DateTime.now();

        // PayLink exposes a newly-created reusable token only in the callback.
        // Canonical invoice reconciliation can confirm the payment slightly
        // earlier, so keep polling briefly when card saving was requested.
        if (state.isCardSavePending &&
            DateTime.now().difference(_fundsSecuredAt!) < _cardSaveGrace) {
          return;
        }

        _pollTimer?.cancel();
        await _pendingStore.clear();
        if (!mounted) return;
        PaymentReturnSessionRegistry.hostedCheckoutActive = false;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(
              orderId: widget.orderId,
              cardSaveStatus: state.cardSaveRequested
                  ? state.normalizedCardSaveStatus
                  : null,
            ),
          ),
          (route) => false,
        );
        return;
      }

      if (state.isFailed || state.isTerminalWithoutSuccess) {
        _pollTimer?.cancel();
        await _pendingStore.clear();
      }
    } on PaymentCheckoutException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _backToOrder() {
    final state = _state;
    Navigator.of(context).pop(
      state != null && (state.isFailed || state.isTerminalWithoutSuccess)
          ? PaymentReturnResult.failed
          : PaymentReturnResult.pending,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = PaymentStrings.of(context);
    final state = _state;
    final failed =
        state != null && (state.isFailed || state.isTerminalWithoutSuccess);

    return PopScope(
      canPop: !_isOpeningProvider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            strings.paymentCheck,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: (failed ? const Color(0xFFD33A2C) : _green)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: failed
                      ? const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFD33A2C),
                          size: 40,
                        )
                      : _isChecking
                          ? const Padding(
                              padding: EdgeInsets.all(26),
                              child: CircularProgressIndicator(
                                color: _green,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(
                              Icons.shield_outlined,
                              color: _green,
                              size: 40,
                            ),
                ),
                const SizedBox(height: 22),
                Text(
                  failed ? strings.paymentFailed : strings.paymentStillPending,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F271E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  failed ? strings.paymentFailedHint : strings.paymentCheckHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Color(0xFF5F685D),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFFD33A2C),
                    ),
                  ),
                ],
                const Spacer(),
                if (!failed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isOpeningProvider ? null : _openProvider,
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: Text(
                        strings.openPayLink,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isChecking ? null : _checkOnce,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(strings.checkAgain),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _backToOrder,
                  child: Text(strings.backToOrder),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
