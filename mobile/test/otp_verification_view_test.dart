import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/presentation/views/auth/otp_verification_view.dart';
import 'package:mobile/presentation/widgets/app_logo.dart';

void main() {
  Widget createTestWidget({
    String phone = '01712345678',
    bool isLoading = false,
    String? errorMessage,
    String? successMessage,
    String? detectedOtp = '491823',
    VoidCallback? onBack,
    ValueChanged<String>? onVerify,
    Future<bool> Function()? onResend,
    VoidCallback? onChangePhone,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: OtpVerificationView(
          phone: phone,
          isLoading: isLoading,
          errorMessage: errorMessage,
          successMessage: successMessage,
          detectedOtp: detectedOtp,
          onBack: onBack ?? () {},
          onVerify: onVerify ?? (_) {},
          onResend: onResend,
          onChangePhone: onChangePhone,
        ),
      ),
    );
  }

  testWidgets('renders all key OTP screen elements from Stitch design including AppLogo', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget(detectedOtp: null));
    await tester.pump();

    // 1. Verify AppLogo & header branding
    expect(find.byType(AppLogo), findsWidgets);
    expect(find.text('Enter 6-Digit OTP'), findsOneWidget);
    expect(find.text('৬ ডিজিটের যাচাইকরণ কোড দিন'), findsOneWidget);
    expect(find.text('SECURE POS GATEWAY'), findsOneWidget);
    expect(find.text('Terminal Active'), findsOneWidget);

    // 2. Verify formatted phone & change number trigger
    expect(find.textContaining('1712-345678'), findsOneWidget);
    expect(find.text('Change Number'), findsOneWidget);

    // 3. Verify channels and action buttons
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Voice Call'), findsOneWidget);
    expect(find.text('Verify & Continue'), findsOneWidget);
    expect(find.textContaining('+880 9612-000000'), findsOneWidget);
  });

  testWidgets('tap to fill populates OTP and triggers onVerify', (tester) async {
    String? verifiedCode;
    await tester.pumpWidget(createTestWidget(
      detectedOtp: '491823',
      onVerify: (code) => verifiedCode = code,
    ));
    await tester.pump();

    // Verify SMS detection banner exists
    expect(find.text('SMS Detected'), findsOneWidget);
    expect(find.text('Tap to Fill'), findsOneWidget);

    // Tap "Tap to Fill"
    final tapToFillFinder = find.text('Tap to Fill');
    await tester.tap(tapToFillFinder);
    await tester.pump();

    expect(verifiedCode, equals('491823'));
  });

  testWidgets('direct text input updates OTP slots and submits', (tester) async {
    tester.view.physicalSize = const Size(420, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    String? verifiedCode;
    await tester.pumpWidget(createTestWidget(
      detectedOtp: null,
      onVerify: (code) => verifiedCode = code,
    ));
    await tester.pump();

    // Enter 6 digits via the underlying TextField
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    await tester.enterText(textFieldFinder, '582910');
    await tester.pump();

    // Tap Verify & Continue
    final verifyBtn = find.text('Verify & Continue');
    await tester.tap(verifyBtn);
    await tester.pump();

    expect(verifiedCode, equals('582910'));
  });
}
