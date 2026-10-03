import '../../core/constants/app_constants.dart';

class ProductModel {
  final String id;
  final String storeId;
  final String name;
  final String category;
  final String brand;
  final String packSize;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  int stock;
  final int minThreshold;
  final String barcode;
  final String sku;
  final String imageUrl;
  final String shelfLocation;
  final bool isStocked;

  ProductModel({
    required this.id,
    this.storeId = AppConstants.defaultStoreId,
    required this.name,
    required this.category,
    this.brand = '',
    this.packSize = '',
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    this.stock = 0,
    this.minThreshold = 5,
    this.barcode = '',
    this.sku = '',
    this.imageUrl = '',
    this.shelfLocation = '',
    this.isStocked = true,
  });

  bool get isLowStock => stock <= minThreshold && stock > 0;
  bool get isOutOfStock => stock <= 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      storeId: json['store_id'] as String? ?? AppConstants.defaultStoreId,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      brand: json['brand'] as String? ?? '',
      packSize: json['pack_size'] as String? ?? json['pack'] as String? ?? '',
      unit: json['unit'] as String? ?? 'pcs',
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? (json['cost'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      minThreshold: json['min_threshold'] as int? ?? json['min'] as int? ?? 5,
      barcode: json['barcode'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['image'] as String? ?? '',
      shelfLocation: json['shelf_location'] as String? ?? json['shelf'] as String? ?? '',
      isStocked: json['is_stocked'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'brand': brand,
      'pack_size': packSize,
      'unit': unit,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'min_threshold': minThreshold,
      'barcode': barcode,
      'sku': sku,
      'image_url': imageUrl,
      'shelf_location': shelfLocation,
      'is_stocked': isStocked,
    };
  }
}
