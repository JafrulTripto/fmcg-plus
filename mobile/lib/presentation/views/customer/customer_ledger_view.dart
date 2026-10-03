import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../view_models/app_mode_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/customer_view_model.dart';

class CustomerLedgerView extends StatefulWidget {
  final String? initialStoreId;
  final bool showAppBar;
  final Function(String? storeId)? onStoreSelected;

  const CustomerLedgerView({
    super.key,
    this.initialStoreId,
    this.showAppBar = false,
    this.onStoreSelected,
  });

  @override
  State<CustomerLedgerView> createState() => _CustomerLedgerViewState();
}

class _CustomerLedgerViewState extends State<CustomerLedgerView> {
  String? _selectedStoreId;
  String _khataFilter = 'all'; // 'all', 'credit', 'payment'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.initialStoreId;
  }

  @override
  void didUpdateWidget(covariant CustomerLedgerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStoreId != oldWidget.initialStoreId) {
      _selectedStoreId = widget.initialStoreId;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            : (l10n?.myStore ?? AppConstants.defaultStoreName));

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
                                l10n?.settleStoreBalance ?? 'Settle Store Balance',
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
                            l10n?.currentDue ?? 'Current Due',
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
                        labelText: l10n?.paymentAmountWithSymbol ?? 'Payment Amount (৳)',
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
                              '${l10n?.payWith ?? "Pay via"} $selectedMfs',
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

    ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appMode = context.watch<AppModeViewModel>();
    final l10n = AppLocalizations.of(context);
    final authVm = context.watch<AuthViewModel>();
    final customerVm = context.watch<CustomerViewModel>();

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

    CustomerModel? currentProfile;
    StoreModel? currentStoreModel;

    if (_selectedStoreId != null) {
      currentProfile = profileByStoreId[_selectedStoreId];
      currentStoreModel = stores.where((s) => s.id == _selectedStoreId).firstOrNull;
    } else if (myProfiles.isNotEmpty) {
      currentProfile = myProfiles.first;
    }

    final List<KhataEntryModel> visibleLedgerEntries;
    if (_selectedStoreId != null) {
      visibleLedgerEntries = (currentProfile?.ledgerEntries ?? []).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      visibleLedgerEntries = myProfiles.expand((p) => p.ledgerEntries).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    final filteredLedgerEntries = visibleLedgerEntries.where((e) {
      if (_khataFilter == 'credit' && e.creditChange <= 0) return false;
      if (_khataFilter == 'payment' && !(e.creditChange < 0 || e.type.toLowerCase().contains('payment'))) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesLabel = e.label.toLowerCase().contains(q);
        final matchesDesc = e.description.toLowerCase().contains(q);
        final matchesStore = e.storeName.toLowerCase().contains(q);
        final matchesAmount = e.creditChange.abs().toString().contains(q);
        if (!matchesLabel && !matchesDesc && !matchesStore && !matchesAmount) return false;
      }
      return true;
    }).toList();

    final body = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Selector Chips
          Text(
            l10n?.filterByStore ?? 'Filter by Store',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildStoreChip(
                  isSelected: _selectedStoreId == null,
                  label: l10n?.allStores ?? 'All Stores',
                  badgeText: Formatters.formatCurrency(totalCombinedDue),
                  badgeColor: totalCombinedDue > 0
                      ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                      : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                  isDark: isDark,
                  onTap: () {
                    setState(() => _selectedStoreId = null);
                    widget.onStoreSelected?.call(null);
                  },
                ),
                const SizedBox(width: 8),
                ...stores.map((store) {
                  final isSelected = _selectedStoreId == store.id;
                  final prof = profileByStoreId[store.id];
                  final storeDue = prof?.currentBalance ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStoreChip(
                      isSelected: isSelected,
                      label: store.name,
                      badgeText: Formatters.formatCurrency(storeDue),
                      badgeColor: storeDue > 0
                          ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                          : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                      isDark: isDark,
                      onTap: () {
                        setState(() => _selectedStoreId = store.id);
                        widget.onStoreSelected?.call(store.id);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Balance Overview Card
          _buildBalanceCard(
            context,
            totalDue: _selectedStoreId != null ? (currentProfile?.currentBalance ?? 0.0) : totalCombinedDue,
            selectedStoreName: currentStoreModel?.name,
            currentProfile: currentProfile,
            isDark: isDark,
            appMode: appMode,
          ),
          const SizedBox(height: 18),

          // Search and Filters Bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n?.searchLedger ?? 'Search ledger...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      filled: true,
                      fillColor: isDark ? AppConstants.surfaceDark : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Chips (সব / বাকি ক্রয় / পরিশোধ)
          Row(
            children: [
              _buildKhataFilterChip(
                id: 'all',
                label: l10n?.all ?? 'All',
                count: visibleLedgerEntries.length,
                isDark: isDark,
                color: const Color(0xFF1D4ED8),
              ),
              const SizedBox(width: 8),
              _buildKhataFilterChip(
                id: 'credit',
                label: l10n?.dueSales ?? 'Due Sales',
                count: visibleLedgerEntries.where((e) => e.creditChange > 0).length,
                isDark: isDark,
                color: const Color(0xFFDC2626),
              ),
              const SizedBox(width: 8),
              _buildKhataFilterChip(
                id: 'payment',
                label: l10n?.payments ?? 'Payments',
                count: visibleLedgerEntries.where((e) => e.creditChange < 0 || e.type.toLowerCase().contains('payment')).length,
                isDark: isDark,
                color: const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ledger Passbook Entries List
          if (visibleLedgerEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_stories_outlined,
                      size: 40,
                      color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n?.noKhataLedgerEntries ?? 'No Khata ledger entries',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n?.connectedStoreLedgerNotice ?? 'Whenever a store records credit purchases or repayments, entries will appear in real time in this digital khata passbook.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (filteredLedgerEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                ),
              ),
              child: Text(
                l10n?.noRecordsMatchFilter ?? 'No records match this filter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredLedgerEntries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = filteredLedgerEntries[index];
                final isCredit = entry.creditChange > 0;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCredit
                              ? (isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.15) : const Color(0xFFFFDAD6))
                              : (isDark ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.15) : const Color(0xFFD1FAE5)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isCredit ? Icons.add_shopping_cart_rounded : Icons.payments_rounded,
                          color: isCredit
                              ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFF93000A))
                              : (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF065F46)),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.label.isNotEmpty
                                        ? entry.label
                                        : (isCredit
                                            ? (l10n?.creditPurchase ?? 'Credit Purchase')
                                            : (l10n?.repayment ?? 'Repayment')),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (entry.storeName.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      entry.storeName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (entry.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
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
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  Formatters.formatDateTime(entry.timestamp),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isCredit
                                ? '+${Formatters.formatCurrency(entry.creditChange)}'
                                : '-${Formatters.formatCurrency(entry.creditChange.abs())}',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isCredit
                                  ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626))
                                  : (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF059669)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
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
        ],
      ),
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      backgroundColor: isDark ? AppConstants.canvasDark : AppConstants.canvasLight,
      appBar: AppBar(
        title: Text(
          l10n?.khataLedger ?? 'Khata Ledger',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
      ),
      body: body,
    );
  }

  Widget _buildBalanceCard(
    BuildContext context, {
    required double totalDue,
    String? selectedStoreName,
    CustomerModel? currentProfile,
    required bool isDark,
    required AppModeViewModel appMode,
  }) {
    final l10n = AppLocalizations.of(context);
    final hasDue = totalDue > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDue
              ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5))
              : (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasDue ? const Color(0xFFDC2626) : const Color(0xFF059669)).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                    selectedStoreName != null
                        ? '$selectedStoreName - ${l10n?.currentDue ?? "DUE"}'
                        : (l10n?.totalOutstandingBalance ?? 'TOTAL OUTSTANDING BALANCE'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: hasDue
                          ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                          : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                    ),
                  ),
                ],
              ),
              if (hasDue && currentProfile != null)
                ElevatedButton.icon(
                  onPressed: () => _showMfsPaymentDialog(
                    context,
                    currentProfile,
                    storeName: selectedStoreName,
                  ),
                  icon: const Icon(Icons.payment_rounded, size: 14),
                  label: Text(
                    l10n?.payDue ?? 'Pay Due',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2136E), // bKash brand color
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Formatters.formatCurrency(totalDue),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: hasDue
                  ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626))
                  : (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF059669)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasDue
                ? (l10n?.recordedKhataPurchases ?? 'Recorded credit purchases by shopkeeper.')
                : (l10n?.zeroOutstandingDues ?? 'You have zero outstanding dues.'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildKhataFilterChip({
    required String id,
    required String label,
    required int count,
    required bool isDark,
    required Color color,
  }) {
    final isSel = _khataFilter == id;
    return InkWell(
      onTap: () => setState(() => _khataFilter = id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppConstants.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? color : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
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
                color: isSel ? color : (isDark ? AppConstants.textSecondaryDark : const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSel ? color : (isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSel ? Colors.white : (isDark ? AppConstants.textMutedDark : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
