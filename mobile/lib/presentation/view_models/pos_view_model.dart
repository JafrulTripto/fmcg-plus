import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/api_service.dart';

enum PaymentMode { cash, partial, credit }

class PosViewModel extends ChangeNotifier {
  final ApiService _apiService;

  PosViewModel({ApiService? apiService}) : _apiService = apiService ?? ApiService() {
    loadRecentTransactions();
  }

  final List<CartItemModel> _cart = [];
  double _discount = 0.0;
  CustomerModel? _selectedCustomer;
  PaymentMode _paymentMode = PaymentMode.cash;
  double _cashReceived = 0.0;
  ReceiptModel? _lastReceipt;
  bool _isLoading = false;

  // Getters
  List<CartItemModel> get cart => List.unmodifiable(_cart);
  double get discount => _discount;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  PaymentMode get paymentMode => _paymentMode;
  double get cashReceived => _cashReceived;
  ReceiptModel? get lastReceipt => _lastReceipt;
  bool get isLoading => _isLoading;

  final List<ReceiptModel> _recentTransactions = [];
  List<ReceiptModel> get recentTransactions => List.unmodifiable(_recentTransactions);

  Future<void> loadRecentTransactions() async {
    final list = await _apiService.getRecentTransactions();
    _recentTransactions.clear();
    _recentTransactions.addAll(list);
    notifyListeners();
  }

  int get totalItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get grandTotal => (subtotal - _discount).clamp(0.0, double.infinity);
  double get remainingDue => (_paymentMode == PaymentMode.cash) ? 0.0 : (grandTotal - _cashReceived).clamp(0.0, double.infinity);

  void addToCart(ProductModel product) {
    final index = _cart.indexWhere((i) => i.product.id == product.id);
    if (index != -1) {
      _cart[index].quantity += 1;
    } else {
      _cart.add(CartItemModel(product: product, quantity: 1));
    }
    notifyListeners();
  }

  int getItemQuantity(String productId) {
    final index = _cart.indexWhere((i) => i.product.id == productId);
    return index != -1 ? _cart[index].quantity : 0;
  }

  void updateQuantity(String productId, int delta) {
    final index = _cart.indexWhere((i) => i.product.id == productId);
    if (index != -1) {
      _cart[index].quantity += delta;
      if (_cart[index].quantity <= 0) {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void setDiscount(double value) {
    _discount = value;
    notifyListeners();
  }

  void selectCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setPaymentMode(PaymentMode mode) {
    _paymentMode = mode;
    if (mode == PaymentMode.cash) {
      _cashReceived = grandTotal;
    } else if (mode == PaymentMode.credit) {
      _cashReceived = 0.0;
    } else {
      _cashReceived = 200.0;
    }
    notifyListeners();
  }

  void setCashReceived(double amount) {
    _cashReceived = amount;
    notifyListeners();
  }

  void addCashPreset(double amount) {
    _cashReceived += amount;
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<ReceiptModel?> processCheckout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        'customer_id': _selectedCustomer?.id ?? '',
        'customer_name': _selectedCustomer?.name ?? 'Walk-in Cash Customer',
        'items': _cart.map((i) => i.toCheckoutItemJson()).toList(),
        'discount': _discount,
        'paid_amount': _cashReceived,
        'payment_method': _paymentMode.name,
      };

      final receipt = await _apiService.checkout(payload);
      _lastReceipt = receipt;
      if (receipt != null) {
        _recentTransactions.insert(0, receipt);
      }
      clearCart();
      _isLoading = false;
      notifyListeners();
      return receipt;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
