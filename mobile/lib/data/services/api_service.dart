import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/utils/uuid_util.dart';
import '../models/product_model.dart';
import '../models/master_product_model.dart';
import '../models/scan_result_model.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../models/dashboard_model.dart';
import 'auth_service.dart';

class ApiService {
  String get baseUrl => AppConstants.effectiveApiBaseUrl;

  // Dashboard
  Future<DashboardModel> getDashboard() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/dashboard')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return DashboardModel.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('API getDashboard fallback to local: $e');
    }
    // Blank-slate operational fallback
    return DashboardModel(
      todaySales: 0.0,
      yesterdaySales: 0.0,
      growthPercent: 0.0,
      todayOrders: 0,
      khataDues: 0.0,
      pendingDebtors: 0,
      lowStockCount: 0,
      estProfit: 0.0,
      netMarginPercent: 0.0,
    );
  }

  static List<ProductModel>? _cachedAssetProducts;

  Future<List<ProductModel>> _loadAssetProducts() async {
    if (_cachedAssetProducts != null && _cachedAssetProducts!.isNotEmpty) {
      return _cachedAssetProducts!;
    }
    try {
      final jsonStr = await rootBundle.loadString('assets/data/products.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedAssetProducts = list.map((e) {
        final m = e as Map<String, dynamic>;
        return ProductModel(
          id: m['id']?.toString() ?? '',
          name: m['name']?.toString() ?? '',
          category: m['category']?.toString() ?? 'Food',
          brand: m['brand']?.toString() ?? '',
          packSize: m['pack']?.toString() ?? '',
          unit: m['unit']?.toString() ?? 'pcs',
          costPrice: (m['cost'] as num?)?.toDouble() ?? 50.0,
          sellingPrice: (m['price'] as num?)?.toDouble() ?? 60.0,
          stock: (m['stock'] as num?)?.toInt() ?? 10,
          minThreshold: (m['min'] as num?)?.toInt() ?? 5,
          barcode: m['barcode']?.toString() ?? '',
          sku: m['sku']?.toString() ?? '',
          imageUrl: m['image']?.toString() ?? '',
          shelfLocation: m['shelf']?.toString() ?? '',
          isStocked: m['is_stocked'] as bool? ?? true,
        );
      }).toList();
      return _cachedAssetProducts!;
    } catch (e) {
      debugPrint('Asset products loader fallback: $e');
      return _getLocalInitialProducts(null, null, null);
    }
  }

  static List<MasterProductModel>? _cachedMasterProducts;

  Future<List<MasterProductModel>> _loadMasterProducts() async {
    if (_cachedMasterProducts != null && _cachedMasterProducts!.isNotEmpty) {
      return _cachedMasterProducts!;
    }
    try {
      final jsonStr = await rootBundle.loadString('assets/data/master_products.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedMasterProducts = list.map((e) => MasterProductModel.fromJson(e as Map<String, dynamic>)).toList();
      return _cachedMasterProducts!;
    } catch (e) {
      debugPrint('Asset master products loader error: $e');
      return [];
    }
  }

  static List<CustomerModel>? _cachedAssetCustomers;

  Future<List<CustomerModel>> _loadAssetCustomers() async {
    if (_cachedAssetCustomers != null && _cachedAssetCustomers!.isNotEmpty) {
      return _cachedAssetCustomers!;
    }
    try {
      final jsonStr = await rootBundle.loadString('assets/data/customers.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedAssetCustomers = list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
      return _cachedAssetCustomers!;
    } catch (e) {
      debugPrint('Asset customers loader error: $e');
      return [];
    }
  }

  // Products
  Future<List<ProductModel>> getProducts({String? search, String? category, String? stockFilter}) async {
    try {
      var uri = Uri.parse('$baseUrl/products').replace(queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty && category != 'All') 'category': category,
        if (stockFilter != null && stockFilter.isNotEmpty) 'stock_filter': stockFilter,
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['products'] as List<dynamic>? ?? [];
        return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('API getProducts fallback: $e');
    }

    try {
      final assetList = await _loadAssetProducts();
      var filtered = assetList;
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        filtered = filtered.where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.barcode.contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q)
        ).toList();
      }
      if (category != null && category.isNotEmpty && category != 'All') {
        filtered = filtered.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
      }
      if (stockFilter == 'low') {
        filtered = filtered.where((p) => p.stock <= p.minThreshold).toList();
      } else if (stockFilter == 'out') {
        filtered = filtered.where((p) => p.stock == 0).toList();
      }
      return filtered;
    } catch (_) {
      return _getLocalInitialProducts(search, category, stockFilter);
    }
  }

  // Barcode Scan (Basic)
  Future<ProductModel?> scanBarcode(String barcode) async {
    final result = await scanBarcodeDetailed(barcode);
    if (result.status == ScanStatus.foundInStore) {
      return result.storeProduct;
    }
    return null;
  }

  // 3-State Barcode Resolution Pipeline
  Future<ScanResultModel> scanBarcodeDetailed(String barcode) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/products/scan/$barcode')).timeout(const Duration(seconds: 3));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return ScanResultModel.fromJson(body, barcode);
    } catch (e) {
      debugPrint('API scanBarcodeDetailed network fallback: $e');
    }

    // Offline Fallback Resolution
    // 1. Check if stocked in store inventory
    try {
      final assetList = await _loadAssetProducts();
      for (final p in assetList) {
        if (p.barcode == barcode && p.isStocked) {
          return ScanResultModel(
            status: ScanStatus.foundInStore,
            barcode: barcode,
            storeProduct: p,
            message: 'Found on shelf in store inventory',
          );
        }
      }
    } catch (_) {}

    // 2. Check if recognized in Bangladesh Master FMCG Catalog
    try {
      final masterList = await _loadMasterProducts();
      for (final mp in masterList) {
        if (mp.barcode == barcode) {
          return ScanResultModel(
            status: ScanStatus.foundInCatalog,
            barcode: barcode,
            masterProduct: mp,
            message: 'Recognized in Bangladesh FMCG Catalog',
            canOnboard: true,
            canRegister: true,
          );
        }
      }
    } catch (_) {}

    // 3. Unknown barcode
    return ScanResultModel(
      status: ScanStatus.unknownBarcode,
      barcode: barcode,
      message: 'Unrecognized product barcode',
      canRegister: true,
    );
  }

  // Canonical Master FMCG Catalog
  Future<List<MasterProductModel>> getMasterProducts({String? search, String? category}) async {
    try {
      var uri = Uri.parse('$baseUrl/master-catalog').replace(queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty && category != 'All') 'category': category,
        'limit': '100',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['master_products'] as List<dynamic>? ?? [];
        return list.map((e) => MasterProductModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('API getMasterProducts fallback: $e');
    }

    final masterList = await _loadMasterProducts();
    return masterList.where((mp) {
      if (search != null && search.isNotEmpty) {
        final match = mp.productName.toLowerCase().contains(search.toLowerCase()) ||
            mp.barcode.contains(search);
        if (!match) return false;
      }
      if (category != null && category.isNotEmpty && category != 'All') {
        if (mp.category.toLowerCase() != category.toLowerCase()) return false;
      }
      return true;
    }).toList();
  }

  // Onboard Master Product to Store Shelf Inventory
  Future<ProductModel?> onboardMasterProduct({
    required String masterProductId,
    required double costPrice,
    required double sellingPrice,
    required int initialStock,
    int minThreshold = 5,
    String shelfLocation = 'General Shelf',
    String customName = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/products/onboard'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'store_id': 'store_default',
          'master_product_id': masterProductId,
          'cost_price': costPrice,
          'selling_price': sellingPrice,
          'initial_stock': initialStock,
          'min_threshold': minThreshold,
          'shelf_location': shelfLocation,
          'custom_name': customName,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return ProductModel.fromJson(body['product'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('API onboardMasterProduct fallback: $e');
    }
    return null;
  }

  // Create Product
  Future<ProductModel?> createProduct(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201 || res.statusCode == 200) {
        return ProductModel.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('API createProduct error: $e');
    }
    return ProductModel.fromJson(payload);
  }

  // Stock Adjustment
  Future<bool> adjustStock(String productId, int adjustedQty, String reason, String notes) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/products/$productId/adjust-stock'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adjusted_qty': adjustedQty,
          'reason': reason,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('API adjustStock error: $e');
      return true; // Optimistic update
    }
  }

  // Customers
  Future<List<CustomerModel>> getCustomers({String? search, String? filter}) async {
    try {
      var uri = Uri.parse('$baseUrl/customers').replace(queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (filter != null && filter.isNotEmpty) 'filter': filter,
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['customers'] as List<dynamic>? ?? [];
        return list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('API getCustomers fallback: $e');
    }
    await _loadAssetCustomers();
    return _getLocalCustomers(search, filter);
  }

  // Customer Profile & Ledger
  Future<CustomerModel?> getCustomerDetails(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/customers/$id')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return CustomerModel.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('API getCustomerDetails fallback: $e');
    }
    await _loadAssetCustomers();
    final list = _getLocalCustomers(null, null);
    for (final c in list) {
      if (c.id == id) return c;
    }
    return null;
  }

  // Record Khata Payment
  Future<bool> recordCustomerPayment(String customerId, double amount, String method, String notes) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/customers/$customerId/payments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'method': method,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('API recordCustomerPayment error: $e');
      return true;
    }
  }

  // Create Customer
  Future<CustomerModel?> createCustomer(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201 || res.statusCode == 200) {
        return CustomerModel.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('API createCustomer error: $e');
    }
    return null;
  }

  static final List<ReceiptModel> _cachedTransactions = [];

  Future<List<ReceiptModel>> getRecentTransactions({int limit = 10}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/transactions?limit=$limit')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = body['receipts'] as List<dynamic>? ?? [];
        final receipts = list.map((e) => ReceiptModel.fromJson(e as Map<String, dynamic>)).toList();
        _cachedTransactions.clear();
        _cachedTransactions.addAll(receipts);
        return receipts;
      }
    } catch (e) {
      debugPrint('API getRecentTransactions fallback to local: $e');
    }
    return List.unmodifiable(_cachedTransactions.take(limit).toList());
  }

  void recordTransaction(ReceiptModel receipt) {
    _cachedTransactions.insert(0, receipt);
  }

  // Checkout Flow
  Future<ReceiptModel?> checkout(Map<String, dynamic> checkoutPayload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/transactions/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(checkoutPayload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final r = ReceiptModel.fromJson(body['receipt']);
        recordTransaction(r);
        return r;
      }
    } catch (e) {
      debugPrint('API checkout error: $e');
    }

    // Dynamic offline fallback receipt using actual checkout payload
    final rawItems = (checkoutPayload['items'] as List<dynamic>? ?? []);
    final items = rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      final name = m['name']?.toString() ?? 'Item';
      final qty = (m['quantity'] as num?)?.toInt() ?? 1;
      final price = (m['unit_price'] as num?)?.toDouble() ?? 0.0;
      final total = (m['total_price'] as num?)?.toDouble() ?? (price * qty);
      return ReceiptItemModel(
        name: name,
        quantity: qty,
        unitPrice: price,
        totalPrice: total,
        formatted: '$name × $qty = ৳${total.toStringAsFixed(0)}',
      );
    }).toList();

    final subtotal = items.fold(0.0, (sum, i) => sum + i.totalPrice);
    final discount = (checkoutPayload['discount'] as num?)?.toDouble() ?? 0.0;
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final paidAmount = (checkoutPayload['paid_amount'] as num?)?.toDouble() ??
        (checkoutPayload['payment_method'] == 'cash' ? total : 0.0);
    final remainingDue = (total - paidAmount).clamp(0.0, double.infinity);
    final now = DateTime.now();
    final uuid = UuidUtil.generate();

    final currentStore = AuthService().currentStore;
    final receipt = ReceiptModel(
      storeName: currentStore?.name.isNotEmpty == true ? currentStore!.name : 'আমার দোকান',
      storeAddress: currentStore?.address ?? '',
      storePhone: currentStore?.ownerPhone ?? '',
      orderNumber: 'Order #${uuid.substring(0, 8).toUpperCase()}',
      dateTime: '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      customerName: checkoutPayload['customer_name']?.toString() ?? 'Walk-in Customer',
      items: items,
      subtotal: subtotal,
      discount: discount,
      total: total,
      paidAmount: paidAmount,
      remainingDue: remainingDue,
      authCode: 'TR-$uuid',
    );

    recordTransaction(receipt);
    return receipt;
  }

  // Asset-backed local fallbacks
  List<ProductModel> _getLocalInitialProducts(String? search, String? category, String? stockFilter) {
    final list = _cachedAssetProducts ?? [];
    return list.where((p) {
      if (category != null && category != 'All' && p.category != category) return false;
      if (search != null && search.isNotEmpty) {
        final s = search.toLowerCase();
        if (!p.name.toLowerCase().contains(s) && !p.barcode.contains(s) && !p.sku.toLowerCase().contains(s)) {
          return false;
        }
      }
      if (stockFilter == 'low' && !p.isLowStock) return false;
      if (stockFilter == 'out' && !p.isOutOfStock) return false;
      return true;
    }).toList();
  }

  List<CustomerModel> _getLocalCustomers(String? search, String? filter) {
    final all = _cachedAssetCustomers ?? [];
    return all.where((c) {
      if (filter == 'due' && !c.hasOutstanding) return false;
      if (filter == 'zero' && !c.isZeroBalance) return false;
      if (search != null && search.isNotEmpty) {
        final s = search.toLowerCase();
        if (!c.name.toLowerCase().contains(s) && !c.phone.contains(s)) return false;
      }
      return true;
    }).toList();
  }
}

