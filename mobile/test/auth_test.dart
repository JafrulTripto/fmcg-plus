import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/services/otp_provider.dart';
import 'package:mobile/presentation/view_models/auth_view_model.dart';

void main() {
  group('Pluggable OtpProvider Tests', () {
    test('MockOtpDriver sends and validates bypass code 123456', () async {
      final driver = MockOtpDriver();
      expect(driver.name, 'mock');

      final sendRes = await driver.sendOtp('01711223344');
      expect(sendRes.provider, 'mock');
      expect(sendRes.sessionId, isNotNull);

      // Successful verification
      final verifyRes = await driver.verifyOtp(phone: '01711223344', code: '123456');
      expect(verifyRes.verified, isTrue);
      expect(verifyRes.verificationToken, isNotEmpty);

      // Failed verification
      final failRes = await driver.verifyOtp(phone: '01711223344', code: '999999');
      expect(failRes.verified, isFalse);
    });

    test('FirebaseOtpDriver formats and handles mock firebase tokens', () async {
      final driver = FirebaseOtpDriver(backendBaseUrl: 'http://localhost:8080/api/v1');
      expect(driver.name, 'firebase');

      final sendRes = await driver.sendOtp('+8801711223344');
      expect(sendRes.provider, 'firebase');
    });

    test('AuthViewModel manages mode, steps, and provider switching', () {
      final vm = AuthViewModel();
      expect(vm.step, 0);
      expect(vm.mode, AuthMode.login);

      // Switch to register mode
      vm.setMode(AuthMode.register);
      expect(vm.mode, AuthMode.register);
      expect(vm.step, 0);

      // Set OTP driver
      vm.setOtpProvider(MockOtpDriver());
      expect(vm.activeOtpProviderName, 'mock');
    });
  });
}
