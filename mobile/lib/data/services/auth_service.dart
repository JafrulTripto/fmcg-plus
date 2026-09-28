import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/auth_model.dart';
import 'otp_provider.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _otpProvider = NishchitOtpDriver(backendBaseUrl: baseUrl);
  }

  String get baseUrl => AppConstants.effectiveApiBaseUrl;

  AuthSession? _currentSession;
  late OtpProvider _otpProvider;

  AuthSession? get currentSession => _currentSession;
  bool get isAuthenticated => _currentSession != null;
  UserModel? get currentUser => _currentSession?.user;
  StoreModel? get currentStore => _currentSession?.store;
  String? get accessToken => _currentSession?.accessToken;
  String? get storeId => _currentSession?.store?.id;
  OtpProvider get otpProvider => _otpProvider;

  void setOtpProvider(OtpProvider provider) {
    _otpProvider = provider;
    debugPrint('[AuthService] Switched OTP Provider to: ${provider.name}');
  }

  Map<String, String> get authHeaders {
    final headers = {'Content-Type': 'application/json'};
    if (accessToken != null && accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    if (storeId != null && storeId!.isNotEmpty) {
      headers['X-Store-ID'] = storeId!;
    }
    return headers;
  }

  // -------------------------------------------------------------------
  // Phone Lookup & OTP Management
  // -------------------------------------------------------------------

  Future<CheckPhoneResult> checkPhone(String phone) async {
    try {
      final cleanPhone = phone.trim();
      final res = await http.get(
        Uri.parse('$baseUrl/auth/check-phone?phone=${Uri.encodeComponent(cleanPhone)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return CheckPhoneResult.fromJson(data);
      }
      return CheckPhoneResult(
        registered: false,
        phone: cleanPhone,
        message: 'Could not check phone number',
      );
    } catch (e) {
      debugPrint('[AuthService] checkPhone error: $e');
      return CheckPhoneResult(
        registered: false,
        phone: phone,
        message: 'Connection error while checking phone',
      );
    }
  }

  Future<SendOtpResult> sendOtp(String phone, {String purpose = 'general'}) async {
    return _otpProvider.sendOtp(phone, purpose: purpose);
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    String? code,
    String? token,
  }) async {
    return _otpProvider.verifyOtp(phone: phone, code: code, token: token);
  }

  // -------------------------------------------------------------------
  // Merchant Onboarding & Registration
  // -------------------------------------------------------------------

  Future<AuthSession> registerMerchant({
    required String phone,
    required String name,
    required String storeName,
    required String storeAddress,
    required String pin,
    String? verificationToken,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register-merchant'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'name': name,
        'store_name': storeName,
        'store_address': storeAddress,
        'pin': pin,
        'verification_token': verificationToken,
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _currentSession = AuthSession.fromJson(data);
      return _currentSession!;
    }

    final errData = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(errData['error'] ?? 'Registration failed');
  }

  // -------------------------------------------------------------------
  // Customer Khata Registration
  // -------------------------------------------------------------------

  Future<AuthSession> registerCustomer({
    required String phone,
    required String name,
    required String pin,
    String? verificationToken,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register-customer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'name': name,
        'pin': pin,
        'verification_token': verificationToken,
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _currentSession = AuthSession.fromJson(data);
      return _currentSession!;
    }

    final errData = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(errData['error'] ?? 'Customer registration failed');
  }

  // -------------------------------------------------------------------
  // Authentication / Login
  // -------------------------------------------------------------------

  Future<AuthSession> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    final http.Response res;
    try {
      res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'pin': pin,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception('সার্ভারের সাথে সংযোগ স্থাপন করা সম্ভব হয়নি। ইন্টারনেট ও ব্যাকএন্ড সংযোগ চেক করুন।');
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _currentSession = AuthSession.fromJson(data);
      return _currentSession!;
    }

    try {
      final errData = jsonDecode(res.body) as Map<String, dynamic>;
      final err = errData['error'] ?? 'লগইন ব্যর্থ হয়েছে। ফোন ও পিন কোড চেক করুন।';
      throw Exception(err);
    } catch (e) {
      if (e is FormatException) {
        throw Exception('লগইন ব্যর্থ হয়েছে (${res.statusCode})');
      }
      rethrow;
    }
  }

  Future<AuthSession> loginWithOtp({
    required String phone,
    String? otpCode,
    String? firebaseToken,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'otp_code': otpCode,
        'firebase_token': firebaseToken,
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _currentSession = AuthSession.fromJson(data);
      return _currentSession!;
    }

    final errData = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(errData['error'] ?? 'OTP Login failed');
  }

  // -------------------------------------------------------------------
  // Refresh & Session Invalidation
  // -------------------------------------------------------------------

  Future<bool> refreshToken() async {
    if (_currentSession == null || _currentSession!.refreshToken.isEmpty) {
      return false;
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _currentSession!.refreshToken}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _currentSession = AuthSession.fromJson(data);
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Refresh token error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    if (_currentSession != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': _currentSession!.refreshToken}),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    _currentSession = null;
  }
}
