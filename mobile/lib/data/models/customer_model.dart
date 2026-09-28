class KhataEntryModel {
  final String id;
  final String customerId;
  final String transactionId;
  final String type;
  final String label;
  final String description;
  final double orderTotal;
  final double paidAmount;
  final double creditChange;
  final double runningBalance;
  final DateTime createdAt;

  KhataEntryModel({
    required this.id,
    required this.customerId,
    this.transactionId = '',
    required this.type,
    required this.label,
    this.description = '',
    this.orderTotal = 0.0,
    this.paidAmount = 0.0,
    required this.creditChange,
    required this.runningBalance,
    required this.createdAt,
  });

  DateTime get timestamp => createdAt;

  factory KhataEntryModel.fromJson(Map<String, dynamic> json) {
    return KhataEntryModel(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      type: json['type'] as String? ?? 'sale_credit',
      label: json['label'] as String? ?? 'Transaction',
      description: json['description'] as String? ?? '',
      orderTotal: (json['order_total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      creditChange: (json['credit_change'] as num?)?.toDouble() ?? 0.0,
      runningBalance: (json['running_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String nameBn;
  final String phone;
  final String address;
  final double creditLimit;
  double currentDue;
  final double lifetimePurchases;
  final String status;
  final String statusLabel;
  final String promiseDate;
  final List<KhataEntryModel> ledger;

  CustomerModel({
    required this.id,
    required this.name,
    this.nameBn = '',
    required this.phone,
    this.address = '',
    this.creditLimit = 5000.0,
    this.currentDue = 0.0,
    this.lifetimePurchases = 0.0,
    this.status = 'normal',
    this.statusLabel = '',
    this.promiseDate = '',
    this.ledger = const [],
  });

  bool get hasOutstanding => currentDue > 0;
  bool get isZeroBalance => currentDue <= 0;
  double get currentBalance => currentDue;
  List<KhataEntryModel> get ledgerEntries => ledger;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'C';
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    var rawLedger = json['ledger'] as List<dynamic>? ?? [];
    List<KhataEntryModel> parsedLedger = rawLedger
        .map((e) => KhataEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return CustomerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameBn: json['name_bn'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 5000.0,
      currentDue: (json['current_due'] as num?)?.toDouble() ?? 0.0,
      lifetimePurchases: (json['lifetime_purchases'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'normal',
      statusLabel: json['status_label'] as String? ?? '',
      promiseDate: json['promise_date'] as String? ?? '',
      ledger: parsedLedger,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_bn': nameBn,
      'phone': phone,
      'address': address,
      'credit_limit': creditLimit,
      'current_due': currentDue,
      'lifetime_purchases': lifetimePurchases,
      'status': status,
      'status_label': statusLabel,
      'promise_date': promiseDate,
    };
  }
}
