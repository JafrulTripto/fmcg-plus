import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/models/customer_model.dart';
import '../../view_models/app_mode_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/customer_view_model.dart';
import '../../view_models/pos_view_model.dart';
import '../../../l10n/app_localizations.dart';
import 'package:mobile/presentation/widgets/app_logo.dart';
import 'grocery_order_sheet.dart';
import 'customer_khata_sheet.dart';
import 'customer_ledger_view.dart';
import 'customer_orders_view.dart';
import '../../../data/services/notification_service.dart';

class CustomerPortalView extends StatefulWidget {
  const CustomerPortalView({super.key});

  @override
  State<CustomerPortalView> createState() => _CustomerPortalViewState();
}

class _CustomerPortalViewState extends State<CustomerPortalView> {
  // Navigation tab: 0: Home, 1: Khata, 2: Orders, 3: Profile
  int _currentIndex = 0;

  // null represents "All Stores" overview, or specific store ID
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerVm = context.read<CustomerViewModel>();
      final authVm = context.read<AuthViewModel>();
      final posVm = context.read<PosViewModel>();
      final phone = authVm.currentUser?.phone;

      if (phone != null && phone.isNotEmpty) {
        customerVm.loadCustomers(search: phone);
        customerVm.loadGroceryRequests(customerPhone: phone);
        posVm.loadRecentTransactions(phone: phone);
      } else {
        customerVm.loadCustomers();
        customerVm.loadGroceryRequests();
        posVm.loadRecentTransactions();
      }
      customerVm.loadStores();
      NotificationService().registerToken();
    });
  }

  // ---------------------------------------------------------------------------
  // MFS Settlement Dialog (Tactile & Branded)
  // ---------------------------------------------------------------------------
  void _showMfsPaymentDialog(BuildContext context, CustomerModel customer, {String? storeName}) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController(text: customer.currentBalance.toStringAsFixed(0));
    String selectedMfs = 'bKash';

    final Map<String, Color> mfsColors = {
      'bKash': const Color(0xFFE2136E),
      'Nagad': const Color(0xFFF7921E),
      'Rocket': const Color(0xFF8C3494),
    };

    final displayStoreName = storeName ??
        (customer.storeName.isNotEmpty
            ? customer.storeName
            : (l10n?.storeFallback ?? 'Store'));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final brandColor = mfsColors[selectedMfs] ?? const Color(0xFFE2136E);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: brandColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.account_balance_wallet_rounded, color: brandColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.settleBalanceViaMfs ?? 'Settle Store Balance',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayStoreName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n?.currentDueLabel ?? 'Current Due',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFF991B1B),
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(customer.currentBalance),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.selectMfsChannel ?? 'Select MFS Channel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: mfsColors.keys.map((mfs) {
                        final isSel = selectedMfs == mfs;
                        final col = mfsColors[mfs]!;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => setDialogState(() => selectedMfs = mfs),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? col.withValues(alpha: 0.15) : (isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? col : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      mfs,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isSel ? col : (isDark ? AppConstants.textPrimaryDark : const Color(0xFF334155)),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n?.mfsGateway ?? 'MFS',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: l10n?.paymentAmountLabel ?? 'Payment Amount (৳)',
                        prefixText: '৳ ',
                        filled: true,
                        fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              l10n?.cancel ?? 'Cancel',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final amount = double.tryParse(amountController.text.trim()) ?? 0;
                              if (amount <= 0) return;
                              Navigator.pop(ctx);
                              _handleKhataRepayment(context, customer, amount, selectedMfs, displayStoreName);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              '${l10n?.payViaMfs ?? "Pay via"} ($selectedMfs)',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleKhataRepayment(
    BuildContext context,
    CustomerModel customer,
    double amount,
    String mfs,
    String storeName,
  ) async {
    final customerVm = context.read<CustomerViewModel>();
    final authVm = context.read<AuthViewModel>();
    final appMode = context.read<AppModeViewModel>();
    final l10n = AppLocalizations.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFE2136E))),
              const SizedBox(height: 16),
              Text(
                l10n?.connectingToMfs ?? 'Connecting to $mfs Gateway...',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    nav.pop();

    await customerVm.recordPayment(
      customerId: customer.id,
      amount: amount,
      notes: 'MFS Repayment ($mfs) by customer to $storeName',
    );

    final phone = authVm.currentUser?.phone;
    if (phone != null && phone.isNotEmpty) {
      await customerVm.loadCustomers(search: phone);
    } else {
      await customerVm.loadCustomers();
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '৳${amount.toStringAsFixed(0)} - ${l10n?.fullyPaid ?? "Paid"} ($storeName)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grocery Order Bottom Sheet
  // ---------------------------------------------------------------------------
  void _showGroceryRequestDialog(
    BuildContext context, {
    CustomerModel? customer,
    String? defaultStoreId,
    List<StoreModel> ledgerStores = const [],
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GroceryOrderSheet(
        customer: customer,
        defaultStoreId: defaultStoreId ?? _selectedStoreId,
        stores: ledgerStores,
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // Build Main Screen
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appMode = context.watch<AppModeViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final customerVm = context.watch<CustomerViewModel>();
    final l10n = AppLocalizations.of(context);

    final userPhone = authVm.currentUser?.phone.trim() ?? '';
    final allCustomers = customerVm.customers;

    bool matchesPhone(String a, String b) {
      final cleanA = a.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanB = b.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanA.isEmpty || cleanB.isEmpty) return false;
      if (cleanA == cleanB) return true;
      if (cleanA.length >= 10 && cleanB.length >= 10) {
        return cleanA.substring(cleanA.length - 10) == cleanB.substring(cleanB.length - 10);
      }
      return false;
    }

    final myProfiles = allCustomers.where((c) =>
      matchesPhone(c.phone, userPhone) ||
      (authVm.currentUser?.name.isNotEmpty == true &&
          c.name.toLowerCase().trim() == authVm.currentUser!.name.toLowerCase().trim())
    ).toList();

    final Map<String, CustomerModel> profileByStoreId = {};
    for (final p in myProfiles) {
      if (p.storeId.isNotEmpty) {
        profileByStoreId[p.storeId] = p;
      }
    }

    final List<StoreModel> stores = [];
    for (final p in myProfiles) {
      if (p.storeId.isEmpty) continue;
      final matchedStore = customerVm.stores.where((s) => s.id == p.storeId).firstOrNull;
      if (matchedStore != null) {
        if (!stores.any((s) => s.id == matchedStore.id)) {
          stores.add(matchedStore);
        }
      } else {
        if (!stores.any((s) => s.id == p.storeId)) {
          stores.add(StoreModel(
            id: p.storeId,
            name: p.storeName.isNotEmpty ? p.storeName : (l10n?.myStore ?? AppConstants.defaultStoreName),
            ownerName: '',
            ownerPhone: '',
            address: p.storeAddress,
          ));
        }
      }
    }

    final totalCombinedDue = myProfiles.fold<double>(0.0, (sum, p) => sum + p.currentDue);
    final storesWithDueCount = myProfiles.where((p) => p.currentDue > 0).length;

    CustomerModel? currentProfile;
    StoreModel? currentStoreModel;

    if (_selectedStoreId != null) {
      currentProfile = profileByStoreId[_selectedStoreId];
      currentStoreModel = stores.where((s) => s.id == _selectedStoreId).firstOrNull;
    } else if (myProfiles.isNotEmpty) {
      currentProfile = myProfiles.first;
    }

    // Header title per tab
    String getTabTitle() {
      switch (_currentIndex) {
        case 0:
          return authVm.currentUser?.name.isNotEmpty == true
              ? authVm.currentUser!.name
              : (l10n?.customerDashboard ?? 'Customer Dashboard');
        case 1:
          return l10n?.khataLedger ?? 'Khata Ledger';
        case 2:
          return l10n?.myOrders ?? 'My Orders';
        case 3:
          return l10n?.customerProfile ?? 'Customer Profile';
        default:
          return 'FMCG+';
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppConstants.canvasDark : AppConstants.canvasLight,
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: isDark ? AppConstants.primaryBlueDark.withValues(alpha: 0.2) : const Color(0xFFEFF6FF),
              child: Text(
                authVm.currentUser?.name.isNotEmpty == true ? authVm.currentUser!.name[0].toUpperCase() : 'C',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          getTabTitle(),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                    ],
                  ),
                  Text(
                    userPhone.isNotEmpty ? userPhone : (l10n?.digitalKhataPassbook ?? 'Digital Khata Passbook'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher Badge
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: InkWell(
              onTap: () => appMode.toggleLanguage(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppConstants.primaryBlueDark.withValues(alpha: 0.4) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 13,
                      color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n?.localeName == 'bn' ? 'বাং' : 'EN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n?.toggleTheme ?? 'Toggle Theme',
            icon: Icon(
              appMode.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 19,
            ),
            onPressed: appMode.toggleTheme,
            visualDensity: VisualDensity.compact,
          ),
          if (authVm.isMerchant)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => appMode.setUserType(UserType.shopkeeper),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1D4ED8).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 16),
                      const SizedBox(width: 6),
                      Text(
                        l10n?.dokanPos ?? 'Dokan POS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (authVm.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: l10n?.logout ?? 'Logout',
                icon: const Icon(Icons.logout_rounded, size: 20),
                onPressed: () async {
                  await authVm.logout();
                  appMode.setUserType(UserType.shopkeeper);
                },
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: customerVm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await customerVm.loadCustomers();
                  await customerVm.loadStores();
                  await customerVm.loadGroceryRequests(customerPhone: userPhone);
                },
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    // Tab 0: Home (Dashboard & Stores Directory)
                    _buildHomeTab(
                      context: context,
                      stores: stores,
                      profileByStoreId: profileByStoreId,
                      totalCombinedDue: totalCombinedDue,
                      storesWithDueCount: storesWithDueCount,
                      currentProfile: currentProfile,
                      currentStoreModel: currentStoreModel,
                      userPhone: userPhone,
                      isDark: isDark,
                      appMode: appMode,
                      authVm: authVm,
                      l10n: l10n,
                    ),

                    // Tab 1: Khata Ledger (Separate Dedicated Page)
                    CustomerLedgerView(
                      key: ValueKey('khata_ledger_$_selectedStoreId'),
                      initialStoreId: _selectedStoreId,
                      showAppBar: false,
                      onStoreSelected: (storeId) {
                        setState(() => _selectedStoreId = storeId);
                      },
                    ),

                    // Tab 2: Orders & Requests (Separate Dedicated Page)
                    CustomerOrdersView(
                      key: ValueKey('orders_view_$_selectedStoreId'),
                      initialStoreId: _selectedStoreId,
                      showAppBar: false,
                    ),

                    // Tab 3: Customer Profile
                    _buildProfileTab(
                      context: context,
                      appMode: appMode,
                      authVm: authVm,
                      customerVm: customerVm,
                      totalDue: totalCombinedDue,
                      storesCount: stores.length,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
      ),
      // Persistent Tactile Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(
        context: context,
        appMode: appMode,
        totalDue: totalCombinedDue,
        pendingOrdersCount: customerVm.pendingGroceryRequestsCount,
        isDark: isDark,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 0: Home View
  // ---------------------------------------------------------------------------
  Widget _buildHomeTab({
    required BuildContext context,
    required List<StoreModel> stores,
    required Map<String, CustomerModel> profileByStoreId,
    required double totalCombinedDue,
    required int storesWithDueCount,
    required CustomerModel? currentProfile,
    required StoreModel? currentStoreModel,
    required String userPhone,
    required bool isDark,
    required AppModeViewModel appMode,
    required AuthViewModel authVm,
    required AppLocalizations? l10n,
  }) {
    final customerVm = context.watch<CustomerViewModel>();
    final activeOrders = customerVm.groceryRequests;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Selector Chips
          Text(
            l10n?.myConnectedStores ?? 'My Connected Stores',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStoreChip(
                  isSelected: _selectedStoreId == null,
                  label: l10n?.allStores ?? 'All Stores',
                  badgeText: '${stores.length}',
                  badgeColor: const Color(0xFF1D4ED8),
                  isDark: isDark,
                  onTap: () => setState(() => _selectedStoreId = null),
                ),
                const SizedBox(width: 8),
                ...stores.map((s) {
                  final storeProfile = profileByStoreId[s.id];
                  final due = storeProfile?.currentDue ?? 0.0;
                  final isSelected = _selectedStoreId == s.id;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStoreChip(
                      isSelected: isSelected,
                      label: s.name,
                      badgeText: due > 0 ? '৳${due.toStringAsFixed(0)}' : '✓ ৳০',
                      badgeColor: due > 0
                          ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                          : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                      isDark: isDark,
                      onTap: () => setState(() => _selectedStoreId = s.id),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hero Card: Multi-store or Single Store
          if (_selectedStoreId == null)
            _buildAllStoresAggregatedHero(
              context,
              totalDue: totalCombinedDue,
              storesCount: stores.length,
              debtorStoresCount: storesWithDueCount,
              isDark: isDark,
              appMode: appMode,
            )
          else
            _buildSingleStoreHero(
              context,
              profile: currentProfile!,
              store: currentStoreModel,
              isDark: isDark,
              appMode: appMode,
              l10n: l10n,
            ),
          const SizedBox(height: 18),

          // Bangladesh Quick Action Banner
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showGroceryRequestDialog(
                context,
                customer: currentProfile,
                defaultStoreId: _selectedStoreId,
                ledgerStores: stores,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF065F46).withValues(alpha: 0.6)
                        : const Color(0xFFA7F3D0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: isDark ? 0.05 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.post_add_rounded, color: Color(0xFF059669), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStoreId != null && currentStoreModel != null
                                ? '${currentStoreModel.name} • ${l10n?.sendOrder ?? "Send Order"}'
                                : (l10n?.requestGroceryFromStore ?? 'Request Grocery from Store'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n?.sendGroceryOrderSubtitle ?? 'Send item list for store pickup or delivery',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            l10n?.sendOrder ?? 'Order',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Active Grocery Orders Preview Snippet (if any)
          if (activeOrders.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF059669), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.activeGroceryOrder ?? 'Active Grocery Order',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 2),
                  child: Text(
                    '${l10n?.all ?? "All"} (${activeOrders.length}) →',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activeOrders.first.storeName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                        ),
                      ),
                      if (activeOrders.first.estimatedTotal > 0)
                        Text(
                          Formatters.formatCurrency(activeOrders.first.estimatedTotal),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeOrders.first.itemsText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // All Stores Directory
          if (_selectedStoreId == null && stores.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.storeDirectoryKhataSummary ?? 'Store Directory & Khata Summary',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                  ),
                ),
                Text(
                  '${stores.length} ${l10n?.storesConnectedSuffix ?? "stores"}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stores.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final store = stores[idx];
                final storeProfile = profileByStoreId[store.id] ??
                    CustomerModel(
                      id: '${authVm.currentUser?.id ?? ""}_${store.id}',
                      storeId: store.id,
                      storeName: store.name,
                      storeAddress: store.address ?? '',
                      name: authVm.currentUser?.name ?? '',
                      phone: userPhone,
                      currentDue: 0.0,
                    );

                return _buildStoreDirectoryCard(
                  context,
                  store: store,
                  profile: storeProfile,
                  isDark: isDark,
                  appMode: appMode,
                );
              },
            ),
          ] else if (_selectedStoreId == null && stores.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 48,
                    color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.noStoreAccountsLinked ?? 'No Store Accounts Linked',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n?.noStoreAccountsLinkedDesc ?? 'Connect with a storekeeper to view credit khata and order groceries.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Profile View
  // ---------------------------------------------------------------------------
  Widget _buildProfileTab({
    required BuildContext context,
    required AppModeViewModel appMode,
    required AuthViewModel authVm,
    required CustomerViewModel customerVm,
    required double totalDue,
    required int storesCount,
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context);
    final user = authVm.currentUser;
    final name = user?.name.isNotEmpty == true ? user!.name : (l10n?.valuedCustomer ?? 'Valued Customer');
    final phone = user?.phone ?? '';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppConstants.borderDark : AppConstants.borderLight),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF1D4ED8).withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF1D4ED8)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF059669)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: GoogleFonts.jetBrainsMono(fontSize: 13, color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n?.verifiedCustomerAccount ?? 'Verified Customer Account',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF059669)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overview Stats
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppConstants.borderDark : AppConstants.borderLight),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$storesCount',
                        style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1D4ED8)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.connectedStores ?? 'Connected Stores',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppConstants.borderDark : AppConstants.borderLight),
                  ),
                  child: Column(
                    children: [
                      Text(
                        Formatters.formatCurrency(totalDue),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: totalDue > 0 ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626)) : const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.totalDue ?? 'Total Due',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppConstants.borderDark : AppConstants.borderLight),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${customerVm.groceryRequests.length}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.groceryOrders ?? 'Grocery Orders',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Settings Section
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppConstants.borderDark : AppConstants.borderLight),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: Color(0xFF1D4ED8)),
                  title: Text(
                    l10n?.appLanguage ?? 'App Language',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n?.localeName == 'bn' ? (l10n?.bangla ?? 'বাংলা') : (l10n?.english ?? 'English'),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12, color: const Color(0xFF1D4ED8)),
                    ),
                  ),
                  onTap: () => appMode.toggleLanguage(),
                ),
                Divider(height: 1, color: isDark ? AppConstants.borderDark : AppConstants.borderLight),
                ListTile(
                  leading: Icon(
                    appMode.themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: const Color(0xFFD97706),
                  ),
                  title: Text(
                    l10n?.darkMode ?? 'Dark Mode',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  trailing: Switch(
                    value: appMode.themeMode == ThemeMode.dark,
                    onChanged: (_) => appMode.toggleTheme(),
                    activeThumbColor: const Color(0xFF1D4ED8),
                  ),
                ),
                if (authVm.isMerchant) ...[
                  Divider(height: 1, color: isDark ? AppConstants.borderDark : AppConstants.borderLight),
                  ListTile(
                    leading: const AppLogo(size: 20),
                    title: Text(
                      l10n?.switchToMerchantPos ?? 'Switch to Dokan POS',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1D4ED8)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => appMode.setUserType(UserType.shopkeeper),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n?.confirmLogoutTitle ?? 'Confirm Logout'),
                  content: Text(l10n?.confirmLogoutMessage ?? 'Are you sure you want to log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n?.cancel ?? 'Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                      child: Text(l10n?.logout ?? 'Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await authVm.logout();
                appMode.setUserType(UserType.shopkeeper);
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              l10n?.logout ?? 'Log Out',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Custom Tactile Bottom Navigation Bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavBar({
    required BuildContext context,
    required AppModeViewModel appMode,
    required double totalDue,
    required int pendingOrdersCount,
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context);
    final navItems = [
      _CustomerNavItem(
        index: 0,
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
        label: l10n?.homeTab ?? 'Home',
      ),
      _CustomerNavItem(
        index: 1,
        activeIcon: Icons.menu_book_rounded,
        inactiveIcon: Icons.menu_book_outlined,
        label: l10n?.khataTab ?? 'Khata',
        badge: totalDue > 0 ? (l10n?.dueBadge ?? 'DUE') : null,
        badgeColor: const Color(0xFFDC2626),
      ),
      _CustomerNavItem(
        index: 2,
        activeIcon: Icons.shopping_bag_rounded,
        inactiveIcon: Icons.shopping_bag_outlined,
        label: l10n?.ordersTab ?? 'Orders',
        badge: pendingOrdersCount > 0 ? '$pendingOrdersCount' : null,
        badgeColor: const Color(0xFF059669),
      ),
      _CustomerNavItem(
        index: 3,
        activeIcon: Icons.person_rounded,
        inactiveIcon: Icons.person_outlined,
        label: l10n?.profileTab ?? 'Profile',
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
            children: navItems.map((item) {
              final isSelected = _currentIndex == item.index;
              final color = isSelected
                  ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8))
                  : (isDark ? AppConstants.textMutedDark : const Color(0xFF64748B));

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = item.index),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: item.badgeColor ?? const Color(0xFFDC2626),
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: color,
                            ),
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

  // ---------------------------------------------------------------------------
  // Store Selector Chip
  // ---------------------------------------------------------------------------
  Widget _buildStoreChip({
    required bool isSelected,
    required String label,
    required String badgeText,
    required Color badgeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8))
              : (isDark ? AppConstants.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8))
                : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 14,
              color: isSelected ? Colors.white : (isDark ? AppConstants.textMutedDark : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Multi-Store Aggregated Hero Card
  // ---------------------------------------------------------------------------
  Widget _buildAllStoresAggregatedHero(
    BuildContext context, {
    required double totalDue,
    required int storesCount,
    required int debtorStoresCount,
    required bool isDark,
    required AppModeViewModel appMode,
  }) {
    final l10n = AppLocalizations.of(context);
    final hasDue = totalDue > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasDue
              ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5))
              : (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasDue ? const Color(0xFFDC2626) : const Color(0xFF059669)).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: hasDue
                          ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                          : const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasDue ? Icons.account_balance_wallet_rounded : Icons.check_circle_rounded,
                      color: hasDue ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.totalOutstandingAllStores ?? 'TOTAL OUTSTANDING (ALL STORES)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: hasDue
                          ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                          : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '$storesCount ${l10n?.storesConnectedSuffix ?? "Stores"}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.formatCurrency(totalDue),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasDue
                ? (l10n?.storesWithOutstandingDues ?? 'You have outstanding dues in connected stores.')
                : (l10n?.allAccountsSettled ?? 'All accounts settled. Zero due across all stores.'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: Text(
                    l10n?.viewLedger ?? 'View Ledger',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showGroceryRequestDialog(context),
                  icon: const Icon(Icons.post_add_rounded, size: 16),
                  label: Text(
                    l10n?.sendOrder ?? 'Send Order',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Single Store Dedicated Hero Card
  // ---------------------------------------------------------------------------
  Widget _buildSingleStoreHero(
    BuildContext context, {
    required CustomerModel profile,
    required StoreModel? store,
    required bool isDark,
    required AppModeViewModel appMode,
    required AppLocalizations? l10n,
  }) {
    final hasDue = profile.currentBalance > 0;
    final storeName = store?.name ?? profile.storeName;
    final storeAddress = store?.address ?? profile.storeAddress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasDue
              ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5))
              : (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasDue ? const Color(0xFFDC2626) : const Color(0xFF059669)).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF1D4ED8)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (storeAddress.isNotEmpty)
                            Text(
                              storeAddress,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _selectedStoreId = null),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close_rounded, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        l10n?.allStores ?? 'All Stores',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasDue
                ? (l10n?.currentOutstandingBalance ?? 'CURRENT OUTSTANDING BALANCE')
                : (l10n?.zeroBalanceSettled ?? 'ZERO BALANCE (SETTLED)'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: hasDue
                  ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                  : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatCurrency(profile.currentBalance),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${l10n?.creditLimitWithColon ?? "Credit Limit:"} ৳${profile.creditLimit.toStringAsFixed(0)}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${l10n?.availableCreditWithColon ?? "Available Credit:"} ৳${(profile.creditLimit - profile.currentBalance).clamp(0.0, double.infinity).toStringAsFixed(0)}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: Text(
                    l10n?.ledgerBook ?? 'Ledger Book',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF334155),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedStoreId = store?.id ?? profile.storeId;
                      _currentIndex = 1; // Switch to dedicated Khata tab!
                    });
                  },
                ),
              ),
              if (hasDue) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2136E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: Text(
                      l10n?.settleDue ?? 'Settle Due',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    onPressed: () => _showMfsPaymentDialog(
                      context,
                      profile,
                      storeName: storeName,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Store Directory Card
  // ---------------------------------------------------------------------------
  Widget _buildStoreDirectoryCard(
    BuildContext context, {
    required StoreModel store,
    required CustomerModel profile,
    required bool isDark,
    required AppModeViewModel appMode,
  }) {
    final l10n = AppLocalizations.of(context);
    final hasDue = profile.currentBalance > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasDue
              ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA))
              : (isDark ? AppConstants.borderDark : AppConstants.borderLight),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF1D4ED8), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (store.address != null && store.address!.isNotEmpty)
                      Text(
                        store.address!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(profile.currentBalance),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: hasDue
                          ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                          : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                    ),
                  ),
                  Text(
                    hasDue ? (l10n?.outstandingStatus ?? 'Outstanding') : (l10n?.settledStatus ?? 'Settled'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hasDue
                          ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                          : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStoreId = store.id;
                      _currentIndex = 1; // Direct jump to dedicated Khata tab!
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    l10n?.viewLedger ?? 'View Ledger',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showGroceryRequestDialog(context, customer: profile, defaultStoreId: store.id, ledgerStores: [store]),
                  icon: const Icon(Icons.post_add_rounded, size: 14),
                  label: Text(
                    l10n?.sendOrder ?? 'Send Order',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              if (hasDue) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showMfsPaymentDialog(context, profile, storeName: store.name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      l10n?.payDue ?? 'Pay',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer Nav Item Model
// ---------------------------------------------------------------------------
class _CustomerNavItem {
  final int index;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final String? badge;
  final Color? badgeColor;

  const _CustomerNavItem({
    required this.index,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    this.badge,
    this.badgeColor,
  });
}
