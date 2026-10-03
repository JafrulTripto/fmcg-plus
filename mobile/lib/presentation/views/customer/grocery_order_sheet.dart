import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/customer_view_model.dart';

class GroceryOrderSheet extends StatefulWidget {
  final CustomerModel? customer;
  final String? defaultStoreId;
  final List<StoreModel> stores;

  const GroceryOrderSheet({
    super.key,
    this.customer,
    this.defaultStoreId,
    required this.stores,
  });

  @override
  State<GroceryOrderSheet> createState() => _GroceryOrderSheetState();
}

class _GroceryOrderSheetState extends State<GroceryOrderSheet> {
  late String _selectedStoreId;
  final _searchController = TextEditingController();
  final _customItemsController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _deliveryType = 'pickup';
  String _selectedCategory = 'All';
  bool _isLoadingProducts = true;
  bool _isSubmitting = false;
  String? _productsError;

  List<ProductModel> _allProducts = [];
  final Map<String, int> _selectedQuantities = {};

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.defaultStoreId ??
        (widget.stores.isNotEmpty ? widget.stores.first.id : AppConstants.defaultStoreId);
    _addressController.text = widget.customer?.address ?? '';
    _loadStoreProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customItemsController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final products = await _apiService.getProducts(storeId: _selectedStoreId);
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _productsError = e.toString();
        });
      }
    }
  }

  List<String> get _categories {
    final cats = <String>{'All'};
    for (final p in _allProducts) {
      if (p.category.trim().isNotEmpty) {
        cats.add(p.category.trim());
      }
    }
    return cats.toList();
  }

  List<ProductModel> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _allProducts.where((p) {
      final matchesCategory = _selectedCategory == 'All' ||
          p.category.toLowerCase() == _selectedCategory.toLowerCase();
      if (!matchesCategory) return false;

      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.brand.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.packSize.toLowerCase().contains(query);
    }).toList();
  }

  double get _calculatedTotal {
    double total = 0.0;
    for (final p in _allProducts) {
      final qty = _selectedQuantities[p.id] ?? 0;
      if (qty > 0) {
        total += p.sellingPrice * qty;
      }
    }
    return total;
  }

  int get _selectedItemsCount {
    int count = 0;
    for (final qty in _selectedQuantities.values) {
      if (qty > 0) count += qty;
    }
    return count;
  }

  String _buildCompiledItemsText(AppLocalizations? l10n) {
    final buffer = StringBuffer();
    final selectedList = _allProducts.where((p) => (_selectedQuantities[p.id] ?? 0) > 0).toList();

    if (selectedList.isNotEmpty) {
      buffer.writeln(l10n?.orderedProducts ?? 'Ordered Products:');
      int idx = 1;
      for (final p in selectedList) {
        final qty = _selectedQuantities[p.id]!;
        final subtotal = p.sellingPrice * qty;
        final packInfo = p.packSize.isNotEmpty ? ' (${p.packSize})' : '';
        buffer.writeln(
          '$idx. ${p.name}$packInfo x $qty = ৳${subtotal.toStringAsFixed(0)}',
        );
        idx++;
      }
      buffer.writeln(
        '------------------------------------\n${l10n?.estimatedSubtotal ?? "Estimated Subtotal:"} ৳${_calculatedTotal.toStringAsFixed(0)}',
      );
    }

    final customText = _customItemsController.text.trim();
    if (customText.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln('');
      buffer.writeln(l10n?.additionalCustomItems ?? 'Additional / Custom Items:');
      buffer.writeln(customText);
    }

    return buffer.toString().trim();
  }

  Future<void> _submitOrder(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final authVm = context.read<AuthViewModel>();
    final customerVm = context.read<CustomerViewModel>();

    final compiledText = _buildCompiledItemsText(l10n);
    if (compiledText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.selectProductsOrEnterItems ?? 'Please select products or enter items to order',
          ),
          backgroundColor: AppConstants.alertCrimson,
        ),
      );
      return;
    }

    if (_deliveryType == 'home_delivery' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.enterDeliveryAddress ?? 'Please enter delivery address for home delivery',
          ),
          backgroundColor: AppConstants.alertCrimson,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSubmitting = true);

    final targetStore = widget.stores.where((s) => s.id == _selectedStoreId).firstOrNull;
    final storeName = targetStore?.name ??
        (widget.customer?.storeName.isNotEmpty == true
            ? widget.customer!.storeName
            : (l10n?.myStore ?? AppConstants.defaultStoreNameBn));

    final customerName = widget.customer?.name.isNotEmpty == true
        ? widget.customer!.name
        : (authVm.currentUser?.name.isNotEmpty == true
            ? authVm.currentUser!.name
            : (l10n?.valuedCustomer ?? 'Valued Customer'));

    final customerPhone = widget.customer?.phone.isNotEmpty == true
        ? widget.customer!.phone
        : (authVm.currentUser?.phone ?? '');

    final customerId = widget.customer?.id.isNotEmpty == true
        ? widget.customer!.id
        : (authVm.currentUser?.id ?? '');

    final res = await customerVm.createGroceryRequest(
      storeId: _selectedStoreId,
      storeName: storeName,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      itemsText: compiledText,
      estimatedTotal: _calculatedTotal,
      deliveryType: _deliveryType,
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    navigator.pop();

    if (res != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '$storeName: ${l10n?.orderSuccessMessage ?? "Grocery order sent successfully!"}',
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isBn = l10n?.localeName == 'bn';

    final targetStore = widget.stores.where((s) => s.id == _selectedStoreId).firstOrNull;
    final storeName = targetStore?.name ?? (l10n?.selectedStoreFallback ?? 'Selected Store');

    final quickSuggestions = isBn
        ? ['মিনিকেট চাল ৫ কেজি', 'সয়াবিন তেল ২ লিটার', 'মশুর ডাল ১ কেজি', 'চিনি ১ কেজি', 'ডিম ১ ডজন']
        : ['Miniket Rice 5kg', 'Soybean Oil 2L', 'Lentils 1kg', 'Sugar 1kg', 'Eggs 1 Dozen'];

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
          // Drag Handle & Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
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
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF059669),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.sendGroceryOrder ?? 'Send Grocery Order',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                            ),
                          ),
                          Text(
                            l10n?.sendGroceryListPrompt ?? 'Select from store inventory or write custom items',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Store Selector (if multiple stores)
                  if (widget.stores.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.targetStore ?? 'Target Store',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${widget.stores.length} ${l10n?.storesConnectedSuffix ?? "stores"}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppConstants.borderDark : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStoreId,
                          isExpanded: true,
                          dropdownColor: isDark ? AppConstants.surfaceDark : Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: widget.stores.map((s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 16,
                                    color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null && val != _selectedStoreId) {
                              setState(() {
                                _selectedStoreId = val;
                                _selectedQuantities.clear();
                              });
                              _loadStoreProducts();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 2. STORE AVAILABLE PRODUCTS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: const Color(0xFF059669),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n?.availableProductsInStore ?? 'Available Products in Store',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      if (!_isLoadingProducts)
                        Text(
                          '${_allProducts.length} ${l10n?.itemsWord ?? "items"}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Search Box
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n?.searchStoreProductsHint ?? 'Search product in store by name...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category Chips
                  if (_categories.length > 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSel = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => setState(() => _selectedCategory = cat),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFF059669)
                                      : (isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSel
                                        ? const Color(0xFF059669)
                                        : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Text(
                                  cat == 'All' ? (l10n?.allCategories ?? 'All') : cat,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    color: isSel
                                        ? Colors.white
                                        : (isDark ? AppConstants.textPrimaryDark : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Products List / Grid
                  if (_isLoadingProducts)
                    Container(
                      height: 140,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                          ),
                          const SizedBox(height: 10),
                          Text(l10n?.loadingStoreProducts ?? 'Loading...', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  else if (_productsError != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n?.errorLoadingProducts ?? 'Error loading store products',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF991B1B)),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadStoreProducts,
                            child: Text(l10n?.retry ?? 'Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_filteredProducts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 32,
                            color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n?.noProductsFound ?? 'No products found',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n?.customItemsInstructionHint ?? 'You can still write items directly in the custom list below.',
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
                    Container(
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _filteredProducts.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                        ),
                        itemBuilder: (context, idx) {
                          final p = _filteredProducts[idx];
                          final qty = _selectedQuantities[p.id] ?? 0;
                          final isInStock = p.stock > 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                // Product Icon / Avatar
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppConstants.surfaceDark : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.fastfood_outlined,
                                    size: 18,
                                    color: isInStock ? const Color(0xFF059669) : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Title & Pricing Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            Formatters.formatCurrency(p.sellingPrice),
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF059669),
                                            ),
                                          ),
                                          if (p.unit.isNotEmpty || p.packSize.isNotEmpty) ...[
                                            Text(
                                              ' / ${p.packSize.isNotEmpty ? p.packSize : p.unit}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(width: 8),
                                          // Stock Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isInStock
                                                  ? const Color(0xFF059669).withValues(alpha: 0.12)
                                                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isInStock
                                                  ? '${l10n?.stockPrefix ?? "Stock: "}${p.stock}'
                                                  : (l10n?.outOfStock ?? 'Out of stock'),
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: isInStock ? const Color(0xFF059669) : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Stepper or Add button
                                if (qty == 0)
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedQuantities[p.id] = 1;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isInStock
                                            ? const Color(0xFF059669)
                                            : (isDark ? AppConstants.surfaceDark : const Color(0xFFE2E8F0)),
                                        foregroundColor: isInStock ? Colors.white : Colors.grey,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.add, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n?.add ?? 'Add',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (qty <= 1) {
                                                _selectedQuantities.remove(p.id);
                                              } else {
                                                _selectedQuantities[p.id] = qty - 1;
                                              }
                                            });
                                          },
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            child: Icon(Icons.remove, size: 14, color: Colors.white),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(
                                            '$qty',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedQuantities[p.id] = qty + 1;
                                            });
                                          },
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            child: Icon(Icons.add, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 18),

                  // 3. CUSTOM / EXTRA ITEMS TEXT AREA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.unlistedItemsOptional ?? 'Unlisted / Custom Items (Optional)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _customItemsController,
                    minLines: 2,
                    maxLines: 4,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n?.customItemsSampleHint ?? 'e.g. 1kg Onion, 250g Ginger, Green chillies...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppConstants.borderDark : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick Suggestion Chips for custom items
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: quickSuggestions.map((sug) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              final cur = _customItemsController.text.trim();
                              if (cur.isEmpty) {
                                _customItemsController.text = sug;
                              } else {
                                _customItemsController.text = '$cur\n$sug';
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded, size: 13, color: Color(0xFF059669)),
                                  const SizedBox(width: 4),
                                  Text(
                                    sug,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. FULFILLMENT METHOD
                  Text(
                    l10n?.fulfillmentMethod ?? 'Fulfillment Method',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _deliveryType = 'pickup'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _deliveryType == 'pickup'
                                  ? const Color(0xFF1D4ED8).withValues(alpha: 0.1)
                                  : (isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _deliveryType == 'pickup'
                                    ? const Color(0xFF1D4ED8)
                                    : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                                width: _deliveryType == 'pickup' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.storefront_outlined,
                                  size: 16,
                                  color: _deliveryType == 'pickup' ? const Color(0xFF1D4ED8) : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n?.storePickup ?? 'Store Pickup',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _deliveryType == 'pickup'
                                        ? const Color(0xFF1D4ED8)
                                        : (isDark ? Colors.white70 : Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _deliveryType = 'home_delivery'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _deliveryType == 'home_delivery'
                                  ? const Color(0xFF059669).withValues(alpha: 0.1)
                                  : (isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _deliveryType == 'home_delivery'
                                    ? const Color(0xFF059669)
                                    : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                                width: _deliveryType == 'home_delivery' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delivery_dining_outlined,
                                  size: 18,
                                  color: _deliveryType == 'home_delivery' ? const Color(0xFF059669) : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n?.homeDelivery ?? 'Home Delivery',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _deliveryType == 'home_delivery'
                                        ? const Color(0xFF059669)
                                        : (isDark ? Colors.white70 : Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_deliveryType == 'home_delivery') ...[
                    const SizedBox(height: 14),
                    Text(
                      l10n?.deliveryAddressRequired ?? 'Delivery Address *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _addressController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n?.deliveryAddressHint ?? 'House/Road no., area',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                        filled: true,
                        fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppConstants.borderDark : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  Text(
                    l10n?.specialInstructionsOptional ?? 'Special Instructions (Optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n?.specialInstructionsHint ?? 'e.g. Please pack carefully, deliver by evening',
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                      filled: true,
                      fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppConstants.borderDark : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Docked Order Summary & Submit Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppConstants.borderDark : AppConstants.borderLight,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedItemsCount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$_selectedItemsCount ${l10n?.selectedWord ?? "selected"}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              l10n?.estSubtotalColon ?? 'Est. Subtotal: ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(_calculatedTotal),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () => _submitOrder(context),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSubmitting
                            ? (l10n?.sendingEllipsis ?? 'Sending...')
                            : (l10n?.submitOrderToStore ?? 'Submit Order to Store'),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
