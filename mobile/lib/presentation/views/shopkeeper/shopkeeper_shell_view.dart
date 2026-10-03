import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/presentation/view_models/app_mode_view_model.dart';
import 'package:mobile/presentation/view_models/auth_view_model.dart';
import 'package:mobile/presentation/views/auth/merchant_auth_view.dart';
import 'package:mobile/presentation/views/shopkeeper/dashboard_view.dart';
import 'package:mobile/presentation/views/shopkeeper/sell_pos_view.dart';
import 'package:mobile/presentation/views/shopkeeper/inventory_view.dart';
import 'package:mobile/presentation/views/shopkeeper/customers_view.dart';
import 'package:mobile/presentation/views/customer/customer_portal_view.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/presentation/widgets/app_logo.dart';
import '../../view_models/notification_view_model.dart';
import 'package:mobile/data/services/notification_service.dart';

class ShopkeeperShellView extends StatefulWidget {
  const ShopkeeperShellView({super.key});

  @override
  State<ShopkeeperShellView> createState() => _ShopkeeperShellViewState();
}

class _ShopkeeperShellViewState extends State<ShopkeeperShellView> {
  int _currentIndex = 1; // Default to Sell POS for rapid transactions

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().registerToken();
    });
  }

  List<Widget> get _views => [
    DashboardView(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
    const SellPosView(),
    const InventoryView(),
    const CustomersView(),
  ];

  String _getTabSubtitle(int index, AppLocalizations? l10n) {
    switch (index) {
      case 0:
        return l10n?.dashboardSubtitle ?? 'Dashboard';
      case 1:
        return l10n?.posTerminalSubtitle ?? 'Pos Terminal';
      case 2:
        return l10n?.stockInventorySubtitle ?? 'Stock Inventory';
      case 3:
        return l10n?.khataLedgerSubtitle ?? 'Ledger';
      default:
        return l10n?.overviewSubtitle ?? 'Overview';
    }
  }

  void _showAuthModal(BuildContext context, AuthViewModel authVm) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.90,
          child: MerchantAuthView(
            viewModel: authVm,
            onAuthenticated: () {
              Navigator.of(ctx).pop();
            },
          ),
        ),
      ),
    );
  }

  void _showProfileModal(BuildContext context, AuthViewModel auth) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppConstants.surfaceOverlayDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.borderDark : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                    child: Text(
                      auth.currentUser?.name.isNotEmpty == true
                          ? auth.currentUser!.name.substring(0, 1).toUpperCase()
                          : 'D',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentStore?.name ?? 'FMCG+ Store',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppConstants.textPrimaryDark : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${auth.currentUser?.name ?? (l10n?.merchant ?? "Merchant")} • ${auth.currentUser?.phone ?? ""}',
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: AppConstants.textMutedDark,
                                )
                              : GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15)
                          : AppConstants.secondaryEmerald.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n?.active ?? 'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
              ListTile(
                leading: Icon(Icons.storefront_outlined, color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue),
                title: Text(
                  l10n?.storeProfile ?? 'Store Profile',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13, color: AppConstants.textPrimaryDark)
                      : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                subtitle: Text(
                  auth.currentStore?.address ?? 'Main Road, Dhaka',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 11, color: AppConstants.textMutedDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 11),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626)),
                title: Text(
                  l10n?.logout ?? 'Logout',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(color: AppConstants.alertCrimsonDark, fontWeight: FontWeight.w700, fontSize: 13)
                      : GoogleFonts.plusJakartaSans(color: const Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 13),
                ),
                subtitle: Text(
                  l10n?.signOutDeviceSubtitle ?? 'Sign out from this device',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 11, color: AppConstants.textMutedDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(ctx);
                  auth.logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, AppModeViewModel appMode, AuthViewModel auth) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppConstants.surfaceOverlayDark : Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.borderDark : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n?.moreOptionsAndSettings ?? 'More Options & Settings',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppConstants.textPrimaryDark : null,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15)
                        : AppConstants.secondaryEmerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_pin_rounded,
                    color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                  ),
                ),
                title: Text(
                  l10n?.customerKhataPortal ?? 'Customer Ledger Portal',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14, color: AppConstants.textPrimaryDark)
                      : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  l10n?.switchCustomerViewSubtitle ?? 'Switch to customer view & receipt passbook',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: isDark ? AppConstants.textMutedDark : null),
                onTap: () {
                  Navigator.pop(ctx);
                  appMode.setUserType(UserType.customer);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppConstants.primaryBlueDark.withValues(alpha: 0.15)
                        : AppConstants.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                  ),
                ),
                title: Text(
                  l10n?.language ?? 'Language',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14, color: AppConstants.textPrimaryDark)
                      : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  appMode.isBangla
                      ? (l10n?.currentLanguageSubtitleBn ?? 'বর্তমান: বাংলা (English করতে চাপুন)')
                      : (l10n?.currentLanguageSubtitleEn ?? 'Current: English (Tap for Bangla)'),
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppConstants.surfaceElevatedDark
                        : AppConstants.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    appMode.isBangla ? 'English' : 'বাংলা',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                    ),
                  ),
                ),
                onTap: () {
                  appMode.toggleLanguage();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppConstants.primaryBlueDark.withValues(alpha: 0.15)
                        : AppConstants.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    appMode.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                  ),
                ),
                title: Text(
                  l10n?.toggleTheme ?? 'Toggle Theme',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14, color: AppConstants.textPrimaryDark)
                      : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  appMode.themeMode == ThemeMode.dark
                      ? (l10n?.switchToLightMode ?? 'Switch to Light Mode')
                      : (l10n?.switchToDarkMode ?? 'Switch to Dark Mode'),
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                trailing: Switch(
                  value: appMode.themeMode == ThemeMode.dark,
                  activeColor: AppConstants.primaryBlueDark,
                  onChanged: (_) {
                    appMode.toggleTheme();
                    Navigator.pop(ctx);
                  },
                ),
              ),
              if (auth.isAuthenticated)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppConstants.alertCrimsonDark.withValues(alpha: 0.15)
                          : Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626),
                    ),
                  ),
                  title: Text(
                    l10n?.logout ?? 'Logout',
                    style: isDark
                        ? GoogleFonts.spaceGrotesk(color: AppConstants.alertCrimsonDark, fontWeight: FontWeight.w700, fontSize: 14)
                        : GoogleFonts.plusJakartaSans(color: const Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n?.signOutDeviceSubtitle ?? 'Sign out from this device',
                    style: isDark
                        ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                        : GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    auth.logout();
                  },
                )
              else
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppConstants.primaryBlueDark.withValues(alpha: 0.15)
                          : AppConstants.primaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.login_rounded,
                      color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                    ),
                  ),
                  title: Text(
                    l10n?.merchantLogin ?? 'Merchant Login',
                    style: isDark
                        ? GoogleFonts.spaceGrotesk(color: AppConstants.primaryBlueDark, fontWeight: FontWeight.w700, fontSize: 14)
                        : GoogleFonts.plusJakartaSans(color: AppConstants.primaryBlue, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n?.pinOrOtpVerification ?? 'PIN or OTP verification',
                    style: isDark
                        ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                        : GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAuthModal(context, auth);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appMode = context.watch<AppModeViewModel>();
    final auth = context.watch<AuthViewModel>();

    // Route guard: Non-merchants / Customers should never see the shopkeeper shell
    if (auth.isAuthenticated && auth.isCustomer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.read<AppModeViewModel>().userType != UserType.customer) {
          context.read<AppModeViewModel>().setUserType(UserType.customer);
        }
      });
      return const CustomerPortalView();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: isDark ? AppConstants.canvasDark : theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            // Dokan Logo Box (Stitch Spec)
            const AppLogo(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          auth.currentStore?.name.isNotEmpty == true
                              ? auth.currentStore!.name
                              : 'FMCG+ Store',
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: AppConstants.textPrimaryDark,
                                )
                              : GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n?.onlineSync ?? 'ONLINE SYNC',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppConstants.textMutedDark : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _getTabSubtitle(_currentIndex, l10n),
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.textMutedDark,
                                )
                              : GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher Badge / Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: InkWell(
              onTap: () => appMode.toggleLanguage(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppConstants.surfaceElevatedDark
                      : AppConstants.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppConstants.primaryBlueDark.withValues(alpha: 0.5)
                        : AppConstants.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 14,
                      color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appMode.isBangla ? 'বাং' : 'EN',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Notification Bell
          Badge(
            isLabelVisible: context.watch<NotificationViewModel>().hasUnread,
            label: Text('${context.watch<NotificationViewModel>().unreadGroceryCount}'),
            child: IconButton(
              tooltip: 'Notifications',
              icon: Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: isDark ? AppConstants.textPrimaryDark : null,
              ),
              onPressed: () {
                context.read<NotificationViewModel>().markAllRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n?.allEventsSynced ?? 'All cloud events synced and updated'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                // TODO: Navigate to grocery requests list
              },
            ),
          ),
          // User / Profile Button:
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: auth.isAuthenticated
                ? InkWell(
                    onTap: () => _showProfileModal(context, auth),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue).withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          auth.currentUser?.name.isNotEmpty == true
                              ? auth.currentUser!.name.substring(0, 1).toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                : InkWell(
                    onTap: () => _showAuthModal(context, auth),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppConstants.surfaceElevatedDark
                            : AppConstants.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppConstants.primaryBlueDark.withOpacity(0.5)
                              : AppConstants.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 14,
                            color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n?.login ?? 'Login',
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstants.primaryBlueDark,
                                  )
                                : GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstants.primaryBlue,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      // Custom Tactile Bottom Navigation Bar matching Stitch Design System
      bottomNavigationBar: _buildBottomNavBar(context, appMode, auth, l10n),
    );
  }

  Widget _buildBottomNavBar(
    BuildContext context,
    AppModeViewModel appMode,
    AuthViewModel auth,
    AppLocalizations? l10n,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      _NavItem(
        index: 0,
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
        label: l10n?.dashboard ?? 'Home',
      ),
      _NavItem(
        index: 1,
        activeIcon: Icons.point_of_sale_rounded,
        inactiveIcon: Icons.point_of_sale_outlined,
        label: l10n?.posRegister ?? 'Sell POS',
        badge: 'HOT',
      ),
      _NavItem(
        index: 2,
        activeIcon: Icons.inventory_2_rounded,
        inactiveIcon: Icons.inventory_2_outlined,
        label: l10n?.inventory ?? 'Stock',
      ),
      _NavItem(
        index: 3,
        activeIcon: Icons.menu_book_rounded,
        inactiveIcon: Icons.menu_book_outlined,
        label: l10n?.customers ?? 'Ledger',
      ),
      _NavItem(
        index: 4,
        activeIcon: Icons.tune_rounded,
        inactiveIcon: Icons.tune_outlined,
        label: l10n?.settings ?? 'More',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isSelected = _currentIndex == item.index;
              final color = isSelected
                  ? (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue)
                  : (isDark ? AppConstants.textMutedDark : const Color(0xFF64748B));

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (item.index == 4) {
                        _showMoreSheet(context, appMode, auth);
                      } else {
                        setState(() => _currentIndex = item.index);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.inactiveIcon,
                                size: 24,
                                color: color,
                              ),
                              if (item.badge != null)
                                Positioned(
                                  top: -4,
                                  right: -14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.badge!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: color,
                                    letterSpacing: 0.2,
                                  )
                                : GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: color,
                                    letterSpacing: 0.2,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final String? badge;

  const _NavItem({
    required this.index,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    this.badge,
  });
}

