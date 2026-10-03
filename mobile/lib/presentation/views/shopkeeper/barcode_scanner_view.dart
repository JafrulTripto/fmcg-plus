import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/master_product_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/scan_result_model.dart';
import '../../view_models/pos_view_model.dart';
import '../../view_models/inventory_view_model.dart';
import 'add_product_sheet.dart';

enum ScannerDockState {
  ready,
  recognized,
  unknown,
  catalogMatch,
}

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _laserController;

  // Resilient, high-compatibility MobileScannerController
  // Omitting fixed cameraResolution & scanWindow fixes Android CameraX initialization issues
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 350,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // Audio player for barcode detection beep
  final AudioPlayer _beepPlayer = AudioPlayer();

  bool _isTorchOn = false;
  bool _isBeepOn = true;
  bool _isProcessingScan = false;

  // Frame stability checking to prevent misreads & wrong numbers
  String? _candidateBarcode;
  int _candidateMatches = 0;
  DateTime _lastCandidateTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastProcessedTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Active state in docked bottom sheet
  ScannerDockState _dockState = ScannerDockState.ready;
  String _activeBarcode = '';
  ProductModel? _activeProduct;
  MasterProductModel? _activeMasterProduct;
  int _productCartQty = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserController.dispose();
    _scannerController.dispose();
    _beepPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reset the processing lock when app resumes to prevent permanent deadlock
    if (state == AppLifecycleState.resumed) {
      _isProcessingScan = false;
      _candidateBarcode = null;
      _candidateMatches = 0;
    }
  }

  void _triggerFeedback() {
    if (_isBeepOn) {
      HapticFeedback.mediumImpact();
      // Play the scanner beep sound asset, falling back to system click
      _beepPlayer.stop().then((_) {
        _beepPlayer.play(AssetSource('sounds/beep.mp3')).catchError((_) {
          SystemSound.play(SystemSoundType.click);
        });
      });
    }
  }

  /// Verifies EAN-13 Modulo-10 checksum to eliminate optically misread digits
  bool _isValidEan13(String code) {
    if (code.length != 13 || !RegExp(r'^\d{13}$').hasMatch(code)) return false;
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final d = int.parse(code[i]);
      sum += (i % 2 == 0) ? d : d * 3;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(code[12]);
  }

  /// Verifies UPC-A Modulo-10 checksum
  bool _isValidUpcA(String code) {
    if (code.length != 12 || !RegExp(r'^\d{12}$').hasMatch(code)) return false;
    int sum = 0;
    for (int i = 0; i < 11; i++) {
      final d = int.parse(code[i]);
      sum += (i % 2 == 0) ? d * 3 : d;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(code[11]);
  }

  /// Barcode capture callback with checksum verification & multi-frame consensus
  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingScan) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim() ?? barcode.displayValue?.trim();
      if (raw == null || raw.isEmpty) continue;

      // Discard noise
      if (raw.length < 4 || raw.length > 36) continue;

      final now = DateTime.now();

      // Fast responsive throttle: 800ms if same barcode, only 250ms if different barcode
      final isSameBarcode = (_activeBarcode == raw);
      final throttleMs = isSameBarcode ? 800 : 250;
      if (now.difference(_lastProcessedTime).inMilliseconds < throttleMs) continue;

      // 1. EAN-13 Checksum verification
      if (raw.length == 13 && RegExp(r'^\d{13}$').hasMatch(raw)) {
        if (!_isValidEan13(raw)) {
          // Checksum mismatch -> optical glare/partial read, wait for next frame
          continue;
        }
        _processScannedBarcode(raw);
        return;
      }

      // 2. UPC-A Checksum verification
      if (raw.length == 12 && RegExp(r'^\d{12}$').hasMatch(raw)) {
        if (!_isValidUpcA(raw)) {
          continue;
        }
        _processScannedBarcode(raw);
        return;
      }

      // 3. Other barcodes (EAN-8, Code 128, Code 39, QR):
      // Require 2 matching consecutive frames to guarantee accuracy
      if (_candidateBarcode == raw && now.difference(_lastCandidateTime).inMilliseconds < 500) {
        _candidateMatches++;
        if (_candidateMatches >= 2) {
          _processScannedBarcode(raw);
          return;
        }
      } else {
        _candidateBarcode = raw;
        _candidateMatches = 1;
        _lastCandidateTime = now;
      }
    }
  }

  void _processScannedBarcode(String code) async {
    if (_isProcessingScan) return;
    _isProcessingScan = true;
    _lastProcessedTime = DateTime.now();
    _candidateBarcode = null;
    _candidateMatches = 0;

    _triggerFeedback();

    try {
      final inventoryVm = context.read<InventoryViewModel>();
      final posVm = context.read<PosViewModel>();

      final result = await inventoryVm.scanBarcodeDetailed(code);
      if (!mounted) return;

      setState(() {
        _activeBarcode = code;
        switch (result.status) {
          case ScanStatus.foundInStore:
            if (result.storeProduct != null) {
              _activeProduct = result.storeProduct;
              _dockState = ScannerDockState.recognized;
              posVm.addToCart(result.storeProduct!);
              _productCartQty = posVm.getItemQuantity(result.storeProduct!.id);
            }
            break;

          case ScanStatus.foundInCatalog:
            if (result.masterProduct != null) {
              _activeMasterProduct = result.masterProduct;
              _dockState = ScannerDockState.catalogMatch;
            }
            break;

          case ScanStatus.unknownBarcode:
            _activeProduct = null;
            _activeMasterProduct = null;
            _dockState = ScannerDockState.unknown;
            break;
        }
      });
    } catch (e) {
      debugPrint('Error processing barcode: $e');
    } finally {
      // Always reset the processing lock unconditionally to prevent deadlock.
      // The flag must be cleared even if the widget is no longer mounted,
      // otherwise the scanner becomes permanently unable to detect barcodes.
      Future.delayed(const Duration(milliseconds: 250), () {
        _isProcessingScan = false;
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _incrementActiveProductQuantity() {
    if (_activeProduct == null) return;
    _triggerFeedback();
    final posVm = context.read<PosViewModel>();
    posVm.addToCart(_activeProduct!);
    setState(() {
      _productCartQty = posVm.getItemQuantity(_activeProduct!.id);
    });
  }

  void _resetToReadyState() {
    _triggerFeedback();
    setState(() {
      _dockState = ScannerDockState.ready;
      _activeBarcode = '';
      _activeProduct = null;
      _activeMasterProduct = null;
      _isProcessingScan = false;
    });
  }

  void _openManualBarcodeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PosManualKeypadModal(
        initialValue: _activeBarcode,
        onSubmit: (barcode) {
          Navigator.pop(ctx);
          _processScannedBarcode(barcode);
        },
      ),
    );
  }

  void _assignBarcodeToExisting() {
    final inventoryVm = context.read<InventoryViewModel>();
    final products = inventoryVm.products;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFFAF8FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Barcode',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF131B2E),
                      ),
                    ),
                    Text(
                      'Linking: $_activeBarcode',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryBlue,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Select a store product to link with this barcode:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF434655),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Text(
                        'No store products available.',
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF747686)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E7FF)),
                      itemBuilder: (c, idx) {
                        final p = products[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E7FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, color: AppConstants.primaryBlue),
                          ),
                          title: Text(
                            p.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF131B2E),
                            ),
                          ),
                          subtitle: Text(
                            'Current Barcode: ${p.barcode.isEmpty ? 'None' : p.barcode}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF747686)),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Assigned barcode $_activeBarcode to ${p.name}'),
                                  backgroundColor: AppConstants.secondaryEmerald,
                                ),
                              );
                              _processScannedBarcode(_activeBarcode);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Link', style: TextStyle(fontSize: 12)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posVm = context.watch<PosViewModel>();
    final screenSize = MediaQuery.of(context).size;

    final reticleWidth = min(screenSize.width * 0.80, 290.0);
    const reticleHeight = 180.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Bright Camera Viewfinder Section
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Live Camera Preview (Clean & Full Brightness)
                  MobileScanner(
                    controller: _scannerController,
                    fit: BoxFit.cover,
                    onDetect: _onDetect,
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
                                'Camera Access: ${error.errorCode.name}\nPlease ensure camera permission is granted in device settings.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // 2. Light Ambient Framing Mask (Transparent inside reticle, soft shading outside)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final centerOffset = Offset(
                        constraints.maxWidth / 2,
                        constraints.maxHeight / 2 - 16,
                      );
                      final scanRect = Rect.fromCenter(
                        center: centerOffset,
                        width: reticleWidth,
                        height: reticleHeight,
                      );

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: _ViewfinderCutoutPainter(
                              cutoutRect: scanRect,
                              overlayColor: Colors.black.withValues(alpha: 0.32),
                            ),
                          ),

                          // Framing Reticle Corners & Laser Beam
                          Positioned(
                            left: scanRect.left,
                            top: scanRect.top,
                            width: scanRect.width,
                            height: scanRect.height,
                            child: Stack(
                              children: [
                                _buildCornerBracket(top: 0, left: 0, isTop: true, isLeft: true),
                                _buildCornerBracket(top: 0, right: 0, isTop: true, isLeft: false),
                                _buildCornerBracket(bottom: 0, left: 0, isTop: false, isLeft: true),
                                _buildCornerBracket(bottom: 0, right: 0, isTop: false, isLeft: false),

                                // Animated Laser Scanning Beam
                                AnimatedBuilder(
                                  animation: _laserController,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: 8 + (_laserController.value * (reticleHeight - 16)),
                                      left: 6,
                                      right: 6,
                                      child: Container(
                                        height: 2.2,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Color(0xFF85F8C4),
                                              Colors.transparent,
                                            ],
                                            stops: [0.0, 0.5, 1.0],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF85F8C4).withValues(alpha: 0.85),
                                              blurRadius: 8,
                                              spreadRadius: 1,
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

                          // Clean Manual Entry Prompt Below Reticle
                          Positioned(
                            top: scanRect.bottom + 14,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: InkWell(
                                onTap: _openManualBarcodeSheet,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.keyboard, size: 16, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Can't scan? Enter manually",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // 3. Clean Minimalist Top App Bar
                  Positioned(
                    top: 10,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.50),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),

                        // Guidance Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Point camera at barcode',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Utilities (Torch, Beep)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () async {
                                try {
                                  await _scannerController.toggleTorch();
                                  setState(() => _isTorchOn = !_isTorchOn);
                                } catch (_) {}
                              },
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _isTorchOn ? const Color(0xFF82F5C1) : Colors.black.withValues(alpha: 0.50),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isTorchOn ? const Color(0xFF00714E) : Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Icon(
                                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                                  color: _isTorchOn ? const Color(0xFF002114) : Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() => _isBeepOn = !_isBeepOn);
                              },
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.50),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: Icon(
                                  _isBeepOn ? Icons.volume_up : Icons.volume_off,
                                  color: _isBeepOn ? const Color(0xFF85F8C4) : Colors.white54,
                                  size: 19,
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

            // DOCKED BOTTOM SHEET
            _buildDockedBottomSheet(posVm),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Color(0xFF1D4ED8), width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Color(0xFF1D4ED8), width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFF1D4ED8), width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Color(0xFF1D4ED8), width: 3) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: (isTop && isLeft) ? const Radius.circular(8) : Radius.zero,
            topRight: (isTop && !isLeft) ? const Radius.circular(8) : Radius.zero,
            bottomLeft: (!isTop && isLeft) ? const Radius.circular(8) : Radius.zero,
            bottomRight: (!isTop && !isLeft) ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildDockedBottomSheet(PosViewModel posVm) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFC4C5D7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),

          // Dynamic state
          if (_dockState == ScannerDockState.recognized)
            _buildRecognizedProductView(posVm)
          else if (_dockState == ScannerDockState.unknown)
            _buildUnknownProductView()
          else if (_dockState == ScannerDockState.catalogMatch)
            _buildCatalogMatchView()
          else
            _buildReadyScanView(),
        ],
      ),
    );
  }

  // CASE A: RECOGNIZED PRODUCT
  Widget _buildRecognizedProductView(PosViewModel posVm) {
    final product = _activeProduct;
    final name = product?.name ?? 'Store Product';
    final price = product?.sellingPrice ?? 0.0;
    final stock = product?.stock ?? 0;
    final shelf = product?.shelfLocation.isNotEmpty == true ? product!.shelfLocation : 'General Shelf';
    final category = product?.category.isNotEmpty == true ? product!.category : 'FMCG';
    final currentQty = product != null ? posVm.getItemQuantity(product.id) : _productCartQty;
    final effectiveQty = currentQty > 0 ? currentQty : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006C4A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Product Recognized',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'EAN: $_activeBarcode',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF434655),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 58,
                  height: 58,
                  color: const Color(0xFFDAE2FD),
                  child: product?.imageUrl.isNotEmpty == true
                      ? Image.network(
                          product!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            color: AppConstants.primaryBlue,
                            size: 26,
                          ),
                        )
                      : const Icon(Icons.inventory_2_outlined, color: AppConstants.primaryBlue, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF131B2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '৳${price.toStringAsFixed(0)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF85F8C4).withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'IN STOCK: $stock',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF005137),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$category • $shelf',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF434655),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart_checkout, size: 14, color: Color(0xFF006C4A)),
                        const SizedBox(width: 4),
                        Text(
                          'Added to Cart! (Qty: $effectiveQty)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF006C4A),
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

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _incrementActiveProductQuantity,
                  icon: const Icon(Icons.add_circle, size: 19),
                  label: Text(
                    'Add Another +',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2E7FF),
                    foregroundColor: const Color(0xFF131B2E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.shopping_bag, size: 19),
                  label: Text(
                    'View Cart (${posVm.totalItemCount})',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sync, size: 14, color: AppConstants.primaryBlue),
            const SizedBox(width: 6),
            Text(
              'Ready for next item. Keep barcode in frame.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF434655)),
            ),
          ],
        ),
      ],
    );
  }

  // CASE B: UNKNOWN BARCODE ALERT
  Widget _buildUnknownProductView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDAD6).withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFDAD6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFBA1A1A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Barcode Not Found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF93000A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBB0112),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEW ITEM',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF434655),
                        ),
                        children: [
                          const TextSpan(text: 'Code '),
                          TextSpan(
                            text: _activeBarcode,
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF131B2E),
                            ),
                          ),
                          const TextSpan(text: ' is not mapped to any inventory item.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    useSafeArea: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddProductSheet(initialBarcode: _activeBarcode),
                  );
                },
                icon: const Icon(Icons.add_box, size: 19),
                label: Text(
                  '+ Add New Product with this Barcode',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _assignBarcodeToExisting,
                icon: const Icon(Icons.link, size: 18),
                label: Text(
                  'Assign Barcode to Existing Product',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2E7FF),
                  foregroundColor: const Color(0xFF131B2E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: TextButton.icon(
                onPressed: _resetToReadyState,
                icon: const Icon(Icons.replay, size: 15, color: Color(0xFF434655)),
                label: Text(
                  'Rescan or Skip',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF434655)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // CASE C: MASTER FMCG CATALOG MATCH
  Widget _buildCatalogMatchView() {
    final mp = _activeMasterProduct;
    final name = mp?.productName ?? 'FMCG Catalog Product';
    final brand = mp?.brand ?? 'Master Catalog';
    final mrp = mp?.suggestedMrp ?? 0.0;
    final pack = mp?.packSize ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppConstants.secondaryEmerald,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'FMCG Catalog Matched',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'EAN: $_activeBarcode',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF434655),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 56,
                  height: 56,
                  color: const Color(0xFFDAE2FD),
                  child: mp?.imageUrl.isNotEmpty == true
                      ? Image.network(
                          mp!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2,
                            color: AppConstants.primaryBlue,
                            size: 26,
                          ),
                        )
                      : const Icon(Icons.inventory_2, color: AppConstants.primaryBlue, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF131B2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Brand: $brand • $pack',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF434655)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Suggested MRP: ৳${mrp.toStringAsFixed(0)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (mp != null) {
                      showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddProductSheet(masterProduct: mp),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(
                    'Auto-fill & Stock Item',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.secondaryEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              child: TextButton.icon(
                onPressed: _resetToReadyState,
                icon: const Icon(Icons.replay, size: 15),
                label: const Text('Rescan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // CASE D: INITIAL READY / SCAN VIEW
  Widget _buildReadyScanView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: AppConstants.primaryBlue, size: 22),
                const SizedBox(width: 8),
                Text(
                  'POS Barcode Scanner',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF85F8C4).withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'READY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF005137),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Point camera at any product barcode. Scanned items are identified and added to the cart automatically.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF434655),
          ),
        ),
        const SizedBox(height: 12),
        // Quick Test Buttons (Clean and compact)
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _processScannedBarcode('894110023419'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('⚡ Test Pran (Known)', style: TextStyle(fontSize: 11.5)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _processScannedBarcode('890103082910'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('⚡ Test Unknown', style: TextStyle(fontSize: 11.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CLEAN VIEWFINDER CUTOUT MASK
// ---------------------------------------------------------------------------
class _ViewfinderCutoutPainter extends CustomPainter {
  final Rect cutoutRect;
  final Color overlayColor;

  _ViewfinderCutoutPainter({
    required this.cutoutRect,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(10)));

    final path = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderCutoutPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect || oldDelegate.overlayColor != overlayColor;
  }
}

// ---------------------------------------------------------------------------
// POS MANUAL BARCODE KEYPAD MODAL
// ---------------------------------------------------------------------------
class _PosManualKeypadModal extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSubmit;

  const _PosManualKeypadModal({
    required this.initialValue,
    required this.onSubmit,
  });

  @override
  State<_PosManualKeypadModal> createState() => _PosManualKeypadModalState();
}

class _PosManualKeypadModalState extends State<_PosManualKeypadModal> {
  late String _currentCode;

  @override
  void initState() {
    super.initState();
    _currentCode = widget.initialValue;
  }

  void _pressDigit(String digit) {
    HapticFeedback.lightImpact();
    setState(() => _currentCode += digit);
  }

  void _backspace() {
    HapticFeedback.lightImpact();
    if (_currentCode.isNotEmpty) {
      setState(() => _currentCode = _currentCode.substring(0, _currentCode.length - 1));
    }
  }

  void _clear() {
    HapticFeedback.lightImpact();
    setState(() => _currentCode = '');
  }

  void _appendPreset(String code) {
    HapticFeedback.lightImpact();
    setState(() => _currentCode = code);
  }

  void _submit() {
    if (_currentCode.trim().isNotEmpty) {
      HapticFeedback.mediumImpact();
      widget.onSubmit(_currentCode.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.dialpad, color: AppConstants.primaryBlue, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Enter Barcode Digitally',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF131B2E),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF434655)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _currentCode.isEmpty ? 'Type or paste barcode...' : _currentCode,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: _currentCode.isEmpty ? const Color(0xFF747686) : const Color(0xFF131B2E),
                    ),
                  ),
                ),
                if (_currentCode.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.backspace_outlined, size: 20, color: Color(0xFF434655)),
                    onPressed: _backspace,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                'QUICK CODES:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF747686),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickCodeChip('894110023419'),
                      const SizedBox(width: 6),
                      _buildQuickCodeChip('890103082910'),
                      const SizedBox(width: 6),
                      _buildQuickCodeChip('8941100100011'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Column(
            children: [
              Row(
                children: [
                  _buildKeypadButton('1'),
                  const SizedBox(width: 8),
                  _buildKeypadButton('2'),
                  const SizedBox(width: 8),
                  _buildKeypadButton('3'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildKeypadButton('4'),
                  const SizedBox(width: 8),
                  _buildKeypadButton('5'),
                  const SizedBox(width: 8),
                  _buildKeypadButton('6'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildKeypadButton('7'),
                  const SizedBox(width: 8),
                  _buildKeypadButton('8'),
                  const SizedBox(width: 8),
                  _buildKeypadButton('9'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _clear,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEAEDFF),
                          foregroundColor: const Color(0xFFBA1A1A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'C',
                          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildKeypadButton('0'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Icon(Icons.check, size: 24, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCodeChip(String code) {
    return InkWell(
      onTap: () => _appendPreset(code),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E7FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          code,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF131B2E),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Expanded(
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () => _pressDigit(digit),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE2E7FF),
            foregroundColor: const Color(0xFF131B2E),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            digit,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF131B2E),
            ),
          ),
        ),
      ),
    );
  }
}
