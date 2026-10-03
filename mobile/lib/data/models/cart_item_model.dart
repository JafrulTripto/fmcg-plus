import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  double discount;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.discount = 0.0,
  });

  double get unitPrice => product.sellingPrice;
  double get subtotal => unitPrice * quantity;
  double get total => (subtotal - discount).clamp(0.0, double.infinity);

  Map<String, dynamic> toCheckoutItemJson() {
    return {
      'product_id': product.id,
      'barcode': product.barcode,
      'name': product.name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'cost_price': product.costPrice,
      'unit': product.unit,
      'total_price': total,
    };
  }
}
