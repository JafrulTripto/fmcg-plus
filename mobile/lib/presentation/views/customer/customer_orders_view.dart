import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/customer_view_model.dart';
import '../../view_models/pos_view_model.dart';
import 'customer_receipt_view.dart';
import 'grocery_order_sheet.dart';

class CustomerOrdersView extends StatefulWidget {
  final String? initialStoreId;
  final bool showAppBar;
  final VoidCallback? onNewOrderRequested;

  const CustomerOrdersView({
    super.key,
    this.initialStoreId,
    this.showAppBar = false,
    this.onNewOrderRequested,
  });

  @override
  State<CustomerOrdersView> createState() => _CustomerOrdersViewState();
}

class _CustomerOrdersViewState extends State<CustomerOrdersView> {
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.initialStoreId;
  }

  @override
  void didUpdateWidget(covariant CustomerOrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStoreId != oldWidget.initialStoreId) {
      _selectedStoreId = widget.initialStoreId;
    }
  }

  Color _getGroceryStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'accepted':
        return const Color(0xFF1D4ED8);
      case 'ready':
        return const Color(0xFF7C3AED);
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getGroceryStatusLabel(String status, AppLocalizations? l10n) {
    switch (status) {
      case 'pending':
        return l10n?.statusPending ?? 'Pending';
      case 'accepted':
        return l10n?.statusAccepted ?? 'Accepted';
      case 'ready':
        return l10n?.statusReady ?? 'Ready';
      case 'completed':
        return l10n?.statusCompleted ?? 'Completed';
      case 'cancelled':
        return l10n?.statusCancelled ?? 'Cancelled';
      default:
        return status;
    }
  }

  IconData _getGroceryStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'accepted':
        return Icons.thumb_up_alt_rounded;
      case 'ready':
        return Icons.inventory_2_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final authVm = context.watch<AuthViewModel>();
    final customerVm = context.watch<CustomerViewModel>();
    final posVm = context.watch<PosViewModel>();

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
            name: p.storeName.isNotEmpty ? p.storeName : (l10n?.myStore ?? AppConstants.defaultStoreNameBn),
            ownerName: '',
            ownerPhone: '',
            address: p.storeAddress,
          ));
        }
      }
    }

    // Filter grocery requests
    final customerGroceryRequests = customerVm.groceryRequests.where((req) {
      if (_selectedStoreId != null) {
        return req.storeId == _selectedStoreId;
      }
      return true;
    }).toList();

    // Count estimated grocery requested amount
    final totalRequestedAmount = customerGroceryRequests.fold<double>(
      0.0,
      (sum, r) => sum + r.estimatedTotal,
    );
    final pendingCount = customerGroceryRequests.where((r) => r.isPending).length;

    // Filter transactions / cash memos
    final customerTransactions = posVm.recentTransactions.where((tx) {
      if (_selectedStoreId != null) {
        return tx.storeId == _selectedStoreId;
      }
      return true;
    }).toList();

    final body = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Selector Chips (if multiple stores)
          if (stores.length > 1) ...[
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
                  _buildStoreFilterChip(
                    isSelected: _selectedStoreId == null,
                    label: l10n?.allStores ?? 'All Stores',
                    isDark: isDark,
                    onTap: () => setState(() => _selectedStoreId = null),
                  ),
                  const SizedBox(width: 8),
                  ...stores.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStoreFilterChip(
                      isSelected: _selectedStoreId == s.id,
                      label: s.name,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedStoreId = s.id),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Total Grocery Requested Amount Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                    : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  blurRadius: 10,
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
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF059669), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n?.totalGroceryRequested ?? 'TOTAL GROCERY REQUESTED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showGroceryRequestDialog(
                        context,
                        defaultStoreId: _selectedStoreId,
                        ledgerStores: stores,
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                      label: Text(
                        l10n?.newOrder ?? '+ New Order',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      Formatters.formatCurrency(totalRequestedAmount),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF047857) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${customerGroceryRequests.length} ${l10n?.ordersSuffix ?? "Orders"}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF047857),
                        ),
                      ),
                    ),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '$pendingCount ${l10n?.pendingSuffix ?? "Pending"}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.groceryActiveOrdersSummary ??
                      'Estimated subtotal of your grocery orders sent to stores.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grocery Requests List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.groceryOrders ?? 'Grocery Orders',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                ),
              ),
              Text(
                '${customerGroceryRequests.length} ${l10n?.requestsCountSuffix ?? "requests"}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (customerGroceryRequests.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 38,
                    color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n?.noGroceryOrdersYet ?? 'No grocery orders yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.sendGroceryListPrompt ??
                        'Select your store and send a grocery shopping list.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customerGroceryRequests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = customerGroceryRequests[index];
                final statusColor = _getGroceryStatusColor(req.status);
                final statusLabel = _getGroceryStatusLabel(req.status, l10n);
                final statusIcon = _getGroceryStatusIcon(req.status);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Type + Store + Amount + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: req.isPickup
                                        ? const Color(0xFF1D4ED8).withValues(alpha: 0.1)
                                        : const Color(0xFF059669).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        req.isPickup ? Icons.storefront_outlined : Icons.delivery_dining_outlined,
                                        size: 13,
                                        color: req.isPickup ? const Color(0xFF1D4ED8) : const Color(0xFF059669),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        req.isPickup
                                            ? (l10n?.storePickup ?? 'Store Pickup')
                                            : (l10n?.homeDelivery ?? 'Home Delivery'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: req.isPickup ? const Color(0xFF1D4ED8) : const Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      req.storeName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Items Content
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          req.itemsText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            height: 1.45,
                            color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Bottom Meta: Address, Requested Amount Count, Timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (req.estimatedTotal > 0)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n?.estAmountColon ?? 'Est. Amount: ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF065F46),
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        Formatters.formatCurrency(req.estimatedTotal),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF059669),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          const SizedBox(width: 8),
                          Text(
                            Formatters.formatDateTime(req.createdAt),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      if (req.address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                req.address,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),

          // Digital Cash Memos & Receipts Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.recentDigitalMemos ?? 'Recent Digital Memos',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                ),
              ),
              Text(
                '${customerTransactions.length} ${l10n?.receiptsCountSuffix ?? "receipts"}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (customerTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 36,
                    color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.noRecentPurchases ?? 'No recent purchases yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.posReceiptAutoSaveNotice ??
                        'Purchases from the POS will automatically appear here.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customerTransactions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tx = customerTransactions[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerReceiptView(transaction: tx),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppConstants.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_rounded, color: Color(0xFF1D4ED8), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n?.memoNumber ?? "Memo #"}${tx.id.length > 8 ? tx.id.substring(0, 8).toUpperCase() : tx.id.toUpperCase()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${tx.items.length} ${l10n?.itemsWord ?? "items"} • ${tx.paymentMethod.toUpperCase()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.formatCurrency(tx.total),
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              Formatters.formatDateTime(tx.createdAt),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
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
          l10n?.myOrdersTitle ?? 'My Orders',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
      ),
      body: body,
    );
  }

  Widget _buildStoreFilterChip({
    required bool isSelected,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8))
              : (isDark ? AppConstants.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8))
                : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight),
          ),
        ),
      ),
    );
  }
}
