import '../models/product_model.dart';

class ProductService {
  static final List<Product> _products = [
    Product(
      sku: '12345',
      productName: 'Producto Ejemplo 1',
      productSKU: '12345',
      price: 29.99,
      tax: 16,
      discount: 5,
    ),
    Product(
      sku: '12345',
      productName: 'Producto Ejemplo 1',
      productSKU: '12345',
      price: 29.99,
      tax: 8,
      discount: 0,
    ),
    Product(
      sku: '22222',
      productName: 'Producto Ejemplo 2',
      productSKU: '22222',
      price: 99.99,
      tax: 8,
      discount: 0,
    ),
    Product(
      sku: '33333',
      productName: 'Producto Ejemplo 3',
      productSKU: '33333',
      price: 53.99,
      tax: 0,
      discount: 5,
    ),
    Product(
      sku: '44444',
      productName: 'Producto Ejemplo 1',
      productSKU: '44444',
      price: 63.12,
      tax: 0,
      discount: 8,
    ),
    // ... otros productos
  ];

  static Future<Map<String, dynamic>> getCode(String sku) async {
    await Future.delayed(Duration(milliseconds: 500));

    try {
      final product = _products.firstWhere((p) => p.sku == sku);
      return {'status': 'success', 'data': product};
    } catch (e) {
      return {'status': 'not_found'};
    }
  }
}
