import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/master_product_model.dart';
import '../../../data/models/scan_result_model.dart';
import '../../view_models/pos_view_model.dart';
import '../../view_models/inventory_view_model.dart';
import 'add_product_sheet.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _isTorchOn = false;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _resumeScanning() {
    if (mounted) {
      setState(() => _isProcessingScan = false);
    }
  }

  void _handleBarcodeScanned(String barcode) async {
    if (_isProcessingScan) return;
    setState(() => _isProcessingScan = true);

    final inventoryVm = context.read<InventoryViewModel>();
    final posVm = context.read<PosViewModel>();

    final result = await inventoryVm.scanBarcodeDetailed(barcode);

    if (!mounted) return;

    switch (result.status) {
      case ScanStatus.foundInStore:
        if (result.storeProduct != null) {
          posVm.addToCart(result.storeProduct!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Added to basket: ${result.storeProduct!.name}')),
                ],
              ),
              backgroundColor: AppConstants.secondaryEmerald,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
        break;

      case ScanStatus.foundInCatalog:
        if (result.masterProduct != null) {
          _showFoundInCatalogDialog(result.masterProduct!);
        }
        break;

      case ScanStatus.unknownBarcode:
        _showUnknownProductDialog(barcode);
        break;
    }
  }

  void _showFoundInCatalogDialog(MasterProductModel masterProduct) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppConstants.secondaryEmerald),
            SizedBox(width: 8),
            Text('FMCG Catalog Matched', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This product is recognized in the Bangladesh FMCG Master Catalog, but not yet stocked in your store.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  if (masterProduct.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        masterProduct.imageUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory_2, size: 36, color: Colors.grey),
                      ),
                    )
                  else
                    const Icon(Icons.inventory_2, size: 36, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          masterProduct.productName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Brand: ${masterProduct.brand} • ${masterProduct.packSize}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          'Suggested MRP: ৳${masterProduct.suggestedMrp.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppConstants.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // close scanner
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddProductSheet(masterProduct: masterProduct),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.secondaryEmerald,
              foregroundColor: Colors.white,
            ),
            child: const Text('Auto-fill & Stock Item'),
          ),
        ],
      ),
    ).then((_) => _resumeScanning());
  }

  void _showUnknownProductDialog(String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.search_off, color: AppConstants.dueAmber),
            SizedBox(width: 8),
            Text('Unknown Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This barcode is not recognized in your store inventory or the FMCG master catalog.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Barcode: $barcode',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // close scanner
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddProductSheet(initialBarcode: barcode),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Product Now'),
          ),
        ],
      ),
    ).then((_) => _resumeScanning());
  }

  void _openManualBarcodeSheet() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enter Barcode Manually', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '13-digit EAN / UPC Barcode',
                  hintText: 'e.g. 8941100100011',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final code = textController.text.trim();
                  if (code.isNotEmpty) {
                    Navigator.pop(ctx);
                    _handleBarcodeScanned(code);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Search & Process Barcode', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Live Mobile Scanner Camera Feed
            Positioned.fill(
              child: MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  if (_isProcessingScan) return;
                  final barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final code = barcode.rawValue;
                    if (code != null && code.trim().isNotEmpty) {
                      _handleBarcodeScanned(code.trim());
                      break;
                    }
                  }
                },
                errorBuilder: (context, error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Camera Error: ${error.errorCode.name}\nPlease grant camera permission in Android settings or enter barcode manually.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Subtle dark overlay to highlight the scan reticle
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),

            // Scanner Reticle Overlay
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Scanner Reticle Box
                  Container(
                    width: 280,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Reticle Corners
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppConstants.secondaryEmerald, width: 4),
                                left: BorderSide(color: AppConstants.secondaryEmerald, width: 4),
                              ),
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppConstants.secondaryEmerald, width: 4),
                                right: BorderSide(color: AppConstants.secondaryEmerald, width: 4),
                              ),
                              borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppConstants.secondaryEmerald, width: 4),
                                left: BorderSide(color: AppConstants.secondaryEmerald, width: 4),
                              ),
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppConstants.secondaryEmerald, width: 4),
                                right: BorderSide(color: AppConstants.secondaryEmerald, width: 4),
                              ),
                              borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
                            ),
                          ),
                        ),

                        // Animated Laser Scan Line
                        AnimatedBuilder(
                          animation: _laserController,
                          builder: (context, child) {
                            return Positioned(
                              top: _laserController.value * 230,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppConstants.secondaryEmerald,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppConstants.secondaryEmerald.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Align Barcode within Frame',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Supports EAN-13, UPC-A, Code-128',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 14),

                  // Manual Keypad Entry Button (Stitch Screen 5)
                  TextButton.icon(
                    onPressed: _openManualBarcodeSheet,
                    icon: const Icon(Icons.keyboard, color: Colors.white, size: 18),
                    label: const Text(
                      "Can't scan? Enter barcode manually",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ],
              ),
            ),

            // Top Bar Controls
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(backgroundColor: Colors.black45),
                  ),
                  const Text(
                    'POS Barcode Scanner',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: _isTorchOn ? AppConstants.dueAmber : Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        await _scannerController.toggleTorch();
                        setState(() => _isTorchOn = !_isTorchOn);
                      } catch (_) {}
                    },
                    style: IconButton.styleFrom(backgroundColor: Colors.black45),
                  ),
                ],
              ),
            ),

            // Bottom 3-State Hardware Test Simulators
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  const Text(
                    '3-State Barcode Simulation Triggers:',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleBarcodeScanned('8941100100011'), // Aarong Milk (In Store)
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text('1. In Store', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.secondaryEmerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            minimumSize: const Size(0, 42),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleBarcodeScanned('8941100511862'), // Radhuni Falooda (Master Catalog)
                          icon: const Icon(Icons.verified, size: 14),
                          label: const Text('2. Catalog', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            minimumSize: const Size(0, 42),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleBarcodeScanned('8941999888123'), // Unknown Code
                          icon: const Icon(Icons.help_outline, size: 14),
                          label: const Text('3. Unknown', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.alertCrimson,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            minimumSize: const Size(0, 42),
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
    );
  }
}
