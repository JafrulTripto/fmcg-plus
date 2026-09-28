import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/master_product_model.dart';
import '../../view_models/inventory_view_model.dart';
import '../../view_models/app_mode_view_model.dart';
import 'barcode_scanner_view.dart';
import '../../../l10n/app_localizations.dart';

class AddProductSheet extends StatefulWidget {
  final String? initialBarcode;
  final MasterProductModel? masterProduct;

  const AddProductSheet({
    super.key,
    this.initialBarcode,
    this.masterProduct,
  });

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '25');
  final _thresholdCtrl = TextEditingController(text: '5');
  final _wholesalePriceCtrl = TextEditingController();
  final _wholesaleMinQtyCtrl = TextEditingController();

  String _selectedCategory = 'Grocery & Staples';
  String _selectedUnit = 'pcs';
  String _uploadedImageUrl = '';
  bool _enableExpiry = false;
  DateTime? _expiryDate;
  bool _isSaving = false;

  final List<Map<String, String>> _categories = [
    {'name': 'Grocery & Staples', 'emoji': '🌾'},
    {'name': 'Dairy & Eggs', 'emoji': '🧀'},
    {'name': 'Beverages', 'emoji': '🥤'},
    {'name': 'Snacks & Bakery', 'emoji': '🍪'},
    {'name': 'Toiletries', 'emoji': '🧼'},
    {'name': 'Baby Products', 'emoji': '👶'},
  ];

  final List<Map<String, String>> _units = [
    {'code': 'pcs', 'label': 'Pcs / Units', 'bn': 'পিস'},
    {'code': 'kg', 'label': 'Kg', 'bn': 'কেজি'},
    {'code': 'L', 'label': 'Litre', 'bn': 'লিটার'},
    {'code': 'g', 'label': 'Gram', 'bn': 'গ্রাম'},
    {'code': 'pack', 'label': 'Pack', 'bn': 'প্যাকেট'},
    {'code': 'dozen', 'label': 'Box / Dozen', 'bn': 'ডজন'},
  ];

  @override
  void initState() {
    super.initState();
    _skuCtrl.text = 'SKU-${Random().nextInt(90000) + 10000}';

    if (widget.masterProduct != null) {
      final mp = widget.masterProduct!;
      _nameCtrl.text = mp.productName;
      _barcodeCtrl.text = mp.barcode;
      if (mp.sku.isNotEmpty) _skuCtrl.text = mp.sku;
      _priceCtrl.text = mp.suggestedMrp.toStringAsFixed(0);
      _costCtrl.text = mp.suggestedCost.toStringAsFixed(0);
      _selectedUnit = mp.unit.isNotEmpty ? mp.unit.toLowerCase() : 'pcs';
      _uploadedImageUrl = mp.imageUrl;

      // Find matching category
      final matchedCat = _categories.firstWhere(
        (c) => c['name']!.toLowerCase().contains(mp.category.toLowerCase()) || mp.category.toLowerCase().contains(c['name']!.toLowerCase()),
        orElse: () => _categories[0],
      );
      _selectedCategory = matchedCat['name']!;
    } else if (widget.initialBarcode != null) {
      _barcodeCtrl.text = widget.initialBarcode!;
    }

    _costCtrl.addListener(() => setState(() {}));
    _priceCtrl.addListener(() => setState(() {}));
    _stockCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _skuCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    _wholesaleMinQtyCtrl.dispose();
    super.dispose();
  }

  void _generateNewSku() {
    setState(() {
      _skuCtrl.text = 'SKU-${Random().nextInt(90000) + 10000}';
    });
  }

  void _adjustStock(int delta) {
    int current = int.tryParse(_stockCtrl.text) ?? 0;
    int next = (current + delta).clamp(0, 99999);
    _stockCtrl.text = next.toString();
  }

  double get _costPrice => double.tryParse(_costCtrl.text) ?? 0.0;
  double get _sellingPrice => double.tryParse(_priceCtrl.text) ?? 0.0;
  double get _profitPerUnit => _sellingPrice - _costPrice;
  double get _marginPercent => _sellingPrice > 0 ? ((_profitPerUnit / _sellingPrice) * 100) : 0.0;

  Future<void> _handleSave({bool addAnother = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final inventoryVm = context.read<InventoryViewModel>();
    bool success;

    if (widget.masterProduct != null) {
      success = await inventoryVm.onboardMasterProduct(
        masterProduct: widget.masterProduct!,
        costPrice: _costPrice > 0 ? _costPrice : widget.masterProduct!.suggestedCost,
        sellingPrice: _sellingPrice > 0 ? _sellingPrice : widget.masterProduct!.suggestedMrp,
        initialStock: int.tryParse(_stockCtrl.text) ?? 25,
        minThreshold: int.tryParse(_thresholdCtrl.text) ?? 5,
        customName: _nameCtrl.text.trim(),
      );
    } else {
      success = await inventoryVm.addProduct(
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        barcode: _barcodeCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        costPrice: _costPrice,
        sellingPrice: _sellingPrice,
        stock: int.tryParse(_stockCtrl.text) ?? 25,
        minThreshold: int.tryParse(_thresholdCtrl.text) ?? 5,
        unit: _selectedUnit,
        imageUrl: _uploadedImageUrl,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Added "${_nameCtrl.text}" to inventory')),
            ],
          ),
          backgroundColor: AppConstants.secondaryEmerald,
          duration: const Duration(seconds: 2),
        ),
      );

      if (addAnother) {
        _nameCtrl.clear();
        _barcodeCtrl.clear();
        _costCtrl.clear();
        _priceCtrl.clear();
        _stockCtrl.text = '25';
        _thresholdCtrl.text = '5';
        _uploadedImageUrl = '';
        _generateNewSku();
      } else {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save product. Please try again.'),
          backgroundColor: AppConstants.alertCrimson,
        ),
      );
    }
  }

  void _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFromMaster = widget.masterProduct != null;
    final l10n = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF8FF),
          // Persistent Top App Bar
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: Colors.black12,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF131B2E), size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFromMaster
                      ? (l10n?.onboardCatalogItem ?? 'Onboard Catalog Item')
                      : (l10n?.addProduct ?? 'Add Product'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: const Color(0xFF131B2E),
                  ),
                ),
                Text(
                  l10n?.retailCatalog ?? 'FMCG+ Retail Master',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF747686),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _handleSave(addAnother: false),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(l10n?.save ?? 'Save', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0037B0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: Container(
                color: const Color(0xFFE2E7FF),
                height: 2,
                child: Row(
                  children: [
                    Container(width: 120, color: const Color(0xFF0037B0), height: 2),
                  ],
                ),
              ),
            ),
          ),

          // Main Form Body
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Quick Scan Hero Banner (Stitch Screen 1)
                  _buildQuickScanBanner(),
                  const SizedBox(height: 14),

                  // Verified Master Catalog Banner (if applicable)
                  if (isFromMaster) ...[
                    _buildMasterCatalogBanner(),
                    const SizedBox(height: 14),
                  ],

                  // 2. Product Photo Card
                  _buildPhotoCard(),
                  const SizedBox(height: 14),

                  // 3. Section 1: Basic Information
                  _buildBasicInfoSection(),
                  const SizedBox(height: 14),

                  // 4. Section 2: Barcode & Identification
                  _buildBarcodeSkuSection(),
                  const SizedBox(height: 14),

                  // 5. Section 3: Pricing & Profit Margin Calculator
                  _buildPricingSection(),
                  const SizedBox(height: 14),

                  // 6. Section 4: Inventory & Stock Control
                  _buildStockControlSection(),
                  const SizedBox(height: 14),

                  // 7. Shopkeeper Quick Tip Card
                  _buildQuickTipCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Persistent Bottom Fixed Action Bar (Fixed Thumb Zone)
          bottomNavigationBar: _buildBottomActionBar(),
        ),
      ),
    );
  }

  // =========================================================================
  // Section Builders
  // =========================================================================

  Widget _buildQuickScanBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0037B0), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0037B0).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Fill by Barcode',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Scan product box to auto-fill details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _openScanner,
            icon: const Icon(Icons.photo_camera, size: 16),
            label: const Text('Scan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0037B0),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterCatalogBanner() {
    final mp = widget.masterProduct!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF82F5C1).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF006C4A).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xFF006C4A), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recognized FMCG Catalog Item',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF005137),
                  ),
                ),
                Text(
                  'Brand: ${mp.brand} • Pack: ${mp.packSize} • Suggested MRP: ৳${mp.suggestedMrp.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF434655),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF131B2E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'AUTO-COMPRESSED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF434655),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Photo Box
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E7FF)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _uploadedImageUrl.isNotEmpty
                    ? Image.network(
                        _uploadedImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.image, color: Colors.grey, size: 36),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, color: Color(0xFF0037B0), size: 26),
                          const SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF434655),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capture or pick from gallery',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: const Color(0xFF131B2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compressed automatically to preserve mobile storage and speed up receipt printing.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Camera capture ready for photo upload')),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.photo_camera, size: 14, color: Color(0xFF0037B0)),
                              const SizedBox(width: 4),
                              Text(
                                'Take Photo',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0037B0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('•', style: TextStyle(color: Colors.grey)),
                        ),
                        InkWell(
                          onTap: _openScanner,
                          child: Row(
                            children: [
                              const Icon(Icons.grid_view_rounded, size: 14, color: Color(0xFF0037B0)),
                              const SizedBox(width: 4),
                              Text(
                                'Catalog',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0037B0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF0037B0), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(
                'Basic Information',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF131B2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Product Name
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
              children: [
                TextSpan(text: '${AppLocalizations.of(context)?.productName ?? "Product Name"} '),
                const TextSpan(text: '*', style: TextStyle(color: AppConstants.alertCrimson)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'e.g., Aarong Butter 200g, Pran Frooto 250ml',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
              suffixIcon: const Icon(Icons.mic_none, color: Color(0xFF64748B), size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter product name' : null,
          ),
          const SizedBox(height: 14),

          // Category Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
                  children: const [
                    TextSpan(text: 'Category '),
                    TextSpan(text: '*', style: TextStyle(color: AppConstants.alertCrimson)),
                  ],
                ),
              ),
              Text(
                '+ New',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0037B0)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${cat['emoji']} ${cat['name']}'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat['name']!);
                    },
                    selectedColor: const Color(0xFF0037B0),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Unit Type Selector (3-column grid)
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
              children: [
                TextSpan(text: '${AppLocalizations.of(context)?.unitType ?? "Unit Type"} '),
                const TextSpan(text: '*', style: TextStyle(color: AppConstants.alertCrimson)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: _units.length,
            itemBuilder: (ctx, index) {
              final unit = _units[index];
              final isSelected = _selectedUnit == unit['code'];
              final isBangla = context.watch<AppModeViewModel>().isBangla;
              return InkWell(
                onTap: () => setState(() => _selectedUnit = unit['code']!),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0037B0) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0037B0).withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      isBangla ? unit['bn']! : unit['label']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeSkuSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF006C4A), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(
                    'Barcode & SKU',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF131B2E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Optional',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barcode Input
          Text(
            'Barcode (EAN-13 / UPC)',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _barcodeCtrl,
            style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Scan or type barcode',
              hintStyle: GoogleFonts.jetBrainsMono(fontSize: 13, color: const Color(0xFF94A3B8)),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(6),
                child: ElevatedButton.icon(
                  onPressed: _openScanner,
                  icon: const Icon(Icons.photo_camera, size: 14),
                  label: const Text('Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAEDFF),
                    foregroundColor: const Color(0xFF0037B0),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)?.looseItemHint ?? 'Leave blank if selling unbranded or loose items.',
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // SKU input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Custom SKU / Item Code',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
              ),
              InkWell(
                onTap: _generateNewSku,
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 12, color: Color(0xFF0037B0)),
                    const SizedBox(width: 4),
                    Text(
                      'Generate New',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0037B0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _skuCtrl,
            style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(
                'Pricing & Profit',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF131B2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2-Column: Purchase Cost & Selling MRP
          Row(
            children: [
              // Cost Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
                        children: [
                          TextSpan(text: '${l10n?.purchaseCost ?? "Purchase Cost"} '),
                          const TextSpan(text: '*', style: TextStyle(color: AppConstants.alertCrimson)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('৳', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.purchaseCostPerUnit ?? 'Purchase Cost / Unit',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Selling Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
                        children: [
                          TextSpan(text: '${l10n?.sellingMrp ?? "Selling MRP"} '),
                          const TextSpan(text: '*', style: TextStyle(color: AppConstants.alertCrimson)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0037B0)),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('৳', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0037B0))),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.customerSellingPrice ?? 'Customer Selling Price',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Real-time Margin & Profit Calculator Banner (Stitch Screen 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _profitPerUnit >= 0 ? const Color(0xFFD1FAE5).withValues(alpha: 0.6) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _profitPerUnit >= 0 ? const Color(0xFF059669).withValues(alpha: 0.3) : const Color(0xFFDC2626).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _profitPerUnit >= 0 ? const Color(0xFF82F5C1) : const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _profitPerUnit >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: _profitPerUnit >= 0 ? const Color(0xFF006C4A) : const Color(0xFFBA1A1A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED MARGIN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: _profitPerUnit >= 0 ? const Color(0xFF00714E) : const Color(0xFF93000A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${_marginPercent.toStringAsFixed(1)}%',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _profitPerUnit >= 0 ? const Color(0xFF005137) : const Color(0xFFBA1A1A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _profitPerUnit >= 0
                                ? '(+৳${_profitPerUnit.round()} profit/unit)'
                                : '(-৳${(-_profitPerUnit).round()} loss/unit)',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _profitPerUnit >= 0 ? const Color(0xFF006C4A) : const Color(0xFFBA1A1A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  _profitPerUnit >= 0 ? Icons.verified : Icons.warning_amber_rounded,
                  color: _profitPerUnit >= 0 ? const Color(0xFF006C4A) : const Color(0xFFBA1A1A),
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockControlSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF68DBA9), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(
                'Inventory & Stock Control',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF131B2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Initial Stock with Stepper Controls (Stitch Screen 1)
          // Initial Stock
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
              children: [
                TextSpan(text: '${AppLocalizations.of(context)?.initialStock ?? "Initial Stock Quantity"} '),
                const TextSpan(text: '*', style: TextStyle(color: AppConstants.alertCrimson)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Minus button
              InkWell(
                onTap: () => _adjustStock(-1),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.remove, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(width: 8),

              // Stock Text input
              Expanded(
                child: TextFormField(
                  controller: _stockCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Plus button
              InkWell(
                onTap: () => _adjustStock(1),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Low Stock Alert Limit
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131B2E)),
              children: [
                TextSpan(text: '${AppLocalizations.of(context)?.lowStockAlertLimit ?? "Low Stock Alert Limit"} '),
                const TextSpan(text: '*', style: TextStyle(color: AppConstants.alertCrimson)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _thresholdCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.lowStockHint ?? 'Dashboard marks item Low Stock when quantity reaches or drops below this count.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B), height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Expiry Date Alert Toggle Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_available, color: Color(0xFF64748B), size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.expiryDateAlert ?? 'Expiry Date Alert',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              AppLocalizations.of(context)?.trackExpiry ?? 'Track product expiration date',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _enableExpiry,
                      activeColor: const Color(0xFF0037B0),
                      onChanged: (val) => setState(() => _enableExpiry = val),
                    ),
                  ],
                ),
                if (_enableExpiry) ...[
                  const Divider(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setState(() => _expiryDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _expiryDate != null
                                ? Formatters.formatDate(_expiryDate!)
                                : 'Select Expiration Date',
                            style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF0037B0)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF1D4ED8), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shopkeeper Quick Tip',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Adding MRP and Purchase cost enables automated gross profit calculations in your daily Sales Report and Dukandari Ledger.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF1E3A8A),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Save & Add Next
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => _handleSave(addAnother: true),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF1E293B),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    l10n?.saveAndAddNext ?? 'Save & Add Next',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Primary Save CTA
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _handleSave(addAnother: false),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle, size: 20),
                  label: Text(
                    _sellingPrice > 0
                        ? '${l10n?.saveProduct ?? "Save Product"} (৳${_sellingPrice.toStringAsFixed(0)})'
                        : (l10n?.saveProduct ?? 'Save Product'),
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0037B0),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
