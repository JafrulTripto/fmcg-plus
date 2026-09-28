import 'package:flutter/material.dart';
import '../../core/utils/uuid_util.dart';
import '../../data/models/product_model.dart';
import '../../data/models/master_product_model.dart';
import '../../data/models/scan_result_model.dart';
import '../../data/services/api_service.dart';

class InventoryViewModel extends ChangeNotifier {
  final ApiService _apiService;

  InventoryViewModel({ApiService? apiService}) : _apiService = apiService ?? ApiService() {
    loadProducts();
  }

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _stockFilter = 'all';

  List<ProductModel> get products => _products;
  List<ProductModel> get filteredProducts => _products;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get stockFilter => _stockFilter;

  List<ProductModel> get lowStockProducts => _products.where((p) => p.isLowStock).toList();

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    _products = await _apiService.getProducts(
      search: _searchQuery,
      category: _selectedCategory,
      stockFilter: _stockFilter,
    );

    _isLoading = false;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    loadProducts();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadProducts();
  }

  void setStockFilter(String filter) {
    _stockFilter = filter;
    loadProducts();
  }

  Future<ProductModel?> scanBarcode(String barcode) async {
    return await _apiService.scanBarcode(barcode);
  }

  Future<ScanResultModel> scanBarcodeDetailed(String barcode) async {
    return await _apiService.scanBarcodeDetailed(barcode);
  }

  Future<bool> onboardMasterProduct({
    required MasterProductModel masterProduct,
    required double costPrice,
    required double sellingPrice,
    required int initialStock,
    int minThreshold = 5,
    String shelfLocation = 'General Shelf',
    String customName = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    final created = await _apiService.onboardMasterProduct(
      masterProductId: masterProduct.id,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      initialStock: initialStock,
      minThreshold: minThreshold,
      shelfLocation: shelfLocation,
      customName: customName,
    );

    if (created != null) {
      _products.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Fallback: create locally
    final fallbackProduct = ProductModel(
      id: UuidUtil.generate(),
      name: customName.isNotEmpty ? customName : masterProduct.productName,
      category: masterProduct.category,
      brand: masterProduct.brand,
      packSize: masterProduct.packSize,
      unit: masterProduct.unit,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      stock: initialStock,
      minThreshold: minThreshold,
      barcode: masterProduct.barcode,
      sku: masterProduct.sku,
      imageUrl: masterProduct.imageUrl,
      shelfLocation: shelfLocation,
      isStocked: true,
    );
    _products.insert(0, fallbackProduct);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> addProduct({
    required String name,
    required String category,
    String barcode = '',
    String sku = '',
    required double costPrice,
    required double sellingPrice,
    required int stock,
    int minThreshold = 5,
    required String unit,
    String imageUrl = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    final payload = {
      'name': name,
      'category': category,
      'barcode': barcode,
      'sku': sku,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'min_threshold': minThreshold,
      'unit': unit,
      'image_url': imageUrl,
    };

    final created = await _apiService.createProduct(payload);
    if (created != null) {
      _products.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return true;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> adjustStock({
    required String productId,
    required int adjustedQty,
    required String reason,
    String notes = '',
  }) async {
    final success = await _apiService.adjustStock(productId, adjustedQty, reason, notes);
    if (success) {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        if (reason == 'restock' || reason == 'return') {
          _products[index].stock += adjustedQty;
        } else if (reason == 'damaged') {
          _products[index].stock = (_products[index].stock - adjustedQty).clamp(0, 99999);
        } else {
          _products[index].stock = adjustedQty;
        }
        notifyListeners();
      }
    }
    return success;
  }
}
