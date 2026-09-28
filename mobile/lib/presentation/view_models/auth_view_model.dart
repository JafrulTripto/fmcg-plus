import 'package:flutter/foundation.dart';
import '../../data/models/auth_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/otp_provider.dart';

enum AuthMode { login, register }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  AuthMode _mode = AuthMode.login;
  int _step = 0; // 0: Phone / Login, 1: OTP Code verification, 2: Store Onboarding

  String _phone = '';
  String _verificationToken = '';
  bool _isPhoneAlreadyRegistered = false;
  String? _registeredStoreName;
  String? _registeredUserName;
  String? _detectedOtp;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  AuthMode get mode => _mode;
  int get step => _step;
  String get phone => _phone;
  bool get isAuthenticated => _authService.isAuthenticated;
  UserModel? get currentUser => _authService.currentUser;
  StoreModel? get currentStore => _authService.currentStore;
  String get activeOtpProviderName => _authService.otpProvider.name;
  bool get isPhoneAlreadyRegistered => _isPhoneAlreadyRegistered;
  String? get registeredStoreName => _registeredStoreName;
  String? get registeredUserName => _registeredUserName;
  String? get detectedOtp => _detectedOtp;

  void setMode(AuthMode mode) {
    _mode = mode;
    _step = 0;
    _errorMessage = null;
    _successMessage = null;
    _isPhoneAlreadyRegistered = false;
    _registeredStoreName = null;
    _registeredUserName = null;
    _detectedOtp = null;
    notifyListeners();
  }

  void setStep(int step) {
    _step = step;
    _errorMessage = null;
    notifyListeners();
  }

  void setOtpProvider(OtpProvider provider) {
    _authService.setOtpProvider(provider);
    notifyListeners();
  }

  void switchToLoginWithPhone(String phone) {
    _mode = AuthMode.login;
    _step = 0;
    _phone = phone.trim();
    _errorMessage = null;
    _isPhoneAlreadyRegistered = false;
    notifyListeners();
  }

  // Pre-check if phone is already registered
  Future<CheckPhoneResult> checkPhone(String inputPhone) async {
    final cleanPhone = inputPhone.trim();
    if (cleanPhone.isEmpty) {
      _isPhoneAlreadyRegistered = false;
      _registeredStoreName = null;
      _registeredUserName = null;
      notifyListeners();
      return const CheckPhoneResult(
        registered: false,
        phone: '',
        message: 'Phone is empty',
      );
    }

    try {
      final res = await _authService.checkPhone(cleanPhone);
      _isPhoneAlreadyRegistered = res.registered;
      _registeredStoreName = res.storeName;
      _registeredUserName = res.name;
      notifyListeners();
      return res;
    } catch (_) {
      return CheckPhoneResult(
        registered: false,
        phone: cleanPhone,
        message: 'Failed to check phone',
      );
    }
  }

  // 1. Send OTP for Registration or Verification
  Future<bool> sendOtp(String inputPhone) async {
    final cleanPhone = inputPhone.trim();
    if (cleanPhone.isEmpty) {
      _errorMessage = 'দয়া করে একটি বৈধ ফোন নম্বর লিখুন';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // If registering, check whether number is already registered BEFORE sending OTP
      if (_mode == AuthMode.register) {
        final check = await _authService.checkPhone(cleanPhone);
        if (check.registered) {
          _isLoading = false;
          _isPhoneAlreadyRegistered = true;
          _registeredStoreName = check.storeName;
          _registeredUserName = check.name;
          _phone = cleanPhone;
          final storeLabel = (check.storeName != null && check.storeName!.isNotEmpty)
              ? ' (${check.storeName})'
              : '';
          _errorMessage = 'এই নম্বরটি ইতিমধ্যে নিবন্ধিত রয়েছে$storeLabel। দয়া করে সরাসরি লগইন করুন।';
          notifyListeners();
          return false;
        }
      }

      final res = await _authService.sendOtp(
        cleanPhone,
        purpose: _mode == AuthMode.register ? 'register' : 'general',
      );

      if (res.isAlreadyRegistered) {
        _isLoading = false;
        _isPhoneAlreadyRegistered = true;
        _phone = cleanPhone;
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }

      _phone = cleanPhone;
      _isPhoneAlreadyRegistered = false;
      _isLoading = false;
      _step = 1; // Move to OTP verification view
      _successMessage = res.message;
      if (_authService.otpProvider.name == 'mock') {
        _detectedOtp = '491823'; // Matches Stitch design mock SMS detection code
      } else {
        _detectedOtp = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'OTP পাঠানো সম্ভব হয়নি: $e';
      notifyListeners();
      return false;
    }
  }

  // 2. Verify OTP Code
  Future<bool> verifyOtp(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.length < 4) {
      _errorMessage = 'দয়া করে সঠিক ভেরিফিকেশন কোড দিন';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authService.verifyOtp(phone: _phone, code: cleanCode);
      _isLoading = false;

      if (res.verified) {
        _verificationToken = res.verificationToken;
        _detectedOtp = null;
        if (_mode == AuthMode.register) {
          _step = 2; // Move to merchant store details entry
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'ভেরিফিকেশন ব্যর্থ হয়েছে: $e';
      notifyListeners();
      return false;
    }
  }

  // 3. Register Merchant
  Future<bool> registerMerchant({
    required String name,
    required String storeName,
    required String storeAddress,
    required String pin,
  }) async {
    if (name.trim().isEmpty || storeName.trim().isEmpty || pin.trim().length < 4) {
      _errorMessage = 'দয়া করে সব তথ্য এবং নূন্যতম ৪-সংখ্যার পিন দিন';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerMerchant(
        phone: _phone,
        name: name.trim(),
        storeName: storeName.trim(),
        storeAddress: storeAddress.trim(),
        pin: pin.trim(),
        verificationToken: _verificationToken,
      );
      _isLoading = false;
      _step = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // 4. Login with Phone & PIN
  Future<bool> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    final cleanPhone = phone.trim().replaceAll(' ', '').replaceAll('-', '');
    final cleanPin = pin.trim();

    if (cleanPhone.isEmpty || cleanPin.length < 4) {
      _errorMessage = 'সঠিক ফোন নম্বর এবং পিন কোড প্রদান করুন';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.loginWithPin(phone: cleanPhone, pin: cleanPin);
      _phone = cleanPhone;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // 5. Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _isLoading = false;
    _step = 0;
    _phone = '';
    _verificationToken = '';
    notifyListeners();
  }
}
