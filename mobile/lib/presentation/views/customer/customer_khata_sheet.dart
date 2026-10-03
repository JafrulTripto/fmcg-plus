import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../l10n/app_localizations.dart';

class CustomerKhataSheet extends StatefulWidget {
  final StoreModel store;
  final CustomerModel profile;
  final void Function(BuildContext context, CustomerModel customer, {String? storeName}) onPayDue;

  const CustomerKhataSheet({
    super.key,
    required this.store,
    required this.profile,
    required this.onPayDue,
  });

  @override
  State<CustomerKhataSheet> createState() => _CustomerKhataSheetState();
}

class _CustomerKhataSheetState extends State<CustomerKhataSheet> {
  String _activeFilter = 'all'; // 'all', 'credit', 'payment'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final customer = widget.profile;
    final store = widget.store;
    final hasDue = customer.currentDue > 0;
    final allEntries = customer.ledgerEntries;

    final filteredEntries = allEntries.where((e) {
      if (_activeFilter == 'credit') {
        return e.creditChange > 0;
      } else if (_activeFilter == 'payment') {
        return e.creditChange < 0 || e.type.toLowerCase().contains('payment');
      }
      return true;
    }).toList();

    // Credit limit usage percentage
    final creditUsage = customer.creditLimit > 0
        ? (customer.currentBalance / customer.creditLimit).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
        ),
      ),
      child: Column(
        children: [
          // Header & Drag Handle
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                ),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF1D4ED8),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.storeKhataLedger ?? 'Store Khata Ledger',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.storefront_rounded,
                                size: 12,
                                color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  store.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Balance & Credit Limit Summary Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasDue
                    ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA))
                    : (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasDue
                          ? (l10n?.totalOutstanding ?? 'TOTAL OUTSTANDING')
                          : (l10n?.zeroBalance ?? 'ZERO BALANCE'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: hasDue
                            ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                            : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hasDue
                            ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                            : const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hasDue
                            ? (l10n?.activeDueStatus ?? 'Active Due')
                            : (l10n?.settledStatus ?? 'Settled'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: hasDue ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.formatCurrency(customer.currentBalance),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 10),

                // Credit Limit Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n?.creditLimitWithColon ?? "Credit Limit:"} ৳${customer.creditLimit.toStringAsFixed(0)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${l10n?.remainingCreditWithColon ?? "Remaining:"} ৳${(customer.creditLimit - customer.currentBalance).clamp(0.0, double.infinity).toStringAsFixed(0)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: creditUsage,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      creditUsage > 0.8
                          ? const Color(0xFFDC2626)
                          : (creditUsage > 0.5 ? const Color(0xFFD97706) : const Color(0xFF059669)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Tabs (All / Due Sales / Payments)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip(
                  id: 'all',
                  label: l10n?.allEntries ?? 'All Entries',
                  count: allEntries.length,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  id: 'credit',
                  label: l10n?.creditDueFilter ?? 'Credit Due',
                  count: allEntries.where((e) => e.creditChange > 0).length,
                  color: const Color(0xFFDC2626),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  id: 'payment',
                  label: l10n?.paymentsFilter ?? 'Payments',
                  count: allEntries.where((e) => e.creditChange < 0).length,
                  color: const Color(0xFF059669),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Ledger Entries List
          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n?.noLedgerRecordsFound ?? 'No ledger records found',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.noKhataRecordsSubtitle ?? 'No credit purchases or payments have been recorded for this store yet.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    itemCount: filteredEntries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final entry = filteredEntries[idx];
                      final isCredit = entry.creditChange > 0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge Icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCredit
                                    ? (isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.15) : const Color(0xFFFFDAD6))
                                    : (isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15) : const Color(0xFFD1FAE5)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isCredit ? Icons.add_shopping_cart_rounded : Icons.payments_rounded,
                                color: isCredit
                                    ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFF93000A))
                                    : (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF065F46)),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Entry Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        entry.label.isNotEmpty ? entry.label : (isCredit ? (l10n?.creditPurchase ?? 'Credit Purchase') : (l10n?.repayment ?? 'Payment')),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (entry.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: isDark ? AppConstants.textMutedDark : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatDateTime(entry.timestamp),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Amounts (Credit change + running balance)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isCredit
                                      ? '+${Formatters.formatCurrency(entry.creditChange)}'
                                      : '-${Formatters.formatCurrency(entry.creditChange.abs())}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isCredit
                                        ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626))
                                        : (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF059669)),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${l10n?.balanceColon ?? "Bal:"} ${Formatters.formatCurrency(entry.runningBalance)}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Settle Due Button (if due > 0)
          if (hasDue)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onPayDue(context, customer, storeName: store.name);
                    },
                    icon: const Icon(Icons.payment_rounded, size: 18),
                    label: Text(
                      l10n?.settleBalanceViaMfs ?? 'Settle Balance via bKash / Nagad',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    required int count,
    Color? color,
    required bool isDark,
  }) {
    final isSel = _activeFilter == id;
    final badgeColor = color ?? const Color(0xFF1D4ED8);

    return InkWell(
      onTap: () => setState(() => _activeFilter = id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel
              ? badgeColor.withValues(alpha: 0.14)
              : (isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel
                ? badgeColor
                : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
            width: isSel ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel
                    ? badgeColor
                    : (isDark ? AppConstants.textPrimaryDark : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSel ? badgeColor : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
