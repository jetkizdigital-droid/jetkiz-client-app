import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/network/apiClient.dart';
import 'package:jetkiz_mobile/features/auth/data/authApi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const phone = String.fromEnvironment('E2E_CLIENT_PHONE');
  const otp = String.fromEnvironment('E2E_CLIENT_OTP');

  final result = await _runClientAuthSmoke(
    phone: phone.trim(),
    otp: otp.trim(),
  );

  runApp(_ClientAuthSmokeApp(result: result));
}

class _ClientAuthSmokeResult {
  const _ClientAuthSmokeResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

Future<_ClientAuthSmokeResult> _runClientAuthSmoke({
  required String phone,
  required String otp,
}) async {
  if (phone.isEmpty || otp.isEmpty) {
    const message = 'Missing E2E client review credentials';
    debugPrint('JETKIZ_CLIENT_E2E_AUTH_FAILED: $message');
    return const _ClientAuthSmokeResult(success: false, message: message);
  }

  final apiClient = ApiClient();
  await apiClient.init();
  final auth = AuthApi(apiClient);

  try {
    await apiClient.clearTokens();

    final requested = await auth.requestSmsCode(
      phone: phone,
      deliveryChannel: 'SMS',
    );

    if (!requested.success) {
      const message = 'Client OTP request did not report success';
      debugPrint('JETKIZ_CLIENT_E2E_AUTH_FAILED: $message');
      return const _ClientAuthSmokeResult(success: false, message: message);
    }

    final verified = await auth.verifySmsCode(phone: phone, code: otp);
    if (verified.accessToken.trim().isEmpty ||
        verified.refreshToken.trim().isEmpty) {
      const message = 'Client OTP verification returned empty auth tokens';
      debugPrint('JETKIZ_CLIENT_E2E_AUTH_FAILED: $message');
      return const _ClientAuthSmokeResult(success: false, message: message);
    }

    await apiClient.setTokens(
      accessToken: verified.accessToken,
      refreshToken: verified.refreshToken,
    );

    final response = await apiClient.dio.get('/auth/me');
    final payload = response.data;
    if (payload is! Map || payload.isEmpty) {
      const message = 'Client session verification returned empty payload';
      debugPrint('JETKIZ_CLIENT_E2E_AUTH_FAILED: $message');
      return const _ClientAuthSmokeResult(success: false, message: message);
    }

    const message =
        'Production client OTP login and session verification passed';
    debugPrint('JETKIZ_CLIENT_E2E_AUTH_OK');
    return const _ClientAuthSmokeResult(success: true, message: message);
  } catch (error, stackTrace) {
    final message = '${error.runtimeType}: $error';
    debugPrint('JETKIZ_CLIENT_E2E_AUTH_FAILED: $message');
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
    return _ClientAuthSmokeResult(success: false, message: message);
  } finally {
    await apiClient.clearTokens().catchError((_) {});
  }
}

class _ClientAuthSmokeApp extends StatelessWidget {
  const _ClientAuthSmokeApp({required this.result});

  final _ClientAuthSmokeResult result;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            result.success
                ? 'JETKIZ_CLIENT_E2E_AUTH_OK'
                : 'JETKIZ_CLIENT_E2E_AUTH_FAILED',
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
