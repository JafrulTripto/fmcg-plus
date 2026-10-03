import '../../core/constants/app_constants.dart';

class ReceiptItemModel {
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String formatted;

  ReceiptItemModel({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.formatted,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptItemModel(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      formatted: json['formatted'] as String? ?? '',
    );
  }
}

class ReceiptModel {
  final String storeId;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String orderNumber;
  final String dateTime;
  final String customerName;
  final List<ReceiptItemModel> items;
  final double subtotal;
  final double discount;
  final double total;
  final double paidAmount;
  final double remainingDue;
  final String authCode;
  final String cashier;
  final String counter;

  ReceiptModel({
    this.storeId = AppConstants.defaultStoreId,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.orderNumber,
    required this.dateTime,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paidAmount,
    required this.remainingDue,
    this.authCode = 'TR-AUTH',
    this.cashier = 'Tanvir',
    this.counter = 'Counter 01',
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<ReceiptItemModel> parsedItems = rawItems
        .map((e) => ReceiptItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReceiptModel(
      storeId: json['store_id'] as String? ?? AppConstants.defaultStoreId,
      storeName: json['store_name'] as String? ?? json['store_name_bn'] as String? ?? AppConstants.defaultStoreNameEn,
      storeAddress: json['store_address'] as String? ?? json['store_branch'] as String? ?? AppConstants.defaultStoreAddress,
      storePhone: json['store_phone'] as String? ?? json['owner_phone'] as String? ?? AppConstants.defaultStorePhone,
      orderNumber: json['order_number'] as String? ?? 'Order',
      dateTime: json['date_time'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? 'Walk-in Customer',
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingDue: (json['remaining_due'] as num?)?.toDouble() ?? 0.0,
      authCode: json['auth_code'] as String? ?? '',
      cashier: json['cashier'] as String? ?? 'Cashier',
      counter: json['counter'] as String? ?? 'Counter 01',
    );
  }

  String get id => orderNumber;
  DateTime get createdAt => DateTime.now();
  String get paymentMethod => remainingDue > 0 ? (paidAmount > 0 ? 'PARTIAL' : 'CREDIT') : 'CASH';
  DateTime get timestamp => DateTime.tryParse(dateTime) ?? createdAt;
  double get dueAmount => remainingDue;
  ReceiptModel toReceipt() => this;
}

typedef TransactionModel = ReceiptModel;

