import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile/presentation/view_models/app_mode_view_model.dart';
import 'package:mobile/presentation/view_models/auth_view_model.dart';
import 'package:mobile/presentation/views/auth/otp_verification_view.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/presentation/widgets/app_logo.dart';

class MerchantAuthView extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final AuthViewModel? viewModel;

  const MerchantAuthView({
    super.key,
    required this.onAuthenticated,
    this.viewModel,
  });

  @override
  State<MerchantAuthView> createState() => _MerchantAuthViewState();
}

class _MerchantAuthViewState extends State<MerchantAuthView> {
  late final AuthViewModel _viewModel;

  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _newPinController = TextEditingController();

  bool _obscurePin = true;
  Timer? _phoneCheckTimer;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? AuthViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (_viewModel.mode != AuthMode.register) return;
    _phoneCheckTimer?.cancel();
    final phone = _phoneController.text.trim();
    if (phone.length >= 11) {
      _phoneCheckTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted && _viewModel.mode == AuthMode.register) {
          _viewModel.checkPhone(phone);
        }
      });
    } else if (_viewModel.isPhoneAlreadyRegistered) {
      _viewModel.checkPhone('');
    }
  }

  void _onViewModelChanged() {
    if (mounted) {
      if (_phoneController.text.isEmpty && _viewModel.phone.isNotEmpty) {
        _phoneController.text = _viewModel.phone;
      }
      setState(() {});
      if (_viewModel.isAuthenticated) {
        widget.onAuthenticated();
      }
    }
  }

  @override
  void dispose() {
    _phoneCheckTimer?.cancel();
    _phoneController.removeListener(_onPhoneChanged);
    _viewModel.removeListener(_onViewModelChanged);
    _phoneController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _newPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.step == 1) {
      return OtpVerificationView(
        phone: _viewModel.phone,
        isLoading: _viewModel.isLoading,
        errorMessage: _viewModel.errorMessage,
        successMessage: _viewModel.successMessage,
        detectedOtp: _viewModel.detectedOtp,
        onBack: () => _viewModel.setStep(0),
        onVerify: (otp) => _viewModel.verifyOtp(otp),
        onResend: () => _viewModel.sendOtp(_phoneController.text),
        onChangePhone: () => _viewModel.setStep(0),
      );
    }

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.canvasDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBrandHeader(),
                  const SizedBox(height: 20),

                  // Tactile Card Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppConstants.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black38 : const Color(0x0F0F172A),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error Banner
                        if (_viewModel.errorMessage != null) ...[
                          _buildErrorBanner(_viewModel.errorMessage!),
                          const SizedBox(height: 16),
                        ],

                        // Success Banner
                        if (_viewModel.successMessage != null && _viewModel.errorMessage == null) ...[
                          _buildSuccessBanner(_viewModel.successMessage!),
                          const SizedBox(height: 16),
                        ],

                        // Mode Selector (Login vs Register)
                        if (_viewModel.step == 0) ...[
                          _buildModeSelector(),
                          const SizedBox(height: 20),
                        ],

                        // Active Step Content
                        if (_viewModel.step == 0 && _viewModel.mode == AuthMode.login)
                          _buildLoginStep()
                        else if (_viewModel.step == 0 && _viewModel.mode == AuthMode.register)
                          _buildPhoneRegisterStep()
                        else if (_viewModel.step == 1)
                          _buildOtpVerificationStep()
                        else if (_viewModel.step == 2)
                          _buildStoreOnboardingStep(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {
                      context.read<AppModeViewModel>().setUserType(UserType.customer);
                    },
                    icon: Icon(Icons.people_alt_outlined, size: 16, color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B)),
                    label: Text(
                      l10n?.switchToCustomerPortal ?? 'Switch to Customer Portal',
                      style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    final appMode = context.watch<AppModeViewModel>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Language Toggle Pill
        Align(
          alignment: Alignment.topRight,
          child: InkWell(
            onTap: () => appMode.toggleLanguage(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceElevatedDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppConstants.borderDark : const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : const Color(0x0A000000),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language_rounded, size: 14, color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8)),
                  const SizedBox(width: 4),
                  Text(
                    appMode.isBangla ? 'English' : 'বাংলা',
                    style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const AppLogo(size: 64, showShadow: true),
        const SizedBox(height: 12),
        Text(
          'FMCG+',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n?.tagline ?? 'Retail POS & Digital Ledger',
          style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppConstants.textMutedDark : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppConstants.borderDark : const Color(0xFFCBD5E1), width: 1),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _viewModel.setMode(AuthMode.login),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _viewModel.mode == AuthMode.login
                      ? (isDark ? AppConstants.surfaceDark : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _viewModel.mode == AuthMode.login
                      ? [
                          BoxShadow(
                            color: isDark ? Colors.black26 : const Color(0x0D0F172A),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  l10n?.login ?? 'Login',
                  textAlign: TextAlign.center,
                  style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _viewModel.mode == AuthMode.login
                        ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8))
                        : (isDark ? AppConstants.textMutedDark : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _viewModel.setMode(AuthMode.register),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _viewModel.mode == AuthMode.register
                      ? (isDark ? AppConstants.surfaceDark : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _viewModel.mode == AuthMode.register
                      ? [
                          BoxShadow(
                            color: isDark ? Colors.black26 : const Color(0x0D0F172A),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  l10n?.registerStore ?? 'Register Store',
                  textAlign: TextAlign.center,
                  style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _viewModel.mode == AuthMode.register
                        ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8))
                        : (isDark ? AppConstants.textMutedDark : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 0: Login with Phone & PIN
  Widget _buildLoginStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _phoneController,
          label: l10n?.mobileNumber ?? 'Mobile Number',
          hint: '01711XXXXXX',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_android_rounded,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _pinController,
          label: l10n?.securityPin ?? 'Security PIN',
          hint: l10n?.pinHint ?? '4 or 6-digit PIN',
          obscureText: _obscurePin,
          isNumericCode: true,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8), size: 20),
            onPressed: () => setState(() => _obscurePin = !_obscurePin),
          ),
        ),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: l10n?.login ?? 'Login',
          icon: Icons.login_rounded,
          onPressed: _viewModel.isLoading
              ? null
              : () {
                  _viewModel.loginWithPin(
                    phone: _phoneController.text,
                    pin: _pinController.text,
                  );
                },
        ),
      ],
    );
  }

  // Step 0 (Register): Enter Phone to receive OTP
  Widget _buildPhoneRegisterStep() {
    final l10n = AppLocalizations.of(context);
    final isRegistered = _viewModel.isPhoneAlreadyRegistered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.enterPhoneToRegister ?? 'Enter your mobile number to register your store.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _phoneController,
          label: l10n?.merchantPhoneNumber ?? 'Merchant Phone Number',
          hint: '01711XXXXXX',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_android_rounded,
        ),
        if (isRegistered) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _viewModel.registeredStoreName != null && _viewModel.registeredStoreName!.isNotEmpty
                            ? 'এই নম্বরটি ইতিমধ্যে "${_viewModel.registeredStoreName}" নামে নিবন্ধিত রয়েছে।'
                            : (l10n?.numberAlreadyRegistered ?? 'This number is already registered. Please log in.'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _viewModel.switchToLoginWithPhone(_phoneController.text);
                    },
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: Text(
                      l10n?.goToLogin ?? 'Go to Login',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: isRegistered
              ? (l10n?.goToLogin ?? 'Go to Login')
              : (l10n?.sendOtp ?? 'Send OTP'),
          icon: isRegistered ? Icons.login_rounded : Icons.send_rounded,
          onPressed: _viewModel.isLoading
              ? null
              : () async {
                  if (isRegistered) {
                    _viewModel.switchToLoginWithPhone(_phoneController.text);
                    return;
                  }
                  final ok = await _viewModel.sendOtp(_phoneController.text);
                  if (ok && _viewModel.activeOtpProviderName == 'mock') {
                    _otpController.text = '123456';
                  }
                },
        ),
      ],
    );
  }

  // Step 1: Verify OTP
  Widget _buildOtpVerificationStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.verifyOtp ?? 'Verify OTP',
              style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
            TextButton(
              onPressed: () => _viewModel.setStep(0),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text(
                l10n?.changePhone ?? 'Change Phone',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1D4ED8)),
              ),
            ),
          ],
        ),
        Text(
          '${l10n?.codeSentTo ?? "Enter the code sent to"} ${_viewModel.phone}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        const SizedBox(height: 12),
        // Monospaced 6-digit Code input
        _buildTextField(
          controller: _otpController,
          label: l10n?.otpCode ?? '6-digit OTP Code',
          hint: '123456',
          isNumericCode: true,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.sms_outlined,
        ),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: l10n?.verify ?? 'Verify',
          icon: Icons.verified_user_outlined,
          onPressed: _viewModel.isLoading
              ? null
              : () {
                  _viewModel.verifyOtp(_otpController.text);
                },
        ),
      ],
    );
  }

  // Step 2: Merchant & Store Setup
  Widget _buildStoreOnboardingStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.storeDetailsAndPin ?? 'Store Details & Security PIN',
          style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _nameController,
          label: l10n?.ownerName ?? 'Owner Name',
          hint: l10n?.ownerNameHint ?? 'e.g. Rafiqul Islam',
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _storeNameController,
          label: l10n?.storeName ?? 'Store Name',
          hint: l10n?.storeNameHint ?? 'e.g. Rafiq General Store',
          prefixIcon: Icons.store_mall_directory_outlined,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _storeAddressController,
          label: l10n?.storeAddress ?? 'Store Address',
          hint: l10n?.storeAddressHint ?? 'e.g. Mirpur-10, Dhaka',
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _newPinController,
          label: l10n?.setPin ?? 'Set 4-Digit Security PIN',
          hint: '1234',
          isNumericCode: true,
          keyboardType: TextInputType.number,
          obscureText: _obscurePin,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: l10n?.launchStore ?? 'Launch Store',
          icon: Icons.rocket_launch_rounded,
          onPressed: _viewModel.isLoading
              ? null
              : () {
                  _viewModel.registerMerchant(
                    name: _nameController.text,
                    storeName: _storeNameController.text,
                    storeAddress: _storeAddressController.text,
                    pin: _newPinController.text,
                  );
                },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isNumericCode = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48, // DESIGN.md: 48px standard form input height
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: isNumericCode
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
                  )
                : (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
                  ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B), size: 18) : null,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: isDark ? AppConstants.surfaceElevatedDark : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), // DESIGN.md: 8px component radii
                borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFCBD5E1), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8), width: 2), // Active focus ring
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 52, // DESIGN.md: Minimum 52px height for primary mobile triggers
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Component Radii 8px
            side: isDark ? BorderSide.none : const BorderSide(color: Color(0xFF1E40AF), width: 1),
          ),
        ),
        child: _viewModel.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3B1219) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.5) : const Color(0xFFFECACA), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                fontSize: 12,
                color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF063321) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.5) : const Color(0xFFA7F3D0), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF059669), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                fontSize: 12,
                color: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF065F46),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
