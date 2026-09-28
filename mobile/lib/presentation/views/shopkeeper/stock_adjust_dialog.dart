import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../view_models/inventory_view_model.dart';
import '../../../l10n/app_localizations.dart';

class StockAdjustDialog extends StatefulWidget {
  final ProductModel product;

  const StockAdjustDialog({super.key, required this.product});

  @override
  State<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<StockAdjustDialog> {
  String _selectedReason = 'restock';
  final _qtyCtrl = TextEditingController(text: '10');
  final _notesCtrl = TextEditingController();
  bool _isApplying = false;

  final List<Map<String, dynamic>> _reasons = [
    {
      'id': 'restock',
      'label': 'Goods Inward',
      'sub': '+ New delivery',
      'icon': Icons.add_business_rounded,
      'color': Color(0xFF006C4A),
    },
    {
      'id': 'damaged',
      'label': 'Damaged / Expired',
      'sub': '- Stock loss',
      'icon': Icons.remove_shopping_cart_rounded,
      'color': Color(0xFFBA1A1A),
    },
    {
      'id': 'return',
      'label': 'Customer Return',
      'sub': '+ Returned item',
      'icon': Icons.assignment_return_rounded,
      'color': Color(0xFF0037B0),
    },
    {
      'id': 'correction',
      'label': 'Audit Correction',
      'sub': 'Count adjustment',
      'icon': Icons.edit_note_rounded,
      'color': Color(0xFFD97706),
    },
  ];

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _adjustQty(int delta) {
    int current = int.tryParse(_qtyCtrl.text) ?? 0;
    int next = (current + delta).clamp(1, 99999);
    setState(() => _qtyCtrl.text = next.toString());
  }

  void _setQtyPreset(int amount) {
    setState(() => _qtyCtrl.text = amount.toString());
  }

  void _confirm() async {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0) return;

    setState(() => _isApplying = true);
    final inventoryVm = context.read<InventoryViewModel>();
    final success = await inventoryVm.adjustStock(
      productId: widget.product.id,
      adjustedQty: qty,
      reason: _selectedReason,
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isApplying = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Stock updated for ${widget.product.name}')),
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
    final p = widget.product;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isDark ? const BorderSide(color: AppConstants.borderDark) : BorderSide.none,
      ),
      backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
                        l10n?.adjustStockLevel ?? 'Adjust Stock Level',
                        style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
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

              // Product Info Preview Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceOverlayDark : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '${l10n?.currentStock ?? "Current Stock"}: ',
                                style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                                  fontSize: 11,
                                  color: isDark ? AppConstants.textMutedDark : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '${p.stock} ${p.unit}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: p.isLowStock
                                      ? (isDark ? AppConstants.alertCrimsonDark : AppConstants.alertCrimson)
                                      : (isDark ? AppConstants.secondaryEmeraldDark : AppConstants.secondaryEmerald),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: p.isLowStock
                                      ? (isDark ? const Color(0xFF3B1219) : const Color(0xFFFFDAD6))
                                      : (isDark ? const Color(0xFF063321) : const Color(0xFFD1FAE5)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.isLowStock ? 'LOW STOCK' : 'NORMAL',
                                  style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: p.isLowStock
                                        ? (isDark ? AppConstants.alertCrimsonDark : const Color(0xFF93000A))
                                        : (isDark ? AppConstants.secondaryEmeraldDark : const Color(0xFF00714E)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Adjustment Reason Grid
              Text(
                l10n?.adjustmentReason ?? 'Adjustment Reason',
                style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.3,
                ),
                itemCount: _reasons.length,
                itemBuilder: (ctx, index) {
                  final reason = _reasons[index];
                  final isSelected = _selectedReason == reason['id'];
                  return InkWell(
                    onTap: () => setState(() => _selectedReason = reason['id'] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0))
                            : (isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppConstants.primaryBlueDark : const Color(0xFF0037B0))
                              : (isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            reason['icon'] as IconData,
                            size: 18,
                            color: isSelected ? Colors.white : (reason['color'] as Color),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  reason['label'] as String,
                                  style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E)),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  reason['sub'] as String,
                                  style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                                    fontSize: 9,
                                    color: isSelected
                                        ? Colors.white70
                                        : (isDark ? AppConstants.textMutedDark : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Quantity Stepper
              Text(
                l10n?.quantityToAdjust ?? 'Quantity to Adjust',
                style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: () => _adjustQty(-1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: isDark ? Border.all(color: AppConstants.borderDark) : null,
                      ),
                      child: Icon(Icons.remove, color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppConstants.textPrimaryDark : Colors.black,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppConstants.borderDark : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _adjustQty(1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: isDark ? Border.all(color: AppConstants.borderDark) : null,
                      ),
                      child: Icon(Icons.add, color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Rapid Quantity Preset Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [5, 10, 25, 50].map((preset) {
                  return InkWell(
                    onTap: () => _setQtyPreset(preset),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceElevatedDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: isDark ? Border.all(color: AppConstants.borderDark) : null,
                      ),
                      child: Text(
                        '+$preset',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppConstants.primaryBlueDark : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Notes Input
              Text(
                l10n?.notesReferenceOptional ?? 'Notes / Reference (Optional)',
                style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppConstants.textPrimaryDark : const Color(0xFF131B2E),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtrl,
                style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                  fontSize: 13,
                  color: isDark ? AppConstants.textPrimaryDark : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g., Supplier delivery memo #482',
                  hintStyle: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                    fontSize: 12,
                    color: isDark ? AppConstants.textMutedDark : const Color(0xFF94A3B8),
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
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Actions
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
                          foregroundColor: isDark ? AppConstants.textMutedDark : const Color(0xFF475569),
                          side: isDark ? const BorderSide(color: AppConstants.borderDark) : BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          l10n?.cancel ?? 'Cancel',
                          style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
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
                        onPressed: _isApplying ? null : _confirm,
                        icon: _isApplying
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          l10n?.applyAdjustment ?? 'Apply Adjustment',
                          style: (isDark ? GoogleFonts.spaceGrotesk : GoogleFonts.plusJakartaSans)(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
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
    );
  }
}
