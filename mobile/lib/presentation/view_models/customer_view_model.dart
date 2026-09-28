import 'package:flutter/material.dart';
import '../../core/utils/uuid_util.dart';
import '../../data/models/customer_model.dart';
import '../../data/services/api_service.dart';

class CustomerViewModel extends ChangeNotifier {
  final ApiService _apiService;

  CustomerViewModel({ApiService? apiService}) : _apiService = apiService ?? ApiService() {
    loadCustomers();
  }

  List<CustomerModel> _customers = [];
  CustomerModel? _activeCustomer;
  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'all';

  List<CustomerModel> get customers => _customers;
  CustomerModel? get activeCustomer => _activeCustomer;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get filter => _filter;

  double get totalKhataDues => _customers.fold(0.0, (sum, c) => sum + c.currentDue);
  int get pendingDebtorCount => _customers.where((c) => c.hasOutstanding).length;
  List<CustomerModel> get customersWithDue => _customers.where((c) => c.hasOutstanding).toList();

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    _customers = await _apiService.getCustomers(
      search: _searchQuery,
      filter: _filter,
    );

    if (_activeCustomer != null) {
      final updated = _customers.where((c) => c.id == _activeCustomer!.id).firstOrNull;
      if (updated != null) {
        _activeCustomer = updated;
      }
    }

    _isLoading = false;
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

    _activeCustomer = await _apiService.getCustomerDetails(customerId);

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> recordPayment({
    required String customerId,
    required double amount,
    String method = 'cash',
    String notes = 'Counter Cash Deposit',
  }) async {
    final success = await _apiService.recordCustomerPayment(customerId, amount, method, notes);
    if (success) {
      await loadCustomers();
      if (_activeCustomer != null && _activeCustomer!.id == customerId) {
        await selectCustomer(customerId);
      }
    }
    return success;
  }

  Future<bool> createCustomer({
    required String name,
    String nameBn = '',
    required String phone,
    String address = '',
    double creditLimit = 5000.0,
    double initialDue = 0.0,
  }) async {
    _isLoading = true;
    notifyListeners();

    final payload = {
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
      name: name,
      nameBn: nameBn,
      phone: phone,
      address: address,
      creditLimit: creditLimit,
      currentDue: initialDue,
      lifetimePurchases: initialDue,
      status: initialDue > 0 ? 'warning' : 'clear',
      statusLabel: initialDue > 0 ? 'Active Balance' : 'Zero Balance',
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
  }) async {
    _isLoading = true;
    notifyListeners();

    final payload = {
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
      name: name.trim(),
      nameBn: '',
      phone: phone.trim(),
      address: address.trim(),
      creditLimit: creditLimit,
      currentDue: initialDue,
      lifetimePurchases: initialDue,
      status: initialDue > 0 ? 'warning' : 'clear',
      statusLabel: initialDue > 0 ? 'Active Balance' : 'Zero Balance',
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
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      final c = _customers[index];
      final newDue = c.currentDue + dueAmount;
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
      );
      _customers[index] = updated;
      if (_activeCustomer?.id == customerId) {
        _activeCustomer = updated;
      }
      notifyListeners();
    }
  }
}
