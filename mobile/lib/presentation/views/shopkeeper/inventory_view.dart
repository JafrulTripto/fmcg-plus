import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../view_models/inventory_view_model.dart';
import '../../widgets/status_badge.dart';
import 'add_product_sheet.dart';
import 'stock_adjust_dialog.dart';
import 'barcode_scanner_view.dart';

class InventoryView extends StatelessWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryVm = context.watch<InventoryViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final lowStockCount = inventoryVm.products.where((p) => p.isLowStock).length;
    final outOfStockCount = inventoryVm.products.where((p) => p.isOutOfStock).length;
    final healthyCount = inventoryVm.products.where((p) => !p.isLowStock && !p.isOutOfStock).length;

    final totalValuation = inventoryVm.products.fold(
      0.0,
      (sum, p) => sum + (p.costPrice > 0 ? p.costPrice : p.sellingPrice * 0.8) * p.stock,
    );

    return RefreshIndicator(
      onRefresh: () async {
        await inventoryVm.loadProducts();
      },
      child: Column(
        children: [
          // Stock Valuation & Health Banner (Stitch Spec: 2_Inventory_Management_b74bfa9e)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              children: [
                // Valuation Card
                Container(
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
                            'TOTAL STOCK VALUATION',
                            style: isDark
                                ? GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppConstants.textMutedDark,
                                    letterSpacing: 0.6,
                                  )
                                : GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.6,
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFDCE1FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${inventoryVm.products.length} SKUs ACTIVE',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            Formatters.formatCurrency(totalValuation),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF0F172A),
                            ),
                          ),
                          if (inventoryVm.products.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Live Catalog',
                                  style: isDark
                                      ? GoogleFonts.spaceGrotesk(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppConstants.secondaryEmeraldDark,
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppConstants.secondaryEmerald,
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Health Meters (3-Grid)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppConstants.dueAmberDark.withValues(alpha: 0.12)
                                    : const Color(0xFFFFDAD6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: isDark ? AppConstants.dueAmberDark : const Color(0xFFDC2626),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'LOW STOCK',
                                        style: isDark
                                            ? GoogleFonts.spaceGrotesk(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: AppConstants.dueAmberDark,
                                              )
                                            : GoogleFonts.plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF93000A),
                                              ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$lowStockCount',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppConstants.dueAmberDark : const Color(0xFF93000A),
                                    ),
                                  ),
                                  Text(
                                    'Needs order',
                                    style: isDark
                                        ? GoogleFonts.spaceGrotesk(fontSize: 9, color: AppConstants.dueAmberDark)
                                        : GoogleFonts.plusJakartaSans(fontSize: 9, color: const Color(0xFF93000A)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppConstants.alertCrimsonDark.withValues(alpha: 0.12)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFF64748B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'OUT STOCK',
                                        style: isDark
                                            ? GoogleFonts.spaceGrotesk(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: AppConstants.alertCrimsonDark,
                                              )
                                            : GoogleFonts.plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF434655),
                                              ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$outOfStockCount',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppConstants.alertCrimsonDark : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Loss risk',
                                    style: isDark
                                        ? GoogleFonts.spaceGrotesk(fontSize: 9, color: AppConstants.alertCrimsonDark)
                                        : GoogleFonts.plusJakartaSans(fontSize: 9, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppConstants.secondaryEmeraldDark.withValues(alpha: 0.12)
                                    : const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'HEALTHY',
                                        style: isDark
                                            ? GoogleFonts.spaceGrotesk(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: AppConstants.secondaryEmeraldDark,
                                              )
                                            : GoogleFonts.plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF065F46),
                                              ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$healthyCount',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF065F46),
                                    ),
                                  ),
                                  Text(
                                    'Optimal tier',
                                    style: isDark
                                        ? GoogleFonts.spaceGrotesk(fontSize: 9, color: AppConstants.secondaryEmeraldDark)
                                        : GoogleFonts.plusJakartaSans(fontSize: 9, color: const Color(0xFF065F46)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Quick Action Dual Triggers (Stitch Spec)
                Row(
                  children: [
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue).withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '+ Add Product',
                                style: isDark
                                    ? GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                                    : GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppConstants.surfaceDark : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: const [
                              BoxShadow(color: Color(0x060F172A), blurRadius: 2, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Scan Barcode',
                                style: isDark
                                    ? GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppConstants.textPrimaryDark,
                                      )
                                    : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
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

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
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
                      onChanged: inventoryVm.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search product, barcode, SKU...',
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
              ],
            ),
          ),

          // Filter Pills
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(context, 'All Stock', 'all', inventoryVm, isDark),
                  const SizedBox(width: 6),
                  _buildFilterChip(context, 'Low Stock', 'low_stock', inventoryVm, isDark),
                  const SizedBox(width: 6),
                  _buildFilterChip(context, 'Out of Stock', 'out_of_stock', inventoryVm, isDark),
                ],
              ),
            ),
          ),

          // Inventory List
          Expanded(
            child: inventoryVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : inventoryVm.filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 40,
                              color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No products match filter',
                              style: isDark
                                  ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14, color: AppConstants.textPrimaryDark)
                                  : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
                        itemCount: inventoryVm.filteredProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = inventoryVm.filteredProducts[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppConstants.surfaceDark : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: const [
                                BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              p.category,
                                              style: isDark
                                                  ? GoogleFonts.spaceGrotesk(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppConstants.textSecondaryDark,
                                                    )
                                                  : GoogleFonts.plusJakartaSans(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: const Color(0xFF434655),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            p.barcode.isNotEmpty ? p.barcode : p.sku,
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 10,
                                              color: isDark ? AppConstants.textMutedDark : const Color(0xFF747686),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p.name,
                                        style: isDark
                                            ? GoogleFonts.spaceGrotesk(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppConstants.textPrimaryDark,
                                              )
                                            : GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            Formatters.formatCurrency(p.sellingPrice),
                                            style: GoogleFonts.spaceGrotesk(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: isDark ? AppConstants.primaryBlueDark : AppConstants.primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Cost: ${Formatters.formatCurrency(p.costPrice)}',
                                            style: isDark
                                                ? GoogleFonts.spaceGrotesk(fontSize: 11, color: AppConstants.textMutedDark)
                                                : GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    StatusBadge(
                                      label: '${p.stock} ${p.unit} left',
                                      type: p.isOutOfStock
                                          ? BadgeType.alert
                                          : (p.isLowStock ? BadgeType.warning : BadgeType.success),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => StockAdjustDialog(product: p),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppConstants.primaryBlueDark.withValues(alpha: 0.15)
                                              : const Color(0xFFEAEDFF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Adjust',
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String filter, InventoryViewModel vm, bool isDark) {
    final isSelected = vm.stockFilter == filter;
    return InkWell(
      onTap: () => vm.setStockFilter(filter),
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
}

