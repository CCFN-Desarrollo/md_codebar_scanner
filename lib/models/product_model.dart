// Modelo principal del producto (actualizado)
class Product {
  final String itemCode;
  final String itemName;
  final String codeBar;
  final String foreignName;
  final double price;
  final double priceWithTax;
  final String currency;
  final int priceList;
  final double taxRate;
  final List<UnitOfMeasure> availableUOMs;
  final Promotion? promotion;

  Product({
    required this.itemCode,
    required this.itemName,
    required this.codeBar,
    required this.foreignName,
    required this.price,
    required this.priceWithTax,
    required this.currency,
    required this.priceList,
    required this.taxRate,
    required this.availableUOMs,
    this.promotion,
  });

  // Constructor para crear un Product vacío
  factory Product.empty() {
    return Product(
      itemCode: '',
      itemName: '',
      codeBar: '',
      foreignName: '',
      price: 0.0,
      priceWithTax: 0.0,
      currency: '',
      priceList: 0,
      taxRate: 0.0,
      availableUOMs: [],
      promotion: null,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      itemCode: json['ItemCode']?.toString() ?? '',
      itemName: json['ItemName']?.toString() ?? '',
      codeBar: json['CodeBars']?.toString() ?? '',
      foreignName: json['ForeignName']?.toString() ?? '',
      price: _parseDouble(json['Price']),
      priceWithTax: _parseDouble(json['PriceWithTax']),
      currency: json['Currency']?.toString() ?? '',
      priceList: _parseInt(json['PriceList']),
      taxRate: _parseDouble(json['TaxRate']),
      availableUOMs: _parseUOMs(json['AvailableUOMs']),
      promotion: _parsePromotion(json['Promotion']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static Promotion? _parsePromotion(dynamic value) {
    if (value == null) return null;
    if (value is! Map<String, dynamic>) return null;

    final map = value as Map<String, dynamic>;

    final hasValidPromotionCode =
        map['PromotionCode'] != null &&
        map['PromotionCode'].toString().trim().isNotEmpty;
    final hasValidStatus =
        map['Status'] != null && map['Status'].toString().trim().isNotEmpty;
    final hasValidPrice =
        map['Price'] != null && _parseDouble(map['Price']) > 0;

    if (!hasValidPromotionCode && !hasValidStatus && !hasValidPrice) {
      return null;
    }

    try {
      return Promotion.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  static List<UnitOfMeasure> _parseUOMs(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    return value
        .where((item) => item is Map<String, dynamic>)
        .map((item) => UnitOfMeasure.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'ItemCode': itemCode,
      'ItemName': itemName,
      'CodeBars': codeBar,
      'ForeignName': foreignName,
      'Price': price,
      'PriceWithTax': priceWithTax,
      'Currency': currency,
      'PriceList': priceList,
      'TaxRate': taxRate,
      'AvailableUOMs': availableUOMs.map((uom) => uom.toJson()).toList(),
      'Promotion': promotion?.toJson(),
    };
  }

  Product copyWith({
    String? itemCode,
    String? itemName,
    String? codeBar,
    String? foreignName,
    double? price,
    double? priceWithTax,
    String? currency,
    int? priceList,
    double? taxRate,
    List<UnitOfMeasure>? availableUOMs,
    Promotion? promotion,
  }) {
    return Product(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      codeBar: codeBar ?? this.codeBar,
      foreignName: foreignName ?? this.foreignName,
      price: price ?? this.price,
      priceWithTax: priceWithTax ?? this.priceWithTax,
      currency: currency ?? this.currency,
      priceList: priceList ?? this.priceList,
      taxRate: taxRate ?? this.taxRate,
      availableUOMs: availableUOMs ?? this.availableUOMs,
      promotion: promotion ?? this.promotion,
    );
  }

  @override
  String toString() {
    return 'Product{itemCode: $itemCode, itemName: $itemName, price: $price}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          itemCode == other.itemCode;

  @override
  int get hashCode => itemCode.hashCode;
}

// Modelo para las unidades de medida
class UnitOfMeasure {
  final String baseCode;
  final String? uomName;
  final int baseQty;
  final bool isDefault;

  UnitOfMeasure({
    required this.baseCode,
    this.uomName,
    required this.baseQty,
    required this.isDefault,
  });

  factory UnitOfMeasure.empty() {
    return UnitOfMeasure(baseCode: '', baseQty: 0, isDefault: false);
  }

  factory UnitOfMeasure.fromJson(Map<String, dynamic> json) {
    return UnitOfMeasure(
      baseCode: json['BaseCode']?.toString() ?? '',
      uomName: json['UomName']?.toString(),
      baseQty: Product._parseInt(json['BaseQty']),
      isDefault: _parseBool(json['IsDefault']),
    );
  }
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      final str = value.toLowerCase().trim();
      return str == 'true' || str == '1' || str == 'yes';
    }
    if (value is int) return value != 0;
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'BaseCode': baseCode,
      'UomName': uomName,
      'BaseQty': baseQty,
      'IsDefault': isDefault,
    };
  }

  UnitOfMeasure copyWith({
    String? baseCode,
    String? uomName,
    int? baseQty,
    bool? isDefault,
  }) {
    return UnitOfMeasure(
      baseCode: baseCode ?? this.baseCode,
      uomName: uomName ?? this.uomName,
      baseQty: baseQty ?? this.baseQty,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'UnitOfMeasure{baseCode: $baseCode, baseQty: $baseQty, isDefault: $isDefault}';
  }
}

// Modelo para las promociones
class Promotion {
  final String promotionCode;
  final String promotionType;
  final String promotionTypeDescription;
  final int hierarchy;
  final String status;
  final String startDate;
  final String endDate;
  final String warehouses;
  final String itemCode;
  final String itemName;
  final String? codeBar;
  final double price;
  final double priceWithTax;
  final double itemsToGetCount;
  final double itemsToPayCount;
  final int discountQty;
  final double discountRate;

  Promotion({
    required this.promotionCode,
    required this.promotionType,
    required this.promotionTypeDescription,
    required this.hierarchy,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.warehouses,
    required this.itemCode,
    required this.itemName,
    this.codeBar,
    required this.price,
    required this.priceWithTax,
    required this.itemsToGetCount,
    required this.itemsToPayCount,
    required this.discountQty,
    required this.discountRate,
  });
  // Constructor para crear una Promotion vacía
  factory Promotion.empty() {
    return Promotion(
      promotionCode: '',
      promotionType: '',
      promotionTypeDescription: '',
      hierarchy: 0,
      status: '',
      startDate: '',
      endDate: '',
      warehouses: '',
      itemCode: '',
      itemName: '',
      codeBar: null,
      price: 0.0,
      priceWithTax: 0.0,
      itemsToGetCount: 0,
      itemsToPayCount: 0,
      discountQty: 0,
      discountRate: 0.0,
    );
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      promotionCode: json['PromotionCode']?.toString() ?? '',
      promotionType: json['PromotionType']?.toString() ?? '',
      promotionTypeDescription:
          json['PromotionTypeDescription']?.toString() ?? '',
      hierarchy: Product._parseInt(json['Hierarchy']),
      status: json['Status']?.toString() ?? '',
      startDate: json['StartDate']?.toString() ?? '',
      endDate: json['EndDate']?.toString() ?? '',
      warehouses: json['Warehouses']?.toString() ?? '',
      itemCode: json['ItemCode']?.toString() ?? '',
      itemName: json['ItemName']?.toString() ?? '',
      codeBar: json['CodeBars']?.toString(),
      price: Product._parseDouble(json['Price']),
      priceWithTax: Product._parseDouble(json['PriceWithTax']),
      itemsToGetCount: Product._parseDouble(json['ItemsToGetCount']),
      itemsToPayCount: Product._parseDouble(json['ItemsToPayCount']),
      discountQty: Product._parseInt(json['DiscountQty']),
      discountRate: Product._parseDouble(json['DiscountRate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PromotionCode': promotionCode,
      'PromotionType': promotionType,
      'PromotionTypeDescription': promotionTypeDescription,
      'Hierarchy': hierarchy,
      'Status': status,
      'StartDate': startDate,
      'EndDate': endDate,
      'Warehouses': warehouses,
      'ItemCode': itemCode,
      'ItemName': itemName,
      'CodeBars': codeBar,
      'Price': price,
      'PriceWithTax': priceWithTax,
      'ItemsToGetCount': itemsToGetCount,
      'ItemsToPayCount': itemsToPayCount,
      'DiscountQty': discountQty,
      'DiscountRate': discountRate,
    };
  }

  bool get isActive => status.toUpperCase() == 'ACTIVA';

  bool isValidForDate(DateTime date) {
    try {
      if (startDate.length < 8 || endDate.length < 8) return false;

      final start = DateTime.parse(
        '${startDate.substring(0, 4)}-${startDate.substring(4, 6)}-${startDate.substring(6, 8)}',
      );
      final end = DateTime.parse(
        '${endDate.substring(0, 4)}-${endDate.substring(4, 6)}-${endDate.substring(6, 8)}',
      );

      return date.isAfter(start.subtract(Duration(days: 1))) &&
          date.isBefore(end.add(Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  List<String> get warehouseList =>
      warehouses.split(', ').map((e) => e.trim()).toList();

  Promotion copyWith({
    String? promotionCode,
    String? promotionType,
    String? promotionTypeDescription,
    int? hierarchy,
    String? status,
    String? startDate,
    String? endDate,
    String? warehouses,
    String? itemCode,
    String? itemName,
    String? codeBar,
    double? price,
    double? priceWithTax,
    double? itemsToGetCount,
    double? itemsToPayCount,
    int? discountQty,
    double? discountRate,
  }) {
    return Promotion(
      promotionCode: promotionCode ?? this.promotionCode,
      promotionType: promotionType ?? this.promotionType,
      promotionTypeDescription:
          promotionTypeDescription ?? this.promotionTypeDescription,
      hierarchy: hierarchy ?? this.hierarchy,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      warehouses: warehouses ?? this.warehouses,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      codeBar: codeBar ?? this.codeBar,
      price: price ?? this.price,
      priceWithTax: priceWithTax ?? this.priceWithTax,
      itemsToGetCount: itemsToGetCount ?? this.itemsToGetCount,
      itemsToPayCount: itemsToPayCount ?? this.itemsToPayCount,
      discountQty: discountQty ?? this.discountQty,
      discountRate: discountRate ?? this.discountRate,
    );
  }

  @override
  String toString() {
    return 'Promotion{promotionCode: $promotionCode, status: $status, price: $price}';
  }
}
