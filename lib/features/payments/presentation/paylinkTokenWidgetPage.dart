import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/features/payments/presentation/paymentStrings.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Standalone UI for the token-based CTP widget flow.
///
/// It is deliberately not used for production invoice checkouts. A server
/// endpoint must first issue a payment token and reconcile its webhook/status.
class PaylinkTokenWidgetPage extends StatefulWidget {
  const PaylinkTokenWidgetPage({
    super.key,
    required this.paymentToken,
  });

  final String paymentToken;

  @override
  State<PaylinkTokenWidgetPage> createState() => _PaylinkTokenWidgetPageState();
}

class _PaylinkTokenWidgetPageState extends State<PaylinkTokenWidgetPage> {
  static const _green = Color(0xFF00B83F);
  WebViewController? _controller;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    final token = widget.paymentToken.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{24,256}$').hasMatch(token)) {
      _loadFailed = true;
      _loading = false;
      return;
    }

    final html = '''
<!doctype html>
<html lang="ru">
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>
  html,body { margin:0; background:#fff; min-height:100%; }
  #payment { min-height:480px; }
</style>
<script src="https://js.paylink.kz/widget/be_gateway.js"></script>
</head>
<body>
<div id="payment"></div>
<script>
window.addEventListener('load', function () {
  try {
    new BeGateway({
      checkout_url: 'https://checkout.paylink.kz',
      fromWebview: true,
      checkout: { iframe: true, transaction_type: 'payment' },
      token: ${jsonEncode(token)},
      closeWidget: function () { /* Confirmation always comes from server. */ }
    }).createWidget();
  } catch (_) {
    document.body.dataset.widgetError = '1';
  }
});
</script>
</body>
</html>
''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame != true || !mounted) return;
          setState(() {
            _loading = false;
            _loadFailed = true;
          });
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null || uri.scheme == 'http') {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    _controller = controller;
    controller.loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    final strings = PaymentStrings.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(strings.paymentCheck),
      ),
      body: SafeArea(
        child: _loadFailed
            ? Center(child: Text(strings.checkoutLoadError))
            : Column(
                children: [
                  if (_loading) const LinearProgressIndicator(color: _green),
                  Expanded(child: WebViewWidget(controller: _controller!)),
                ],
              ),
      ),
    );
  }
}
