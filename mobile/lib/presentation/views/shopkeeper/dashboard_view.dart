import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../view_models/pos_view_model.dart';
import '../../view_models/inventory_view_model.dart';
import '../../view_models/customer_view_model.dart';
import '../../view_models/app_mode_view_model.dart';
import '../../../l10n/app_localizations.dart';
import 'barcode_scanner_view.dart';
import 'add_product_sheet.dart';
import 'receipt_view.dart';

class DashboardView extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardView({super.key, required this.onNavigateTab});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String _selectedPeriod = 'today'; // 'today', 'yesterday', 'week'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerViewModel>().loadCustomers();
      context.read<InventoryViewModel>().loadProducts();
      context.read<PosViewModel>().loadRecentTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerVm = context.watch<CustomerViewModel>();
    final inventoryVm = context.watch<InventoryViewModel>();
    final posVm = context.watch<PosViewModel>();
    final appMode = context.watch<AppModeViewModel>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final todayGrossSales = posVm.recentTransactions.fold(0.0, (sum, t) => sum + t.total);
    final todayOrderCount = posVm.recentTransactions.length;
    final lowStockCount = inventoryVm.products.where((p) => p.isLowStock || p.isOutOfStock).length;
    final estProfit = todayGrossSales * 0.196;

    return RefreshIndicator(
      onRefresh: () async {
        await customerVm.loadCustomers();
        await inventoryVm.loadProducts();
        await posVm.loadRecentTransactions();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Time Horizon & Live Sync Strip (Stitch Spec: 6_Shopkeeper_Dashboard_a301af12)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfaceDark : const Color(0xFFE2E8FF),
                    borderRadius: BorderRadius.circular(24),
                    border: isDark ? Border.all(color: AppConstants.borderDark) : null,
                  ),
                  child: Row(
                    children: [
                      _buildPeriodBtn('Today', 'today', isDark),
                      _buildPeriodBtn('Yesterday', 'yesterday', isDark),
                      _buildPeriodBtn('This Week', 'week', isDark),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfaceDark : const Color(0xFFEAEDFF),
                    borderRadius: BorderRadius.circular(20),
                    border: isDark ? Border.all(color: AppConstants.borderDark) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Synced 2m ago',
                        style: isDark
                            ? GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.textSecondaryDark,
                              )
                            : GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF434655),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Financial KPI Metrics Hero Bento (Stitch Spec)
            // 1. Gross Daily Sales (Span 2 Gradient Card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF1E3A8A), Color(0xFF1D4ED8)]
                      : const [Color(0xFF0037B0), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.35)) : null,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x241D4ED8),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GROSS DAILY SALES',
                        style: isDark
                            ? GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: const Color(0xFFCAD3FF),
                              )
                            : GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: const Color(0xFFCAD3FF),
                              ),
                      ),
                      if (todayGrossSales > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF4EDEA3) : const Color(0xFF82F5C1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up, size: 13, color: Color(0xFF005137)),
                              const SizedBox(width: 2),
                              Text(
                                'Active',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF005137),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.formatCurrency(todayGrossSales),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white70),
                          const SizedBox(width: 5),
                          Text(
                            '$todayOrderCount completed orders',
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                      Text(
                        todayGrossSales > 0 ? 'Live Total' : 'No sales today',
                        style: isDark
                            ? GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                color: Colors.white70,
                              )
                            : GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 2 & 3: Khata Dues & Est. Profit (2-Column Bento Row)
            Row(
              children: [
                // Khata / Customer Dues (Baaki)
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onNavigateTab(3), // Navigate to Khata tab
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppConstants.alertCrimsonDark.withValues(alpha: 0.12)
                            : const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppConstants.alertCrimsonDark.withValues(alpha: 0.35)
                              : const Color(0xFFDC2626).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n?.totalKhataCredit ?? 'LEDGER DUES',
                                style: isDark
                                    ? GoogleFonts.spaceGrotesk(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppConstants.alertCrimsonDark,
                                        letterSpacing: 0.5,
                                      )
                                    : GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF93000A),
                                        letterSpacing: 0.5,
                                      ),
                              ),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: customerVm.totalKhataDues > 0
                                      ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626))
                                      : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.formatCurrency(customerVm.totalKhataDues),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF410002),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                customerVm.customersWithDue.isNotEmpty
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline,
                                size: 14,
                                color: customerVm.customersWithDue.isNotEmpty
                                    ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626))
                                    : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${customerVm.customersWithDue.length} pending',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.alertCrimsonDark,
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF93000A),
                                        ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Estimated Net Profit Margin
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppConstants.surfaceDark : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'EST. PROFIT',
                              style: isDark
                                  ? GoogleFonts.spaceGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppConstants.textSecondaryDark,
                                      letterSpacing: 0.5,
                                    )
                                  : GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF434655),
                                      letterSpacing: 0.5,
                                    ),
                            ),
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 16,
                              color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.formatCurrency(estProfit),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Net margin',
                              style: isDark
                                  ? GoogleFonts.spaceGrotesk(fontSize: 10, color: AppConstants.textMutedDark)
                                  : GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
                            ),
                            Text(
                              todayGrossSales > 0 ? '19.6%' : '0.0%',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Big Thumb Tactile POS Actions (Stitch Spec: 6_Shopkeeper_Dashboard_a301af12)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Register Actions',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w800, color: AppConstants.textPrimaryDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                Text(
                  'FAST LANE',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppConstants.textMutedDark,
                        )
                      : GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFF64748B),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Huge New Sale Primary Touch Target (F1 POS)
                  Expanded(
                    child: InkWell(
                      onTap: () => widget.onNavigateTab(1), // Go to Sell POS
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 108),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                          borderRadius: BorderRadius.circular(16),
                          border: isDark ? Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.35)) : null,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF4EDEA3) : const Color(0xFF85F8C4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'F1 POS',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF002114),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'New Sale',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                ),
                                Text(
                                  'Tap to ring up',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(
                                          fontSize: 10,
                                          color: const Color(0xFFCAD3FF),
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: const Color(0xFFCAD3FF),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Barcode Scan Button
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 108),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.surfaceDark : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark ? AppConstants.primaryBlueDark.withValues(alpha: 0.2) : const Color(0xFFEAEDFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Barcode Scan',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppConstants.textPrimaryDark,
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                ),
                                Text(
                                  'Instant camera lookup',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(
                                          fontSize: 10,
                                          color: AppConstants.textMutedDark,
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: const Color(0xFF64748B),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                // Add Product Button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddProductSheet(),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 72,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceDark : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add_box_rounded,
                              color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Add Product',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppConstants.textPrimaryDark,
                                        )
                                      : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                                Text(
                                  'Stock new SKU',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(fontSize: 10, color: AppConstants.textMutedDark)
                                      : GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Khata Entry Button
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onNavigateTab(3), // Navigate to Khata tab
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 72,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceDark : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.2) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  appMode.isBangla ? 'লেজার এন্ট্রি' : 'Ledger Entry',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppConstants.textPrimaryDark,
                                        )
                                      : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                                Text(
                                  appMode.isBangla ? 'গ্রাহক বাকি' : 'Customer credit',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(fontSize: 10, color: AppConstants.textMutedDark)
                                      : GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Low Stock Alert Banner
            if (lowStockCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppConstants.dueAmberDark.withValues(alpha: 0.12)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppConstants.dueAmberDark.withValues(alpha: 0.35)
                        : const Color(0xFFD97706).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: isDark ? AppConstants.dueAmberDark : const Color(0xFFB45309),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$lowStockCount Products Low in Stock',
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppConstants.dueAmberDark,
                                  )
                                : GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: const Color(0xFF78350F),
                                  ),
                          ),
                          Text(
                            'Tap to view and restock inventory before items run out',
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    color: AppConstants.textSecondaryDark,
                                  )
                                : GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: const Color(0xFF92400E),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.onNavigateTab(2), // Stock tab
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.dueAmberDark : const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'View',
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                )
                              : GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Recent Transactions Feed (Stitch Spec: 6_Shopkeeper_Dashboard_a301af12)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w800, color: AppConstants.textPrimaryDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                Text(
                  'TODAY',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppConstants.textMutedDark,
                        )
                      : GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFF64748B),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (posVm.recentTransactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfaceDark : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No sales recorded today yet. Tap "New Sale" to ring up an order!',
                    style: isDark
                        ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                        : GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posVm.recentTransactions.take(8).length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final t = posVm.recentTransactions[index];
                  final customerName = t.customerName.isNotEmpty ? t.customerName : 'Walk-in Customer';
                  final initials = customerName.length >= 2
                      ? customerName.substring(0, 2).toUpperCase()
                      : customerName.substring(0, 1).toUpperCase();

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppConstants.surfaceDark : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFDCE1FF),
                              child: Text(
                                initials,
                                style: isDark
                                    ? GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: AppConstants.primaryBlueDark,
                                      )
                                    : GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: const Color(0xFF0037B0),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      customerName,
                                      style: isDark
                                          ? GoogleFonts.spaceGrotesk(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppConstants.textPrimaryDark,
                                            )
                                          : GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '#${t.id.substring(t.id.length > 4 ? t.id.length - 4 : 0)}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      t.paymentMethod == 'bkash' ? Icons.qr_code_2_rounded : Icons.payments_rounded,
                                      size: 12,
                                      color: t.paymentMethod == 'bkash'
                                          ? Colors.pink
                                          : (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      t.paymentMethod.toUpperCase(),
                                      style: isDark
                                          ? GoogleFonts.spaceGrotesk(fontSize: 10, color: AppConstants.textMutedDark)
                                          : GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('•', style: TextStyle(fontSize: 8, color: isDark ? AppConstants.textMutedDark : Colors.grey)),
                                    const SizedBox(width: 4),
                                    Text(
                                      Formatters.formatDateTime(t.timestamp),
                                      style: isDark
                                          ? GoogleFonts.spaceGrotesk(fontSize: 10, color: AppConstants.textMutedDark)
                                          : GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.formatCurrency(t.total),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: t.dueAmount > 0
                                        ? (isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.15) : const Color(0xFFFFDAD6))
                                        : (isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15) : AppConstants.secondaryEmerald.withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    t.dueAmount > 0 ? 'PARTIAL' : 'PAID',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: t.dueAmount > 0
                                          ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFF93000A))
                                          : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.receipt_outlined,
                                size: 18,
                                color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReceiptView(receipt: t.toReceipt()),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodBtn(String label, String key, bool isDark) {
    final isSelected = _selectedPeriod == key;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? AppConstants.primaryBlueDark : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x100F172A), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: isDark
              ? GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppConstants.textMutedDark,
                )
              : GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppConstants.primaryBlue : const Color(0xFF434655),
                ),
        ),
      ),
    );
  }
}

