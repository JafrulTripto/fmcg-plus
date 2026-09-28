import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/customer_model.dart';
import '../../view_models/customer_view_model.dart';
import '../../view_models/app_mode_view_model.dart';
import '../../widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';

class CustomersView extends StatelessWidget {
  const CustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    final customerVm = context.watch<CustomerViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await customerVm.loadCustomers();
      },
      child: Column(
        children: [
          // Total Khata Dues Hero Strip (Stitch Spec: 7_Customer_Khata_and_Profile_e22116d4)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF991B1B), Color(0xFF7F1D1D)]
                      : const [Color(0xFFDC2626), Color(0xFFB91C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: AppConstants.alertCrimsonDark.withValues(alpha: 0.35)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.totalKhataCredit ?? 'TOTAL LEDGER DUES',
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                )
                              : GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(customerVm.totalKhataDues),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${customerVm.pendingDebtorCount} ${l10n?.activeDebtors ?? "Active Debtors"}',
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 11)
                              : GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _openAddCustomerDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
                      foregroundColor: isDark ? AppConstants.alertCrimsonDark : const Color(0xFF8F000B),
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      l10n?.newCustomer ?? '+ Customer',
                      style: isDark
                          ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 12)
                          : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                onChanged: customerVm.setSearchQuery,
                decoration: InputDecoration(
                  hintText: l10n?.searchCustomers ?? 'Search customers by name or phone...',
                  hintStyle: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF747686)),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                style: isDark
                    ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textPrimaryDark)
                    : GoogleFonts.plusJakartaSans(fontSize: 12),
              ),
            ),
          ),

          // Filter Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _buildFilterTab(context, l10n?.all ?? 'All', 'all', customerVm, isDark),
                const SizedBox(width: 6),
                _buildFilterTab(context, l10n?.dueBalance ?? 'Due Balance', 'due', customerVm, isDark),
                const SizedBox(width: 6),
                _buildFilterTab(context, l10n?.zeroBalance ?? 'Zero Balance', 'zero', customerVm, isDark),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: customerVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customerVm.customers.isEmpty
                    ? Center(
                        child: Text(
                          'No customers found',
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(color: AppConstants.textMutedDark, fontSize: 13)
                              : GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
                        itemCount: customerVm.customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final c = customerVm.customers[index];
                          return InkWell(
                            onTap: () => _openCustomerProfileSheet(context, c),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
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
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: c.hasOutstanding
                                        ? (isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.15) : const Color(0xFFFFDAD6))
                                        : (isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15) : const Color(0xFFD1FAE5)),
                                    child: Text(
                                      c.initials,
                                      style: isDark
                                          ? GoogleFonts.spaceGrotesk(
                                              color: c.hasOutstanding
                                                  ? AppConstants.alertCrimsonDark
                                                  : AppConstants.secondaryEmeraldDark,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            )
                                          : GoogleFonts.plusJakartaSans(
                                              color: c.hasOutstanding
                                                  ? const Color(0xFF93000A)
                                                  : const Color(0xFF065F46),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              c.name,
                                              style: isDark
                                                  ? GoogleFonts.spaceGrotesk(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                      color: AppConstants.textPrimaryDark,
                                                    )
                                                  : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                                            ),
                                            if (c.status == 'warning') ...[
                                              const SizedBox(width: 4),
                                              const StatusBadge(label: 'Overdue', type: BadgeType.alert),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          c.phone,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        Formatters.formatCurrency(c.currentDue),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: c.hasOutstanding
                                              ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                                              : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                                        ),
                                      ),
                                      Text(
                                        c.hasOutstanding ? 'Outstanding' : 'All Settled',
                                        style: isDark
                                            ? GoogleFonts.spaceGrotesk(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: c.hasOutstanding
                                                    ? AppConstants.alertCrimsonDark
                                                    : AppConstants.secondaryEmeraldDark,
                                              )
                                            : GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: c.hasOutstanding ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(BuildContext context, String label, String filter, CustomerViewModel vm, bool isDark) {
    final isSelected = vm.filter == filter;
    return InkWell(
      onTap: () => vm.setFilter(filter),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue)
              : (isDark ? AppConstants.surfaceDark : Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue)
                : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x060F172A), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Text(
          label,
          style: isDark
              ? GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppConstants.textSecondaryDark,
                )
              : GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF434655),
                ),
        ),
      ),
    );
  }

  void _openCustomerProfileSheet(BuildContext context, CustomerModel customer) {
    final appMode = context.read<AppModeViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                color: isDark ? AppConstants.surfaceOverlayDark : Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppConstants.borderDark : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFDCE1FF),
                                child: Text(
                                  customer.initials,
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w800,
                                          color: AppConstants.primaryBlueDark,
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0037B0),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: isDark ? AppConstants.textPrimaryDark : null,
                                    ),
                                  ),
                                  Text(
                                    customer.phone,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: isDark ? AppConstants.textMutedDark : null,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Outstanding Balance Hero Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: customer.hasOutstanding
                              ? (isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.15) : const Color(0xFFFFDAD6))
                              : (isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15) : const Color(0xFFD1FAE5)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: customer.hasOutstanding
                                ? (isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.35) : const Color(0xFFDC2626).withOpacity(0.3))
                                : (isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.35) : const Color(0xFF059669).withOpacity(0.3)),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)?.currentDue ?? 'Current Due',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: customer.hasOutstanding
                                              ? AppConstants.alertCrimsonDark
                                              : AppConstants.secondaryEmeraldDark,
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: customer.hasOutstanding ? const Color(0xFF93000A) : const Color(0xFF065F46),
                                        ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatCurrency(customer.currentDue),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: customer.hasOutstanding
                                        ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFF410002))
                                        : (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF064E3B)),
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _openPaymentEntryDialog(context, customer),
                              icon: const Icon(Icons.payments_rounded, size: 16),
                              label: Text(AppLocalizations.of(context)?.recordPayment ?? 'Record Payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: customer.hasOutstanding
                                    ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0))
                                    : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Ledger History Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            appMode.isBangla ? 'লেজার হিসাব খতিয়ান' : 'Ledger History',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppConstants.textPrimaryDark : null,
                            ),
                          ),
                          Text(
                            '${customer.ledgerEntries.length} Records',
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(fontSize: 11, color: AppConstants.textMutedDark)
                                : GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (customer.ledgerEntries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No ledger entries found for this customer.',
                              style: isDark
                                  ? GoogleFonts.spaceGrotesk(color: AppConstants.textMutedDark, fontSize: 12)
                                  : GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12),
                            ),
                          ),
                        )
                      else
                        ...customer.ledgerEntries.map((entry) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppConstants.surfaceDark : Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: entry.creditChange > 0
                                              ? (isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.15) : const Color(0xFFFFDAD6))
                                              : (isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15) : const Color(0xFFD1FAE5)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          entry.creditChange > 0 ? Icons.add_circle_outline : Icons.check_circle_outline,
                                          color: entry.creditChange > 0
                                              ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFF93000A))
                                              : (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF065F46)),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.description,
                                            style: isDark
                                                ? GoogleFonts.spaceGrotesk(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                    color: AppConstants.textPrimaryDark,
                                                  )
                                                : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                                          ),
                                          Text(
                                            Formatters.formatDateTime(entry.timestamp),
                                            style: isDark
                                                ? GoogleFonts.spaceGrotesk(fontSize: 10, color: AppConstants.textMutedDark)
                                                : GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        entry.creditChange > 0
                                            ? '+${Formatters.formatCurrency(entry.creditChange)}'
                                            : '-${Formatters.formatCurrency(entry.creditChange.abs())}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: entry.creditChange > 0
                                              ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626))
                                              : (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF059669)),
                                        ),
                                      ),
                                      Text(
                                        'Bal: ${Formatters.formatCurrency(entry.runningBalance)}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openPaymentEntryDialog(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => _CustomerPaymentDialog(customer: customer),
    );
  }

  void _openAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _NewCustomerDialog(),
    );
  }
}

class _CustomerPaymentDialog extends StatefulWidget {
  final CustomerModel customer;
  const _CustomerPaymentDialog({required this.customer});

  @override
  State<_CustomerPaymentDialog> createState() => _CustomerPaymentDialogState();
}

class _CustomerPaymentDialogState extends State<_CustomerPaymentDialog> {
  final _amountCtrl = TextEditingController(text: '500');
  final _notesCtrl = TextEditingController();
  String _selectedMethod = 'cash';
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _addAmount(double delta) {
    double current = double.tryParse(_amountCtrl.text) ?? 0.0;
    setState(() => _amountCtrl.text = (current + delta).toStringAsFixed(0));
  }

  void _setFullDue() {
    setState(() => _amountCtrl.text = widget.customer.currentDue.toStringAsFixed(0));
  }

  void _submit() async {
    final amt = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amt <= 0) return;

    setState(() => _isSaving = true);
    final success = await context.read<CustomerViewModel>().recordPayment(
          customerId: widget.customer.id,
          amount: amt,
          method: _selectedMethod,
          notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : 'Counter Cash Deposit',
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Recorded ৳${amt.toInt()} payment from ${widget.customer.name}')),
            ],
          ),
          backgroundColor: AppConstants.secondaryEmerald,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppConstants.surfaceOverlayDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.surfaceOverlayDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: AppConstants.borderDark) : null,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF006C4A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.recordKhataPayment ?? 'Record Ledger Payment',
                        style: isDark
                            ? GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.textPrimaryDark,
                              )
                            : GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF131B2E),
                              ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 20, color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Customer Info Strip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark ? AppConstants.surfaceDark : const Color(0xFFEFF6FF),
                      child: Text(
                        c.initials,
                        style: isDark
                            ? GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w800,
                                color: AppConstants.primaryBlueDark,
                                fontSize: 14,
                              )
                            : GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1D4ED8),
                                fontSize: 14,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppConstants.textPrimaryDark,
                                  )
                                : GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: const Color(0xFF131B2E),
                                  ),
                          ),
                          Text(
                            c.phone,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppConstants.alertCrimsonDark.withValues(alpha: 0.15)
                            : const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'CURRENT DUE',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFF93000A),
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(c.currentDue),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFFBA1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method Chips
              Text(
                l10n?.paymentMethod ?? 'Payment Method',
                style: isDark
                    ? GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppConstants.textPrimaryDark)
                    : GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMethodChip('cash', l10n?.cashPayment ?? 'Cash', Icons.payments_outlined, isDark),
                  const SizedBox(width: 8),
                  _buildMethodChip('bkash', 'bKash', Icons.qr_code_2_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildMethodChip('bank', 'Bank', Icons.account_balance_outlined, isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Amount Input
              Text(
                l10n?.paymentAmountWithSymbol ?? 'Payment Amount (৳)',
                style: isDark
                    ? GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppConstants.textPrimaryDark)
                    : GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF006C4A),
                ),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '৳',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF006C4A),
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  filled: true,
                  fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF006C4A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Quick Increment Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildPresetChip('+৳100', () => _addAmount(100), isDark),
                  _buildPresetChip('+৳500', () => _addAmount(500), isDark),
                  _buildPresetChip('+৳1000', () => _addAmount(1000), isDark),
                  if (c.currentDue > 0)
                    InkWell(
                      onTap: _setFullDue,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15)
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${l10n?.fullDue ?? "Full Due"}: ৳${c.currentDue.toInt()}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF00714E),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes Input
              Text(
                l10n?.notesOptional ?? 'Notes / Voucher # (Optional)',
                style: isDark
                    ? GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppConstants.textPrimaryDark)
                    : GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtrl,
                style: isDark
                    ? GoogleFonts.spaceGrotesk(fontSize: 13, color: AppConstants.textPrimaryDark)
                    : GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: InputDecoration(
                  hintText: l10n?.notesHint ?? 'e.g., Counter deposit or bKash TrxID',
                  hintStyle: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF006C4A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                          foregroundColor: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          l10n?.cancel ?? 'Cancel',
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13)
                              : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          l10n?.confirmPayment ?? 'Record Payment',
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13)
                              : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF006C4A),
                          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
  }

  Widget _buildMethodChip(String id, String label, IconData icon, bool isDark) {
    final isSelected = _selectedMethod == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = id),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF006C4A))
                : (isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF006C4A))
                  : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                    : (isDark ? AppConstants.textMutedDark : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: isDark
                    ? GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                            : AppConstants.textPrimaryDark,
                      )
                    : GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: isDark ? Border.all(color: AppConstants.borderDark) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
          ),
        ),
      ),
    );
  }
}

class _NewCustomerDialog extends StatefulWidget {
  const _NewCustomerDialog();

  @override
  State<_NewCustomerDialog> createState() => _NewCustomerDialogState();
}

class _NewCustomerDialogState extends State<_NewCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _limitCtrl = TextEditingController(text: '5000');
  final _addressCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _limitCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final success = await context.read<CustomerViewModel>().createCustomer(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          creditLimit: double.tryParse(_limitCtrl.text) ?? 5000.0,
          address: _addressCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Created Ledger account for ${_nameCtrl.text}')),
            ],
          ),
          backgroundColor: AppConstants.secondaryEmerald,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppConstants.surfaceOverlayDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.surfaceOverlayDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: AppConstants.borderDark) : null,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.newKhataCustomer ?? 'New Ledger Customer',
                          style: isDark
                              ? GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.textPrimaryDark,
                                )
                              : GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF131B2E),
                                ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 20, color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                RichText(
                  text: TextSpan(
                    style: isDark
                        ? GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppConstants.textPrimaryDark)
                        : GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
                    children: [
                      TextSpan(text: '${l10n?.customerName ?? "Customer Name"} '),
                      const TextSpan(text: '*', style: TextStyle(color: AppConstants.alertCrimson)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  style: isDark ? GoogleFonts.spaceGrotesk(fontSize: 13, color: AppConstants.textPrimaryDark) : null,
                  decoration: InputDecoration(
                    hintText: l10n?.ownerNameHint ?? 'e.g., Rafiqul Islam, Karim Bhai',
                    hintStyle: isDark
                        ? GoogleFonts.spaceGrotesk(fontSize: 13, color: AppConstants.textMutedDark)
                        : GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? (l10n?.nameRequired ?? 'Name is required') : null,
                ),
                const SizedBox(height: 14),

                // Phone
                RichText(
                  text: TextSpan(
                    style: isDark
                        ? GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppConstants.textPrimaryDark)
                        : GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
                    children: [
                      TextSpan(text: '${l10n?.customerPhone ?? "Phone Number"} '),
                      const TextSpan(text: '*', style: TextStyle(color: AppConstants.alertCrimson)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppConstants.textPrimaryDark : null,
                  ),
                  decoration: InputDecoration(
                    hintText: '01711XXXXXX',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(
                      Icons.phone_android_rounded,
                      size: 20,
                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                    ),
                    filled: true,
                    fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? (l10n?.phoneRequired ?? 'Phone number is required') : null,
                ),
                const SizedBox(height: 14),

                // Credit Limit
                Text(
                  l10n?.creditLimit ?? 'Credit Limit',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppConstants.textPrimaryDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _limitCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppConstants.textPrimaryDark : null,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '৳',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    filled: true,
                    fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [2000, 5000, 10000, 20000].map((lim) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => _limitCtrl.text = lim.toString()),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: isDark ? Border.all(color: AppConstants.borderDark) : null,
                          ),
                          child: Text(
                            '৳${lim ~/ 1000}k',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Address (Optional)
                Text(
                  l10n?.addressOptional ?? 'Address / Area (Optional)',
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppConstants.textPrimaryDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressCtrl,
                  style: isDark
                      ? GoogleFonts.spaceGrotesk(fontSize: 13, color: AppConstants.textPrimaryDark)
                      : GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: l10n?.addressHint ?? 'e.g., Road 4, House 12, Mirpur 10',
                    hintStyle: isDark
                        ? GoogleFonts.spaceGrotesk(fontSize: 12, color: AppConstants.textMutedDark)
                        : GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                            foregroundColor: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            l10n?.cancel ?? 'Cancel',
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13)
                                : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _submit,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.person_add_alt_1, size: 18),
                          label: Text(
                            l10n?.openKhataAccount ?? 'Open Ledger Account',
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13)
                                : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


