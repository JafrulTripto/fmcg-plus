import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../view_models/pos_view_model.dart';
import '../../view_models/inventory_view_model.dart';
import 'barcode_scanner_view.dart';
import 'checkout_dialog.dart';

class SellPosView extends StatefulWidget {
  const SellPosView({super.key});

  @override
  State<SellPosView> createState() => _SellPosViewState();
}

class _SellPosViewState extends State<SellPosView> {
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'All Items',
    'Food',
    'Beverages',
    'Spices & Oil',
    'Snacks & Biscuits',
    'Rice & Flour',
    'Dairy',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCartBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: isDark ? AppConstants.surfaceOverlayDark : theme.colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Consumer<PosViewModel>(
              builder: (_, posVm, __) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.borderInteractiveDark : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Active Sale Basket',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppConstants.textPrimaryDark : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${posVm.totalItemCount} items',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            posVm.clearCart();
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: posVm.cart.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item = posVm.cart[i];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppConstants.surfaceElevatedDark : theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppConstants.borderInteractiveDark : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isDark ? AppConstants.textPrimaryDark : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${Formatters.formatCurrency(item.product.sellingPrice)} / ${item.product.unit}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        size: 20,
                                        color: isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson,
                                      ),
                                      onPressed: () => posVm.updateQuantity(item.product.id, -1),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: isDark ? AppConstants.textPrimaryDark : null,
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        size: 20,
                                        color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                                      ),
                                      onPressed: () => posVm.updateQuantity(item.product.id, 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Formatters.formatCurrency(item.total),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Divider(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Payable:',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? AppConstants.textSecondaryDark : null,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(posVm.grandTotal),
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => const CheckoutDialog(),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryVm = context.watch<InventoryViewModel>();
    final posVm = context.watch<PosViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          children: [
            // Top Command: Search Bar + Barcode Scan Button (Stitch Spec)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppConstants.borderInteractiveDark : const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x080F172A), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: inventoryVm.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Search product, barcode, SKU...',
                          hintStyle: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.cancel,
                                    size: 16,
                                    color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    inventoryVm.setSearchQuery('');
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: isDark ? AppConstants.textPrimaryDark : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Scan',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Category Filter Pills (Stitch Spec)
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final filterVal = cat == 'All Items' ? 'All' : cat;
                  final isSelected = inventoryVm.selectedCategory == filterVal || (index == 0 && inventoryVm.selectedCategory == 'All');

                  return InkWell(
                    onTap: () => inventoryVm.setCategory(filterVal),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue)
                            : (isDark ? AppConstants.surfaceDark : theme.colorScheme.surface),
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
                      child: Center(
                        child: Text(
                          cat,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Catalog Header Strip (Stitch Spec: Popular Products | 48 SKUs)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Catalog Items',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppConstants.textPrimaryDark : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${inventoryVm.products.length} SKUs',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppConstants.textSecondaryDark : const Color(0xFF434655),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Tap to add',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Product Catalog Rapid Matrix / Horizontal Rows (Stitch Spec)
            Expanded(
              child: inventoryVm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : inventoryVm.products.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, posVm.totalItemCount > 0 ? 140 : 20),
                          itemCount: inventoryVm.products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = inventoryVm.products[index];
                            return _buildProductRow(context, p, posVm);
                          },
                        ),
            ),
          ],
        ),

        // Main High-Velocity CTA Bar (Stitch Spec from 4_Sell_and_POS_Terminal_bbafe438)
        if (posVm.totalItemCount > 0)
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? const Color(0x60000000) : const Color(0x180F172A),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick tender chips (Stitch spec: Exact, +10, +50, 100, 500, 1000)
                  SizedBox(
                    height: 28,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildTenderChip('Exact', isDark: isDark, onTap: () => _openCartBottomSheet(context)),
                        _buildTenderChip('+৳10', isDark: isDark, onTap: () => _openCartBottomSheet(context)),
                        _buildTenderChip('+৳50', isDark: isDark, onTap: () => _openCartBottomSheet(context)),
                        _buildTenderChip('৳100', isDark: isDark, onTap: () => _openCartBottomSheet(context)),
                        _buildTenderChip('৳500', isDark: isDark, onTap: () => _openCartBottomSheet(context)),
                        _buildTenderChip('৳1,000', isDark: isDark, onTap: () => _openCartBottomSheet(context)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Main High-Velocity CTA Bar
                  Row(
                    children: [
                      // Khata / To Due Button (Stitch Spec)
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => const CheckoutDialog(initialMode: 'due'),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppConstants.alertCrimsonDark.withValues(alpha: 0.12)
                                : const Color(0xFFFFDAD6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626)).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFF93000A),
                                size: 18,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'To Due',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFF93000A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Primary Instant Charge Button (Stitch Spec)
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const CheckoutDialog(),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue).withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'INSTANT CHARGE',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: const Color(0xFFCAD3FF),
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(posVm.grandTotal),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${posVm.totalItemCount} items',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
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
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTenderChip(String label, {required VoidCallback onTap, bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppConstants.borderInteractiveDark : const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppConstants.onSurfaceDark : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Horizontal Product Row matching Stitch Spec (4_Sell_and_POS_Terminal_bbafe438)
  Widget _buildProductRow(BuildContext context, dynamic p, PosViewModel posVm) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inCartCount = posVm.getItemQuantity(p.id);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: inCartCount > 0 && isDark ? AppConstants.surfaceElevatedDark : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: inCartCount > 0
              ? (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue.withOpacity(0.4))
              : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          // Product Thumbnail Box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppConstants.borderInteractiveDark : const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(p.category),
                color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Details (Name, Category Tag, Price, Stock)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppConstants.textPrimaryDark : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: p.isLowStock
                            ? (isDark ? AppConstants.alertCrimsonDark.withValues(alpha: 0.12) : const Color(0xFFFFDAD6))
                            : (isDark
                                ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.12)
                                : AppConstants.secondaryEmerald.withOpacity(0.12)),
                        borderRadius: BorderRadius.circular(4),
                        border: isDark
                            ? Border.all(
                                color: (p.isLowStock ? AppConstants.alertCrimsonDark : AppConstants.secondaryEmeraldDark)
                                    .withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Text(
                        p.isLowStock ? 'LOW' : p.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: p.isLowStock
                              ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFF93000A))
                              : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      Formatters.formatCurrency(p.sellingPrice),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppConstants.textPrimaryDark : AppConstants.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('•', style: TextStyle(fontSize: 10, color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8))),
                    const SizedBox(width: 6),
                    Text(
                      'Stock: ${p.stock}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.isLowStock
                            ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFFDC2626))
                            : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Add / In-Basket Button
          if (inCartCount > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => posVm.updateQuantity(p.id, -1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? AppConstants.surfaceOverlayDark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? AppConstants.borderInteractiveDark : const Color(0xFFE2E8F0)),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: isDark ? AppConstants.textPrimaryDark : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$inCartCount',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppConstants.textPrimaryDark : null,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => posVm.addToCart(p),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: () => posVm.addToCart(p),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(10),
                  border: isDark ? Border.all(color: AppConstants.borderInteractiveDark) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      size: 16,
                      color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
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

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('beverage') || lower.contains('juice') || lower.contains('drink')) {
      return Icons.local_drink_rounded;
    }
    if (lower.contains('milk') || lower.contains('dairy')) {
      return Icons.egg_rounded;
    }
    if (lower.contains('snack') || lower.contains('biscuit')) {
      return Icons.cookie_rounded;
    }
    if (lower.contains('oil') || lower.contains('spice')) {
      return Icons.soup_kitchen_rounded;
    }
    if (lower.contains('rice') || lower.contains('flour')) {
      return Icons.grain_rounded;
    }
    if (lower.contains('baby')) {
      return Icons.child_friendly_rounded;
    }
    return Icons.shopping_bag_rounded;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            'No matching products',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Try scanning barcode or change filter',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
