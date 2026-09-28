import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // Currency
  static const String currencySymbol = '৳';

  // Base API configuration (Supports --dart-define=API_URL=... with smart defaults)
  static const String _configuredApiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  static const String _configuredAndroidApiUrl = String.fromEnvironment('ANDROID_API_URL', defaultValue: '');

  static String get defaultApiBaseUrl => effectiveApiBaseUrl;
  static String get androidEmulatorApiBaseUrl => _configuredAndroidApiUrl.isNotEmpty 
      ? _configuredAndroidApiUrl 
      : 'http://10.0.2.2:8080/api/v1';

  static String get effectiveApiBaseUrl {
    if (_configuredApiUrl.isNotEmpty) {
      return _configuredApiUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidEmulatorApiBaseUrl;
    }
    return 'http://localhost:8080/api/v1';
  }

  // App Name
  static const String appName = 'FMCG+';

  // Palette Tokens
  static const Color primaryBlue = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFEFF6FF);
  static const Color primaryDark = Color(0xFF1E40AF);

  static const Color secondaryEmerald = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFFD1FAE5);
  static const Color secondaryDark = Color(0xFF064E3B);
  static const Color successColor = secondaryEmerald;

  static const Color alertCrimson = Color(0xFFDC2626);
  static const Color alertLight = Color(0xFFFEE2E2);
  static const Color dangerColor = alertCrimson;

  static const Color dueAmber = Color(0xFFD97706);
  static const Color dueLight = Color(0xFFFEF3C7);

  // Light Palette Tokens
  static const Color canvasLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Palette Tokens (DESIGN-DARK.md: Tactical Slate Retail POS)
  static const Color canvasDark = Color(0xFF0B0F19); // Obsidian Slate Canvas
  static const Color canvasLowestDark = Color(0xFF0A0E18);
  static const Color surfaceDark = Color(0xFF111827); // Charcoal Card & Section Surface (Layer 1)
  static const Color surfaceContainerLowDark = Color(0xFF171B26);
  static const Color surfaceContainerDark = Color(0xFF1C1F2A);
  static const Color surfaceElevatedDark = Color(0xFF182234); // Elevated & Active Containers (Layer 2)
  static const Color surfaceOverlayDark = Color(0xFF1E293B); // Overlays, Drawers & Sheets (Layer 3)
  static const Color surfaceHighestDark = Color(0xFF313540);

  static const Color borderDark = Color(0xFF1E293B); // Structural hairline border
  static const Color borderInteractiveDark = Color(0xFF334155); // Interactive cards & inputs border
  static const Color outlineDark = Color(0xFF8C909F);
  static const Color outlineVariantDark = Color(0xFF424754);

  static const Color primaryBlueDark = Color(0xFF3B82F6); // Electric Blue
  static const Color primaryContainerDark = Color(0xFF4D8EFF);
  static const Color primaryTintDark = Color(0xFFADC6FF);

  static const Color secondaryEmeraldDark = Color(0xFF10B981); // Luminous Emerald
  static const Color secondaryEmeraldBright = Color(0xFF4EDEA3);
  static const Color secondaryContainerDark = Color(0xFF00A572);

  static const Color dueAmberDark = Color(0xFFF59E0B); // Bright Amber
  static const Color dueAmberBright = Color(0xFFFFB95F);
  static const Color dueContainerDark = Color(0xFFCA8100);

  static const Color alertCrimsonDark = Color(0xFFF43F5E); // Signal Rose
  static const Color alertCrimsonBright = Color(0xFFFFB4AB);
  static const Color alertContainerDark = Color(0xFF93000A);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // High-clarity white
  static const Color onSurfaceDark = Color(0xFFDFE2F1);
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Light Slate metadata
  static const Color onSurfaceVariantDark = Color(0xFFC2C6D6);
  static const Color textMutedDark = Color(0xFF64748B); // Muted Slate placeholders
}
