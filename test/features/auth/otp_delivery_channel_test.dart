import 'package:flutter_test/flutter_test.dart';
import 'package:jetkiz_mobile/features/auth/data/authApi.dart';

void main() {
  test('OTP delivery channels use stable backend wire names', () {
    expect(OtpDeliveryChannel.auto.wireName, 'AUTO');
    expect(OtpDeliveryChannel.whatsapp.wireName, 'WHATSAPP');
    expect(OtpDeliveryChannel.sms.wireName, 'SMS');
  });

  test('request-code response reports the actual SMS provider channel', () {
    final response = RequestSmsCodeResponse.fromJson({
      'success': true,
      'phone': '+77001234567',
      'deliveryChannel': 'SMS',
      'deliveryProvider': 'kazinfoteh-sms',
    });

    expect(response.success, isTrue);
    expect(response.deliveryChannel, OtpDeliveryChannel.sms);
    expect(response.deliveryProvider, 'kazinfoteh-sms');
  });

  test('unknown delivery channel stays nullable instead of guessing', () {
    final response = RequestSmsCodeResponse.fromJson({
      'success': true,
      'phone': '+77001234567',
      'deliveryChannel': 'carrier-pigeon',
    });

    expect(response.deliveryChannel, isNull);
  });
}
