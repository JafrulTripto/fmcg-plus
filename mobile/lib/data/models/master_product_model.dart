class MasterProductModel {
  final String id;
  final String barcode;
  final String productName;
  final String? productNameBn;
  final String brand;
  final String category;
  final String subcategory;
  final String packSize;
  final String unit;
  final double suggestedMrp;
  final double suggestedCost;
  final String sku;
  final String imageUrl;

  MasterProductModel({
    required this.id,
    required this.barcode,
    required this.productName,
    this.productNameBn,
    this.brand = '',
    this.category = '',
    this.subcategory = '',
    this.packSize = '',
    this.unit = 'pcs',
    this.suggestedMrp = 0.0,
    this.suggestedCost = 0.0,
    this.sku = '',
    this.imageUrl = '',
  });

  factory MasterProductModel.fromJson(Map<String, dynamic> json) {
    return MasterProductModel(
      id: json['id']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? json['name']?.toString() ?? '',
      productNameBn: json['product_name_bn']?.toString(),
      brand: json['brand']?.toString() ?? json['brand_id']?.toString() ?? '',
      category: json['category']?.toString() ?? json['category_id']?.toString() ?? '',
      subcategory: json['subcategory']?.toString() ?? json['subcategory_id']?.toString() ?? '',
      packSize: json['pack_size']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'pcs',
      suggestedMrp: (json['suggested_mrp'] as num?)?.toDouble() ?? 0.0,
      suggestedCost: (json['suggested_cost'] as num?)?.toDouble() ?? 0.0,
      sku: json['sku']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'product_name': productName,
      'product_name_bn': productNameBn,
      'brand': brand,
      'category': category,
      'subcategory': subcategory,
      'pack_size': packSize,
      'unit': unit,
      'suggested_mrp': suggestedMrp,
      'suggested_cost': suggestedCost,
      'sku': sku,
      'image_url': imageUrl,
    };
  }
}
