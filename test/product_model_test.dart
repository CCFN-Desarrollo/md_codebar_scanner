import 'package:flutter_test/flutter_test.dart';
import 'package:md_codebar_scanner/models/product_model.dart';

void main() {
  group('Product.fromJson', () {
    test('lee los campos usados en la etiqueta', () {
      final product = Product.fromJson({
        'ItemCode': 'A0107638',
        'ItemName': 'SUST. SPLENDA 24/25 PZ',
        'CodeBars': '7501007531090',
        'ForeignName': 'SUST. SPLENDA 25 PZ',
        'PriceWithTax': 28.9,
        'AvailableUOMs': [
          {'BaseCode': 'PZ', 'BaseQty': 1.0, 'IsDefault': true},
        ],
      });

      expect(product.itemCode, 'A0107638');
      expect(product.codeBar, '7501007531090');
      expect(product.priceWithTax, 28.9);
      expect(product.availableUOMs.single.isDefault, isTrue);
    });
  });

  group('Product.labelTitle', () {
    Product product({required String itemName, required String foreignName}) =>
        Product.empty().copyWith(itemName: itemName, foreignName: foreignName);

    test('usa ForeignName cuando viene informado', () {
      expect(
        product(
          itemName: 'SUST. SPLENDA 24/25 PZ',
          foreignName: ' SUST. SPLENDA 25 PZ ',
        ).labelTitle,
        'SUST. SPLENDA 25 PZ',
      );
    });

    test('usa ItemName cuando ForeignName esta vacio', () {
      expect(
        product(itemName: 'SUST. SPLENDA 24/25 PZ', foreignName: '  ')
            .labelTitle,
        'SUST. SPLENDA 24/25 PZ',
      );
    });
  });
}
