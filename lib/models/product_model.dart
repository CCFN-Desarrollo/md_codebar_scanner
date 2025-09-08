class Product {
  final String sku;
  final String productName;
  final String productSKU;
  final double price;
  final int tax;
  final int discount;

  Product({
    required this.sku,
    required this.productName,
    required this.productSKU,
    required this.price,
    required this.tax,
    required this.discount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      sku: json['sku'],
      productName: json['productName'],
      productSKU: json['productSKU'],
      price: json['price'].toDouble(),
      tax: json['tax'],
      discount: json['discount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'productName': productName,
      'productSKU': productSKU,
      'price': price,
      'tax': tax,
      'discount': discount,
    };
  }
}
