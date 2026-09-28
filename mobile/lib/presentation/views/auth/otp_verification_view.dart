import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/presentation/widgets/app_logo.dart';

/// Stitch Design-faithful OTP Verification Screen for FMCG+ DokanPOS.
/// Matches Screen ID ca83477ca35f47f4af58c4159f00634c:
/// - Secure POS Gateway notice with live pulsing terminal indicator
/// - Hero icon & bilingual guidance
/// - Mobile recipient pill with edit trigger
/// - Smart quick SMS auto-fill card ("Tap to Fill")
/// - 6-slot OTP frame with active cursor pulse
/// - Live 42s resend countdown timer with WhatsApp & Voice Call fallback channels
/// - Tactile POS 3x4 thumb-friendly touch keypad with CLEAR, 0, and Backspace
/// - Primary transactional button: "Verify & Continue"
/// - FMCG+ Support desk hotline link
class OtpVerificationView extends StatefulWidget {
  final String phone;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String? detectedOtp;
  final VoidCallback onBack;
  final ValueChanged<String> onVerify;
  final Future<bool> Function()? onResend;
  final VoidCallback? onChangePhone;

  const OtpVerificationView({
    super.key,
    required this.phone,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.detectedOtp,
    required this.onBack,
    required this.onVerify,
    this.onResend,
    this.onChangePhone,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView>
    with SingleTickerProviderStateMixin {
  static const int maxDigits = 6;
  final List<String> _currentOtp = [];
  late final TextEditingController _otpInputController;
  late final FocusNode _otpFocusNode;

  bool _autofillDismissed = false;
  int _secondsLeft = 42;
  Timer? _countdownTimer;
  late final AnimationController _pulseController;
  late final Animation<double> _cursorOpacity;

  @override
  void initState() {
    super.initState();
    _otpInputController = TextEditingController();
    _otpFocusNode = FocusNode();

    if (widget.detectedOtp != null && widget.detectedOtp!.isNotEmpty) {
      final initialDigits = widget.detectedOtp!
          .replaceAll(RegExp(r'\D'), '')
          .split('')
          .take(maxDigits)
          .toList();
      _otpInputController.text = initialDigits.join();
      _currentOtp.addAll(initialDigits);
    }

    // Automatically open the device's native number pad on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });

    _startCountdown();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _cursorOpacity = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(OtpVerificationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When incoming SMS arrives with an OTP, automatically fill and verify
    if (widget.detectedOtp != null &&
        widget.detectedOtp!.isNotEmpty &&
        widget.detectedOtp != oldWidget.detectedOtp) {
      _onTapToFill(widget.detectedOtp!);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsLeft = 42;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
        });
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _otpInputController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _onTapToFill(String code) {
    HapticFeedback.mediumImpact();
    final digits = code
        .trim()
        .replaceAll(RegExp(r'\D'), '')
        .split('')
        .take(maxDigits)
        .toList();
    final joined = digits.join();
    _otpInputController.text = joined;
    _otpInputController.selection = TextSelection.fromPosition(TextPosition(offset: joined.length));
    setState(() {
      _currentOtp.clear();
      _currentOtp.addAll(digits);
      _autofillDismissed = true;
    });
    if (_currentOtp.length == maxDigits) {
      widget.onVerify(_currentOtp.join());
    }
  }

  String _formatPhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 11) {
      final last10 = cleaned.substring(cleaned.length - 10);
      final p1 = last10.substring(0, 4);
      final p2 = last10.substring(4);
      return '+880 $p1-$p2';
    }
    return raw.isNotEmpty ? raw : '+880 1712-345678';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedPhone = _formatPhone(widget.phone);
    final displayedOtpDetected = widget.detectedOtp ?? '491823';

    return Scaffold(
      backgroundColor: isDark ? AppConstants.canvasDark : const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(context, l10n, isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Security Notice Tag
                        _buildSecurityNoticeTag(l10n, isDark),
                        const SizedBox(height: 12),

                        // Error Banner if present
                        if (widget.errorMessage != null) ...[
                          _buildNoticeBanner(
                            icon: Icons.error_outline_rounded,
                            bgColor: isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.15) : const Color(0xFFFEF2F2),
                            borderColor: isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.3) : const Color(0xFFFECACA),
                            textColor: isDark ? AppConstants.alertCrimsonBright : const Color(0xFF991B1B),
                            text: widget.errorMessage!,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Success / Info Banner if present
                        if (widget.successMessage != null && widget.errorMessage == null) ...[
                          _buildNoticeBanner(
                            icon: Icons.check_circle_outline_rounded,
                            bgColor: isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15) : const Color(0xFFECFDF5),
                            borderColor: isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.3) : const Color(0xFFA7F3D0),
                            textColor: isDark ? AppConstants.secondaryEmeraldBright : const Color(0xFF065F46),
                            text: widget.successMessage!,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Hero & Context Visual Section
                        _buildHeroSection(formattedPhone, l10n, isDark),
                        const SizedBox(height: 16),

                        // Smart Quick Auto-fill Notification / Detected SMS Pill
                        if (!_autofillDismissed && displayedOtpDetected.isNotEmpty) ...[
                          _buildAutofillCard(displayedOtpDetected, l10n, isDark),
                          const SizedBox(height: 16),
                        ],

                        // 6-Slot OTP Display Frame
                        _buildOtpSlotsFrame(isDark),
                        const SizedBox(height: 16),

                        // Resend Countdown and Alternative Verification Hub
                        _buildResendAndChannelsHub(l10n, isDark),
                        const SizedBox(height: 24),

                        // Primary Transactional Action Bar
                        _buildVerifyButton(l10n, isDark),
                        const SizedBox(height: 16),

                        // Retail Support & Trouble Link
                        _buildSupportDeskLink(l10n, isDark),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Top App Bar
  Widget _buildTopAppBar(BuildContext context, AppLocalizations? l10n, bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.canvasDark : const Color(0xFFFAF8FF),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E), size: 24),
            onPressed: widget.onBack,
            tooltip: 'Go Back',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.otpVerificationTitle ?? 'OTP Verification',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
                    height: 1.2,
                  ),
                ),
                Text(
                  'FMCG+ DokanPOS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFEAEDFF),
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: AppConstants.borderInteractiveDark, width: 1) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 16),
                const SizedBox(width: 6),
                Text(
                  'DokanPOS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Security Notice Tag
  Widget _buildSecurityNoticeTag(AppLocalizations? l10n, bool isDark) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFEAEDFF),
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: AppConstants.borderInteractiveDark, width: 1) : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_rounded, color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0), size: 15),
              const SizedBox(width: 6),
              Text(
                l10n?.securePosGateway ?? 'SECURE POS GATEWAY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15) : const Color(0xFF82F5C1).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: AppConstants.secondaryEmeraldDark.withValues(alpha: 0.3), width: 1) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.secondaryEmeraldBright : const Color(0xFF006C4A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                l10n?.terminalActive ?? 'Terminal Active',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppConstants.secondaryEmeraldBright : const Color(0xFF006C4A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Hero & Context Visual Section
  Widget _buildHeroSection(String formattedPhone, AppLocalizations? l10n, bool isDark) {
    return Column(
      children: [
        // Brand Illustration Stack with SMS Badge
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppConstants.surfaceElevatedDark, AppConstants.surfaceDark]
                        : const [Color(0xFFE2E7FF), Color(0xFFEAEDFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: isDark ? Border.all(color: AppConstants.borderInteractiveDark, width: 1) : null,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.security_rounded,
                    color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8).withValues(alpha: 0.85),
                    size: 38,
                  ),
                ),
              ),
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.sms_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Screen Title & Bilingual Guidance
        Text(
          l10n?.enter6DigitOtp ?? 'Enter 6-Digit OTP',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n?.enter6DigitOtpBn ?? '৬ ডিজিটের যাচাইকরণ কোড দিন',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655),
          ),
        ),
        const SizedBox(height: 8),

        // Target Recipient Pill with Edit Trigger
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF2F3FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppConstants.borderInteractiveDark : const Color(0xFFE2E7FF),
              width: 1,
            ),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                formattedPhone,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
                ),
              ),
              Text('•', style: TextStyle(color: isDark ? AppConstants.textMutedDark : const Color(0xFFC4C5D7), fontSize: 13)),
              InkWell(
                onTap: widget.onChangePhone ?? widget.onBack,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        l10n?.changeNumber ?? 'নম্বর পরিবর্তন',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Smart Quick Auto-fill Notification / Detected SMS Pill
  Widget _buildAutofillCard(String detectedCode, AppLocalizations? l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceElevatedDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppConstants.borderInteractiveDark : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.2)
                  : const Color(0xFF82F5C1).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                Icons.mark_chat_unread_rounded,
                color: isDark ? AppConstants.secondaryEmeraldBright : const Color(0xFF006C4A),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.2)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n?.smsDetected ?? 'SMS DETECTED',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? AppConstants.secondaryEmeraldBright : const Color(0xFF006C4A),
                        ),
                      ),
                    ),
                    Text(
                      detectedCode,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.fmcgSecurityVerificationCode ?? 'FMCG+ Security verification code',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _onTapToFill(detectedCode),
            icon: const Icon(Icons.touch_app_rounded, size: 15),
            label: Text(
              l10n?.tapToFill ?? 'Tap to Fill',
              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // 5. 6-Slot OTP Display Frame with Native Keyboard & SMS Autofill Integration
  Widget _buildOtpSlotsFrame(bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _otpFocusNode.requestFocus();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Underlying transparent TextField that captures system keyboard and SMS autofill
          Positioned.fill(
            child: Opacity(
              opacity: 0.0,
              child: AutofillGroup(
                child: TextField(
                  controller: _otpInputController,
                  focusNode: _otpFocusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  textInputAction: TextInputAction.done,
                  enableSuggestions: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(maxDigits),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _currentOtp.clear();
                      _currentOtp.addAll(val.split(''));
                    });
                    if (val.length == maxDigits) {
                      widget.onVerify(val);
                    }
                  },
                  onSubmitted: (val) {
                    if (val.length == maxDigits) {
                      widget.onVerify(val);
                    }
                  },
                ),
              ),
            ),
          ),
          // Styled 6-slot visual display
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(maxDigits, (index) {
                final isFilled = index < _currentOtp.length;
                final isActive = index == _currentOtp.length;
                final char = isFilled ? _currentOtp[index] : '';

                return Expanded(
                  child: Container(
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFE2E7FF))
                          : (isDark ? AppConstants.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0))
                            : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x080F172A),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isFilled
                          ? Text(
                              char,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
                              ),
                            )
                          : isActive
                              ? FadeTransition(
                                  opacity: _cursorOpacity,
                                  child: Container(
                                    width: 2.5,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                )
                              : Text(
                                  '•',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppConstants.textMutedDark
                                        : const Color(0xFF747686).withValues(alpha: 0.35),
                                  ),
                                ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Resend Countdown and Alternative Verification Hub
  Widget _buildResendAndChannelsHub(AppLocalizations? l10n, bool isDark) {
    return Column(
      children: [
        // Countdown row
        if (_secondsLeft > 0)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 2,
            children: [
              Icon(Icons.history_rounded, size: 16, color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655)),
              Text(
                '${l10n?.resendCodeIn ?? "Resend code in"} ',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655)),
              ),
              Text(
                '00:${_secondsLeft.toString().padLeft(2, '0')}s',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                ),
              ),
              Text(
                '(${l10n?.pleaseWait ?? "অপেক্ষা করুন"})',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: (isDark ? AppConstants.textMutedDark : const Color(0xFF434655)).withValues(alpha: 0.7),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: () async {
              HapticFeedback.mediumImpact();
              if (widget.onResend != null) {
                final ok = await widget.onResend!();
                if (ok) _startCountdown();
              } else {
                _startCountdown();
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 16, color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0)),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n?.resendCodeNow ?? "Resend Code Now"} (${l10n?.resendCodeNowBn ?? "আবার পাঠান"})',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 10),

        // Alternative verification channels bar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAlternativeChannelBtn(
              icon: Icons.chat_rounded,
              iconColor: isDark ? AppConstants.secondaryEmeraldBright : const Color(0xFF006C4A),
              label: l10n?.whatsApp ?? 'WhatsApp',
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('WhatsApp ওটিপি যাচাইকরণ শুরু হচ্ছে...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            _buildAlternativeChannelBtn(
              icon: Icons.phone_in_talk_rounded,
              iconColor: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
              label: l10n?.voiceCall ?? 'Voice Call',
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ভয়েস কল ওটিপি কল শুরু হচ্ছে...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlternativeChannelBtn({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFEAEDFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppConstants.borderInteractiveDark : const Color(0xFFDAE2FD),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF434655),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  // 8. Primary Transactional Action Bar
  Widget _buildVerifyButton(AppLocalizations? l10n, bool isDark) {
    final isReady = _currentOtp.length == maxDigits;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: widget.isLoading
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    widget.onVerify(_currentOtp.join());
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isReady
                  ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0))
                  : (isDark
                      ? AppConstants.primaryBlueDark.withValues(alpha: 0.7)
                      : const Color(0xFF0037B0).withValues(alpha: 0.85)),
              foregroundColor: Colors.white,
              elevation: isDark ? 0 : 2,
              shadowColor: const Color(0x330037B0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n?.verifyAndContinue ?? 'Verify & Continue',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.verifyAndContinueSub ?? 'যাচাই করুন ও এগিয়ে যান',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655),
          ),
        ),
      ],
    );
  }

  // 9. Retail Support & Trouble Link
  Widget _buildSupportDeskLink(AppLocalizations? l10n, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 2,
          children: [
            Icon(Icons.support_agent_rounded, size: 16, color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686)),
            Text(
              '${l10n?.needHelpFmcgDesk ?? "Need help? FMCG+ Desk"}: ',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655),
              ),
            ),
            Text(
              '+880 9612-000000',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeBanner({
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
