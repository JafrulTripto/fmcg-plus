import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/uuid_util.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/grocery_request_model.dart';
import '../../data/models/auth_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_service.dart';

class CustomerViewModel extends ChangeNotifier {
  final ApiService _apiService;

  CustomerViewModel({ApiService? apiService}) : _apiService = apiService ?? ApiService() {
    loadCustomers();
    loadStores();
  }

  List<CustomerModel> _customers = [];
  CustomerModel? _activeCustomer;
  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'all';

  List<StoreModel> _stores = [];
  List<StoreModel> get stores => _stores;

  List<GroceryRequestModel> _groceryRequests = [];
  bool _isGroceryLoading = false;

  List<CustomerModel> get customers => _customers;
  CustomerModel? get activeCustomer => _activeCustomer;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get filter => _filter;

  List<GroceryRequestModel> get groceryRequests => _groceryRequests;
  bool get isGroceryLoading => _isGroceryLoading;

  double get totalKhataDues => _customers.fold(0.0, (sum, c) => sum + c.currentDue);
  int get pendingDebtorCount => _customers.where((c) => c.hasOutstanding).length;
  List<CustomerModel> get customersWithDue => _customers.where((c) => c.hasOutstanding).toList();

  Future<void> loadCustomers({String? search, String? filter}) async {
    _isLoading = true;
    notifyListeners();

    final fetched = await _apiService.getCustomers(
      search: search ?? _searchQuery,
      filter: filter ?? _filter,
    );

    _customers = fetched;

    if (_activeCustomer != null) {
      final updated = _customers.where((c) => c.id == _activeCustomer!.id).firstOrNull;
      if (updated != null) {
        _activeCustomer = updated;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStores() async {
    _stores = await _apiService.getStores();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadCustomers();
  }

  void setFilter(String filter) {
    _filter = filter;
    loadCustomers();
  }

  Future<void> selectCustomer(String customerId) async {
    _isLoading = true;
    notifyListeners();

    final details = await _apiService.getCustomerDetails(customerId);
    if (details != null) {
      _activeCustomer = details;
    } else {
      _activeCustomer = _customers.where((c) => c.id == customerId).firstOrNull;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> recordPayment({
    required String customerId,
    required double amount,
    String method = 'cash',
    String notes = 'Counter Cash Deposit',
  }) async {
    final updatedCustomer = await _apiService.recordCustomerPayment(customerId, amount, method, notes);

    // Update in-memory customer immediately
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      if (updatedCustomer != null) {
        _customers[index] = updatedCustomer;
      } else {
        final c = _customers[index];
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
        _customers[index] = updated;
      }

      if (_activeCustomer != null && _activeCustomer!.id == customerId) {
        _activeCustomer = _customers[index];
      }
      notifyListeners();
      return true;
    }

    if (updatedCustomer != null) {
      if (_activeCustomer != null && _activeCustomer!.id == customerId) {
        _activeCustomer = updatedCustomer;
      }
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> createCustomer({
    required String name,
    String nameBn = '',
    required String phone,
    String address = '',
    double creditLimit = 5000.0,
    double initialDue = 0.0,
    String? storeId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final effectiveStoreId = storeId ?? AuthService().storeId ?? AppConstants.defaultStoreId;
    final payload = {
      'store_id': effectiveStoreId,
      'name': name,
      'name_bn': nameBn,
      'phone': phone,
      'address': address,
      'credit_limit': creditLimit,
      'initial_due': initialDue,
    };

    final created = await _apiService.createCustomer(payload);
    if (created != null) {
      _customers.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    final newCust = CustomerModel(
      id: UuidUtil.generate(),
      storeId: effectiveStoreId,
      storeName: AuthService().currentStore?.name ?? AppConstants.defaultStoreNameBn,
      name: name,
      nameBn: nameBn,
      phone: phone,
      address: address,
      creditLimit: creditLimit,
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

    _customers.insert(0, newCust);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<CustomerModel> createAndReturnCustomer({
    required String name,
    required String phone,
    String address = '',
    double creditLimit = 5000.0,
    double initialDue = 0.0,
    String? storeId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final effectiveStoreId = storeId ?? AuthService().storeId ?? AppConstants.defaultStoreId;
    final payload = {
      'store_id': effectiveStoreId,
      'name': name.trim(),
      'name_bn': '',
      'phone': phone.trim(),
      'address': address.trim(),
      'credit_limit': creditLimit,
      'initial_due': initialDue,
    };

    final created = await _apiService.createCustomer(payload);
    if (created != null) {
      _customers.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    }

    final newCust = CustomerModel(
      id: UuidUtil.generate(),
      storeId: effectiveStoreId,
      storeName: AuthService().currentStore?.name ?? AppConstants.defaultStoreNameBn,
      name: name.trim(),
      nameBn: '',
      phone: phone.trim(),
      address: address.trim(),
      creditLimit: creditLimit,
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

    _customers.insert(0, newCust);
    _isLoading = false;
    notifyListeners();
    return newCust;
  }

  void recordCreditSale({
    required String customerId,
    required double dueAmount,
    required String orderNumber,
    String? description,
  }) {
    _apiService.recordCreditSaleLocally(customerId, dueAmount, orderNumber);
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      final c = _customers[index];
      final newDue = c.currentDue + dueAmount;
      final newEntry = KhataEntryModel(
        id: UuidUtil.generate(),
        customerId: c.id,
        transactionId: orderNumber,
        type: 'sale_credit',
        label: 'POS Sale Memo ($orderNumber)',
        description: description ?? 'Remaining Due on Checkout',
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
      _customers[index] = updated;
      if (_activeCustomer?.id == customerId) {
        _activeCustomer = updated;
      }
      notifyListeners();
    }
  }

  Future<void> loadGroceryRequests({
    String? storeId,
    String? customerPhone,
    String? customerId,
    String? status,
  }) async {
    _isGroceryLoading = true;
    notifyListeners();

    try {
      final requests = await _apiService.getGroceryRequests(
        storeId: storeId,
        customerPhone: customerPhone,
        customerId: customerId,
        status: status,
      );
      _groceryRequests = requests;
    } finally {
      _isGroceryLoading = false;
      notifyListeners();
    }
  }

  double get totalGroceryRequestedAmount {
    return _groceryRequests.fold<double>(0.0, (sum, r) => sum + r.estimatedTotal);
  }

  int get pendingGroceryRequestsCount {
    return _groceryRequests.where((r) => r.isPending).length;
  }

  Future<GroceryRequestModel?> createGroceryRequest({
    required String storeId,
    required String storeName,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String itemsText,
    double estimatedTotal = 0.0,
    String deliveryType = 'pickup',
    String address = '',
    String notes = '',
  }) async {
    _isGroceryLoading = true;
    notifyListeners();

    try {
      final payload = {
        'store_id': storeId,
        'store_name': storeName,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'items_text': itemsText,
        'estimated_total': estimatedTotal,
        'delivery_type': deliveryType,
        'address': address,
        'notes': notes,
      };

      final created = await _apiService.createGroceryRequest(payload);
      if (created != null) {
        if (!_groceryRequests.any((r) => r.id == created.id)) {
          _groceryRequests.insert(0, created);
        }
      }
      return created;
    } finally {
      _isGroceryLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGroceryRequestStatus(String requestId, String status) async {
    final updated = await _apiService.updateGroceryRequestStatus(requestId, status);
    if (updated != null) {
      final index = _groceryRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _groceryRequests[index] = updated;
      }
      notifyListeners();
      return true;
    }
    return false;
  }
}
