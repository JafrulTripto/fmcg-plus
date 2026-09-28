import 'product_model.dart';
import 'master_product_model.dart';

enum ScanStatus {
  foundInStore,
  foundInCatalog,
  unknownBarcode,
}

class ScanResultModel {
  final ScanStatus status;
  final String barcode;
  final ProductModel? storeProduct;
  final MasterProductModel? masterProduct;
  final String message;
  final bool canRegister;
  final bool canOnboard;

  ScanResultModel({
    required this.status,
    required this.barcode,
    this.storeProduct,
    this.masterProduct,
    this.message = '',
    this.canRegister = false,
    this.canOnboard = false,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json, String scannedBarcode) {
    final statusStr = json['status']?.toString().toUpperCase() ?? '';
    ScanStatus status = ScanStatus.unknownBarcode;

    if (statusStr == 'FOUND_IN_STORE' || statusStr == 'FOUND' || json['product'] != null) {
      status = ScanStatus.foundInStore;
    } else if (statusStr == 'FOUND_IN_CATALOG' || json['master_product'] != null) {
      status = ScanStatus.foundInCatalog;
    } else {
      status = ScanStatus.unknownBarcode;
    }

    ProductModel? storeProduct;
    if (json['product'] != null) {
      storeProduct = ProductModel.fromJson(json['product'] as Map<String, dynamic>);
    } else if (json['store_product'] != null) {
      storeProduct = ProductModel.fromJson(json['store_product'] as Map<String, dynamic>);
    }

    MasterProductModel? masterProduct;
    if (json['master_product'] != null) {
      masterProduct = MasterProductModel.fromJson(json['master_product'] as Map<String, dynamic>);
    }

    return ScanResultModel(
      status: status,
      barcode: json['barcode']?.toString() ?? scannedBarcode,
      storeProduct: storeProduct,
      masterProduct: masterProduct,
      message: json['message']?.toString() ?? '',
      canRegister: json['can_register'] as bool? ?? false,
      canOnboard: json['can_onboard'] as bool? ?? false,
    );
  }
}
