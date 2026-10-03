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
import '../models/grocery_request_model.dart';
import '../models/auth_model.dart';
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
  static Map<String, MasterProductModel>? _cachedMasterByBarcode;

  Future<List<MasterProductModel>> _loadMasterProducts() async {
    if (_cachedMasterProducts != null && _cachedMasterProducts!.isNotEmpty) {
      return _cachedMasterProducts!;
    }
    try {
      final jsonStr = await rootBundle.loadString('assets/data/master_products.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedMasterProducts = list.map((e) => MasterProductModel.fromJson(e as Map<String, dynamic>)).toList();
      _cachedMasterByBarcode = {
        for (final mp in _cachedMasterProducts!) mp.barcode: mp,
      };
      return _cachedMasterProducts!;
    } catch (e) {
      debugPrint('Asset master products loader error: $e');
      return [];
    }
  }

  Future<Map<String, MasterProductModel>> _loadMasterProductsMap() async {
    if (_cachedMasterByBarcode != null && _cachedMasterByBarcode!.isNotEmpty) {
      return _cachedMasterByBarcode!;
    }
    await _loadMasterProducts();
    return _cachedMasterByBarcode ?? {};
  }

  static List<CustomerModel>? _cachedAssetCustomers;

  Future<List<CustomerModel>> _loadAssetCustomers() async {
    if (_cachedAssetCustomers != null) {
      return _cachedAssetCustomers!;
    }
    try {
      final jsonStr = await rootBundle.loadString('assets/data/customers.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedAssetCustomers = list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
      return _cachedAssetCustomers!;
    } catch (e) {
      debugPrint('Asset customers loader error: $e');
      _cachedAssetCustomers = [];
      return [];
    }
  }

  // Products
  Future<List<ProductModel>> getProducts({String? search, String? category, String? stockFilter, String? storeId}) async {
    try {
      var uri = Uri.parse('$baseUrl/products').replace(queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty && category != 'All') 'category': category,
        if (stockFilter != null && stockFilter.isNotEmpty) 'stock_filter': stockFilter,
        if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
      });

      final res = await http.get(uri, headers: AuthService().authHeaders).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['products'] as List<dynamic>? ?? [];
        return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('API getProducts fallback: $e');
    }

    // Never show demo/sample products for custom stores
    if (storeId != null && storeId.isNotEmpty && storeId != AppConstants.defaultStoreId) {
      return [];
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
    final clean = barcode.trim();
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/products/scan/$clean'))
          .timeout(const Duration(milliseconds: 1200));
      if (res.statusCode == 200 || res.statusCode == 404) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return ScanResultModel.fromJson(body, clean);
      }
    } catch (e) {
      debugPrint('API scanBarcodeDetailed fast network fallback: $e');
    }

    // Offline Fallback Resolution
    // 1. Check if stocked in store inventory
    try {
      final assetList = await _loadAssetProducts();
      for (final p in assetList) {
        if (p.barcode == clean && p.isStocked) {
          return ScanResultModel(
            status: ScanStatus.foundInStore,
            barcode: clean,
            storeProduct: p,
            message: 'Found on shelf in store inventory',
          );
        }
      }
    } catch (_) {}

    // 2. Instant O(1) in-memory check in Bangladesh Master FMCG Catalog
    try {
      final masterMap = await _loadMasterProductsMap();
      final mp = masterMap[clean];
      if (mp != null) {
        return ScanResultModel(
          status: ScanStatus.foundInCatalog,
          barcode: clean,
          masterProduct: mp,
          message: 'Recognized in Bangladesh FMCG Catalog',
          canOnboard: true,
          canRegister: true,
        );
      }
    } catch (_) {}

    // 3. Unknown barcode
    return ScanResultModel(
      status: ScanStatus.unknownBarcode,
      barcode: clean,
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
    String? storeId,
  }) async {
    try {
      final effectiveStoreId = storeId ?? AuthService().storeId ?? AppConstants.defaultStoreId;
      final res = await http.post(
        Uri.parse('$baseUrl/products/onboard'),
        headers: AuthService().authHeaders,
        body: jsonEncode({
          'store_id': effectiveStoreId,
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
      debugPrint('API createProduct failed with ${res.statusCode}: ${res.body}');
      return null;
    } catch (e) {
      debugPrint('API createProduct network error: $e');
      return null;
    }
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
        final customers = list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
        _cachedAssetCustomers = customers;
        return customers;
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
        final cust = CustomerModel.fromJson(jsonDecode(res.body));
        _updateCachedCustomer(cust);
        return cust;
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

  void _updateCachedCustomer(CustomerModel updated) {
    _cachedAssetCustomers ??= [];
    final idx = _cachedAssetCustomers!.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _cachedAssetCustomers![idx] = updated;
    } else {
      _cachedAssetCustomers!.insert(0, updated);
    }
  }

  CustomerModel? _applyLocalPayment(String customerId, double amount, String method, String notes) {
    _cachedAssetCustomers ??= [];
    final idx = _cachedAssetCustomers!.indexWhere((c) => c.id == customerId);
    if (idx == -1) return null;

    final c = _cachedAssetCustomers![idx];
    final newDue = (c.currentDue - amount).clamp(0.0, double.infinity);
    final newEntry = KhataEntryModel(
      id: UuidUtil.generate(),
      customerId: c.id,
      type: 'payment_received',
      label: '${method.toUpperCase()} Payment Received',
      description: notes,
      paidAmount: amount,
      creditChange: -amount,
      runningBalance: newDue,
      createdAt: DateTime.now(),
    );

    final updated = CustomerModel(
      id: c.id,
      name: c.name,
      nameBn: c.nameBn,
      phone: c.phone,
      address: c.address,
      creditLimit: c.creditLimit,
      currentDue: newDue,
      lifetimePurchases: c.lifetimePurchases,
      status: newDue > 0 ? 'warning' : 'clear',
      statusLabel: newDue > 0 ? 'Active Balance' : 'All Dues Cleared',
      promiseDate: newDue > 0 ? c.promiseDate : '',
      ledger: [newEntry, ...c.ledger],
    );

    _cachedAssetCustomers![idx] = updated;
    return updated;
  }

  void recordCreditSaleLocally(String customerId, double dueAmount, String orderNumber) {
    _cachedAssetCustomers ??= [];
    final idx = _cachedAssetCustomers!.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      final c = _cachedAssetCustomers![idx];
      final newDue = c.currentDue + dueAmount;
      final newEntry = KhataEntryModel(
        id: UuidUtil.generate(),
        customerId: c.id,
        transactionId: orderNumber,
        type: 'sale_credit',
        label: 'POS Sale Memo ($orderNumber)',
        description: 'Remaining Due on Checkout',
        orderTotal: dueAmount,
        paidAmount: 0.0,
        creditChange: dueAmount,
        runningBalance: newDue,
        createdAt: DateTime.now(),
      );
      final updated = CustomerModel(
        id: c.id,
        name: c.name,
        nameBn: c.nameBn,
        phone: c.phone,
        address: c.address,
        creditLimit: c.creditLimit,
        currentDue: newDue,
        lifetimePurchases: c.lifetimePurchases + dueAmount,
        status: newDue > 0 ? 'warning' : 'clear',
        statusLabel: newDue > 0 ? 'Active Balance' : 'Zero Balance',
        promiseDate: c.promiseDate,
        ledger: [newEntry, ...c.ledger],
      );
      _cachedAssetCustomers![idx] = updated;
    }
  }

  // Record Khata Payment
  Future<CustomerModel?> recordCustomerPayment(String customerId, double amount, String method, String notes) async {
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
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['customer'] != null) {
          final updated = CustomerModel.fromJson(body['customer'] as Map<String, dynamic>);
          _updateCachedCustomer(updated);
          return updated;
        }
      }
    } catch (e) {
      debugPrint('API recordCustomerPayment error: $e');
    }

    // Local / Offline fallback update:
    await _loadAssetCustomers();
    return _applyLocalPayment(customerId, amount, method, notes);
  }

  // Stores
  Future<List<StoreModel>> getStores() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stores')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['stores'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          return list.map((e) => StoreModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('API getStores error: $e');
    }

    // Default neighborhood stores fallback
    return const [
      StoreModel(
        id: AppConstants.defaultStoreId,
        name: '${AppConstants.defaultStoreNameBn} (প্রধান শাখা)',
        ownerName: 'মো. রফিকুল ইসলাম',
        ownerPhone: '01711000000',
        address: 'মিরপুর-১০ গোলচত্বর, ঢাকা',
      ),
      StoreModel(
        id: 'store_gulshan',
        name: 'ভাই ভাই এন্টারপ্রাইজ',
        ownerName: 'তানভীর আহমেদ',
        ownerPhone: '01722000000',
        address: 'গুলশান-১ ডিসিসি মার্কেট, ঢাকা',
      ),
      StoreModel(
        id: 'store_dhanmondi',
        name: 'জনতা ডিপার্টমেন্টাল স্টোর',
        ownerName: 'হাজী সেলিম মিয়া',
        ownerPhone: '01733000000',
        address: 'ধানমন্ডি-২৭, ঢাকা',
      ),
    ];
  }

  // Create Customer
  Future<CustomerModel?> createCustomer(Map<String, dynamic> payload) async {
    try {
      final activeStoreId = AuthService().storeId;
      if ((payload['store_id'] == null ||
           payload['store_id'] == '' ||
           payload['store_id'] == AppConstants.defaultStoreId) &&
          activeStoreId != null &&
          activeStoreId.isNotEmpty) {
        payload['store_id'] = activeStoreId;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: AuthService().authHeaders,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final cust = CustomerModel.fromJson(jsonDecode(res.body));
        _updateCachedCustomer(cust);
        return cust;
      }
    } catch (e) {
      debugPrint('API createCustomer error: $e');
    }

    // Local fallback
    await _loadAssetCustomers();
    final initialDue = (payload['initial_due'] as num?)?.toDouble() ?? 0.0;
    final currentStore = AuthService().currentStore;
    final cust = CustomerModel(
      id: UuidUtil.generate(),
      storeId: payload['store_id']?.toString() ?? currentStore?.id ?? AppConstants.defaultStoreId,
      storeName: currentStore?.name.isNotEmpty == true ? currentStore!.name : AppConstants.defaultStoreNameBn,
      storeAddress: currentStore?.address ?? '',
      name: payload['name']?.toString() ?? '',
      nameBn: payload['name_bn']?.toString() ?? '',
      phone: payload['phone']?.toString() ?? '',
      address: payload['address']?.toString() ?? '',
      creditLimit: (payload['credit_limit'] as num?)?.toDouble() ?? 5000.0,
      currentDue: initialDue,
      lifetimePurchases: initialDue,
      status: initialDue > 0 ? 'warning' : 'clear',
      statusLabel: initialDue > 0 ? 'Active Balance' : 'Zero Balance',
      ledger: initialDue > 0
          ? [
              KhataEntryModel(
                id: UuidUtil.generate(),
                customerId: '',
                type: 'initial_due',
                label: 'Opening Balance Due',
                description: 'Initial balance carried over',
                orderTotal: initialDue,
                paidAmount: 0.0,
                creditChange: initialDue,
                runningBalance: initialDue,
                createdAt: DateTime.now(),
              )
            ]
          : const [],
    );
    _updateCachedCustomer(cust);
    return cust;
  }

  static final List<ReceiptModel> _cachedTransactions = [];

  Future<List<ReceiptModel>> getRecentTransactions({int limit = 10, String? customerId, String? phone, String? storeId}) async {
    try {
      final queryParams = <String, String>{'limit': '$limit'};
      if (customerId != null && customerId.isNotEmpty) {
        queryParams['customer_id'] = customerId;
      }
      if (phone != null && phone.isNotEmpty) {
        queryParams['phone'] = phone;
      }
      final effectiveStoreId = storeId ?? AuthService().storeId;
      if (effectiveStoreId != null && effectiveStoreId.isNotEmpty) {
        queryParams['store_id'] = effectiveStoreId;
      }
      final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams);
      final res = await http.get(
        uri,
        headers: AuthService().authHeaders,
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = body['receipts'] as List<dynamic>? ?? [];
        final receipts = list.map((e) => ReceiptModel.fromJson(e as Map<String, dynamic>)).toList();
        if (receipts.isNotEmpty && (customerId == null || customerId.isEmpty) && (phone == null || phone.isEmpty)) {
          _cachedTransactions.clear();
          _cachedTransactions.addAll(receipts);
        }
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
      final activeStoreId = AuthService().storeId;
      if ((checkoutPayload['store_id'] == null ||
           checkoutPayload['store_id'] == '' ||
           checkoutPayload['store_id'] == AppConstants.defaultStoreId) &&
          activeStoreId != null &&
          activeStoreId.isNotEmpty) {
        checkoutPayload['store_id'] = activeStoreId;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/transactions/checkout'),
        headers: AuthService().authHeaders,
        body: jsonEncode(checkoutPayload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final r = ReceiptModel.fromJson(body['receipt']);
        recordTransaction(r);
        return r;
      } else {
        debugPrint('API checkout error HTTP ${res.statusCode}: ${res.body}');
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
      storeId: checkoutPayload['store_id']?.toString() ?? currentStore?.id ?? AppConstants.defaultStoreId,
      storeName: currentStore?.name.isNotEmpty == true ? currentStore!.name : AppConstants.defaultStoreNameBn,
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

  // Grocery Requests
  static final List<GroceryRequestModel> _cachedGroceryRequests = [];

  Future<GroceryRequestModel?> createGroceryRequest(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/grocery-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final gr = GroceryRequestModel.fromJson(body['grocery_request']);
        _cachedGroceryRequests.insert(0, gr);
        return gr;
      }
    } catch (e) {
      debugPrint('API createGroceryRequest error: $e');
    }

    // Local fallback
    final rawTotal = (payload['estimated_total'] as num?)?.toDouble() ?? 0.0;
    final itemsTxt = payload['items_text']?.toString() ?? '';
    double resolvedTotal = rawTotal;
    if (resolvedTotal == 0.0 && itemsTxt.isNotEmpty) {
      final regExp = RegExp(r'(?:মোট|Total|Subtotal)[:\s]*[৳Tk\s]*([0-9]+(?:\.[0-9]+)?)', caseSensitive: false);
      final match = regExp.firstMatch(itemsTxt);
      if (match != null && match.group(1) != null) {
        resolvedTotal = double.tryParse(match.group(1)!) ?? 0.0;
      }
    }

    final gr = GroceryRequestModel(
      id: UuidUtil.generate(),
      storeId: payload['store_id']?.toString() ?? AppConstants.defaultStoreId,
      storeName: payload['store_name']?.toString() ?? AppConstants.defaultStoreNameBn,
      customerId: payload['customer_id']?.toString() ?? '',
      customerName: payload['customer_name']?.toString() ?? '',
      customerPhone: payload['customer_phone']?.toString() ?? '',
      itemsText: itemsTxt,
      deliveryType: payload['delivery_type']?.toString() ?? 'pickup',
      address: payload['address']?.toString() ?? '',
      notes: payload['notes']?.toString() ?? '',
      estimatedTotal: resolvedTotal,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    _cachedGroceryRequests.insert(0, gr);
    return gr;
  }

  Future<List<GroceryRequestModel>> getGroceryRequests({
    String? storeId,
    String? customerPhone,
    String? customerId,
    String? status,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/grocery-requests').replace(queryParameters: {
        if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
        if (customerPhone != null && customerPhone.isNotEmpty) 'customer_phone': customerPhone,
        if (customerId != null && customerId.isNotEmpty) 'customer_id': customerId,
        if (status != null && status.isNotEmpty) 'status': status,
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = body['grocery_requests'] as List<dynamic>? ?? [];
        final requests = list.map((e) => GroceryRequestModel.fromJson(e as Map<String, dynamic>)).toList();
        _cachedGroceryRequests.clear();
        _cachedGroceryRequests.addAll(requests);
        return requests;
      }
    } catch (e) {
      debugPrint('API getGroceryRequests error: $e');
    }

    return _cachedGroceryRequests.where((gr) {
      if (storeId != null && storeId.isNotEmpty && gr.storeId != storeId) return false;
      if (customerPhone != null && customerPhone.isNotEmpty && gr.customerPhone != customerPhone) return false;
      if (customerId != null && customerId.isNotEmpty && gr.customerId != customerId) return false;
      if (status != null && status.isNotEmpty && gr.status != status) return false;
      return true;
    }).toList();
  }

  Future<GroceryRequestModel?> updateGroceryRequestStatus(String id, String status) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/grocery-requests/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final gr = GroceryRequestModel.fromJson(body['grocery_request']);
        final idx = _cachedGroceryRequests.indexWhere((r) => r.id == id);
        if (idx != -1) {
          _cachedGroceryRequests[idx] = gr;
        }
        return gr;
      }
    } catch (e) {
      debugPrint('API updateGroceryRequestStatus error: $e');
    }

    final idx = _cachedGroceryRequests.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final old = _cachedGroceryRequests[idx];
      final updated = GroceryRequestModel(
        id: old.id,
        storeId: old.storeId,
        storeName: old.storeName,
        customerId: old.customerId,
        customerName: old.customerName,
        customerPhone: old.customerPhone,
        itemsText: old.itemsText,
        deliveryType: old.deliveryType,
        address: old.address,
        notes: old.notes,
        status: status,
        createdAt: old.createdAt,
      );
      _cachedGroceryRequests[idx] = updated;
      return updated;
    }
    return null;
  }

  // Device Token Registration
  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    required String role,
    required String storeId,
    required String userId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/devices/register'),
        headers: AuthService().authHeaders,
        body: jsonEncode({
          'token': token,
          'platform': platform,
          'role': role,
          'store_id': storeId,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('registerDeviceToken error: $e');
      return false;
    }
  }
}

