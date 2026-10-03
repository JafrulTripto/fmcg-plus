import '../../core/constants/app_constants.dart';

class GroceryRequestModel {
  final String id;
  final String storeId;
  final String storeName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String itemsText;
  final String deliveryType; // 'pickup', 'delivery'
  final String address;
  final String notes;
  final double estimatedTotal;
  final String status; // 'pending', 'accepted', 'ready', 'completed', 'cancelled'
  final DateTime createdAt;

  const GroceryRequestModel({
    required this.id,
    this.storeId = AppConstants.defaultStoreId,
    this.storeName = AppConstants.defaultStoreNameBn,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.itemsText,
    this.deliveryType = 'pickup',
    this.address = '',
    this.notes = '',
    this.estimatedTotal = 0.0,
    this.status = 'pending',
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isReady => status == 'ready';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isPickup => deliveryType == 'pickup';
  bool get isHomeDelivery => deliveryType == 'home_delivery' || deliveryType == 'delivery';

  String get deliveryTypeLabelBn => isPickup ? 'দোকান থেকে নেব' : 'হোম ডেলিভারি';
  String get deliveryTypeLabelEn => isPickup ? 'Store Pickup' : 'Home Delivery';

  String get statusDisplayBn {
    switch (status) {
      case 'pending':
        return 'অপেক্ষমান';
      case 'accepted':
        return 'দোকানদার গ্রহণ করেছেন';
      case 'ready':
        return 'ব্যাগ প্রস্তুত';
      case 'completed':
        return 'সরবরাহ সম্পন্ন';
      case 'cancelled':
        return 'বাতিল';
      default:
        return status;
    }
  }

  String get statusDisplayEn {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted by Shop';
      case 'ready':
        return 'Ready for Pickup';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  factory GroceryRequestModel.fromJson(Map<String, dynamic> json) {
    final rawTotal = (json['estimated_total'] as num?)?.toDouble() ?? 0.0;
    final itemsText = json['items_text'] as String? ?? '';
    double resolvedTotal = rawTotal;
    if (resolvedTotal == 0.0 && itemsText.isNotEmpty) {
      final regExp = RegExp(r'(?:মোট|Total|Subtotal)[:\s]*[৳Tk\s]*([0-9]+(?:\.[0-9]+)?)', caseSensitive: false);
      final match = regExp.firstMatch(itemsText);
      if (match != null && match.group(1) != null) {
        resolvedTotal = double.tryParse(match.group(1)!) ?? 0.0;
      }
    }

    return GroceryRequestModel(
      id: json['id'] as String? ?? '',
      storeId: json['store_id'] as String? ?? AppConstants.defaultStoreId,
      storeName: json['store_name'] as String? ?? AppConstants.defaultStoreNameBn,
      customerId: json['customer_id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      itemsText: itemsText,
      deliveryType: json['delivery_type'] as String? ?? 'pickup',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      estimatedTotal: resolvedTotal,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'store_name': storeName,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'items_text': itemsText,
      'delivery_type': deliveryType,
      'address': address,
      'notes': notes,
      'estimated_total': estimatedTotal,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
