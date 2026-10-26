import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:md_codebar_scanner/models/batch_label_item.dart';
import 'package:md_codebar_scanner/models/product_model.dart';
import 'package:md_codebar_scanner/services/api_service.dart';
import 'package:md_codebar_scanner/services/batch_label_controller.dart';
import 'package:md_codebar_scanner/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Product _product(String itemCode, String codeBar) {
  return Product.empty().copyWith(
    itemCode: itemCode,
    itemName: 'PRODUCTO $itemCode',
    codeBar: codeBar,
    priceWithTax: 10,
  );
}

/// Catálogo falso: código de barras → producto.
ProductLookup _lookup(Map<String, Product> catalog) {
  return (code) async {
    final product = catalog[code];
    return product != null
        ? ApiResponse.success(product)
        : ApiResponse.error(message: 'No encontrado', statusCode: 404);
  };
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  final catalog = {
    '111': _product('A1', '111'),
    '222': _product('B2', '222'),
    '333': _product('A1', '333'), // otro código del mismo artículo A1
  };

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('agrega con valores por defecto y resuelve el producto', () async {
    final batch = BatchLabelController(lookup: _lookup(catalog));

    expect(batch.addScan('111'), BatchScanResult.added);
    expect(batch.items.single.status, BatchItemStatus.loading);

    await _settle();

    final item = batch.items.single;
    expect(item.isReady, isTrue);
    expect(item.product!.itemCode, 'A1');
    expect(item.front, 1);
    expect(item.copies, 1);
    expect(batch.totalLabels, 1);
  });

  test(
    're-escanear el mismo código suma una impresión hasta el máximo',
    () async {
      final batch = BatchLabelController(lookup: _lookup(catalog));
      batch.addScan('111');
      await _settle();

      expect(batch.addScan('111'), BatchScanResult.incremented);
      expect(batch.items.single.copies, 2);

      for (var i = 0; i < 20; i++) {
        batch.addScan('111');
      }
      expect(batch.items.single.copies, AppConstants.batchMaxCopies);
      expect(batch.addScan('111'), BatchScanResult.maxReached);
      expect(batch.items, hasLength(1));
    },
  );

  test(
    'otro código del mismo artículo se fusiona sumando impresiones',
    () async {
      final batch = BatchLabelController(lookup: _lookup(catalog));
      batch.addScan('111');
      await _settle();
      batch.addScan('333');
      await _settle();

      expect(batch.items, hasLength(1));
      expect(batch.items.single.code, '111');
      expect(batch.items.single.copies, 2);
    },
  );

  test('código no encontrado queda con error y no cuenta etiquetas', () async {
    final batch = BatchLabelController(lookup: _lookup(catalog));
    batch.addScan('999');
    await _settle();

    final item = batch.items.single;
    expect(item.status, BatchItemStatus.error);
    expect(item.errorMessage, AppConstants.errorProductNotFound);
    expect(batch.readyItems, isEmpty);
    expect(batch.totalLabels, 0);
  });

  test('aplicar a todos respeta los límites', () {
    final batch = BatchLabelController(lookup: _lookup(catalog));
    batch.addScan('111');
    batch.addScan('222');

    batch.applyToAll(front: 3, copies: 50);

    expect(batch.items.every((i) => i.front == 3), isTrue);
    expect(
      batch.items.every((i) => i.copies == AppConstants.batchMaxCopies),
      isTrue,
    );
  });

  test('la lista se guarda y se recupera; eliminar lista la borra', () async {
    final batch = BatchLabelController(lookup: _lookup(catalog));
    batch.addScan('111');
    batch.addScan('222');
    await _settle();
    batch.setCopies(batch.items.last, 4); // '111' quedó al final
    await _settle();

    final restored = BatchLabelController(lookup: _lookup(catalog));
    await restored.load();

    expect(restored.items.map((i) => i.code), ['222', '111']);
    expect(restored.items.every((i) => i.isReady), isTrue);
    expect(restored.items.last.copies, 4);
    expect(restored.totalLabels, 5);

    restored.clear();
    await _settle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.prefsBatchLabels), isNull);
  });

  test('renglones pendientes se vuelven a consultar al cargar', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefsBatchLabels: jsonEncode([
        {
          'code': '222',
          'product': null,
          'error': null,
          'front': 2,
          'copies': 3,
        },
      ]),
    });

    final batch = BatchLabelController(lookup: _lookup(catalog));
    await batch.load();
    await _settle();

    final item = batch.items.single;
    expect(item.isReady, isTrue);
    expect(item.front, 2);
    expect(item.copies, 3);
  });

  test('un renglón eliminado mientras se consulta no reaparece', () async {
    final completer = Completer<ApiResponse<Product>>();
    final batch = BatchLabelController(lookup: (_) => completer.future);

    batch.addScan('111');
    batch.remove(batch.items.single);
    completer.complete(ApiResponse.success(catalog['111']!));
    await _settle();

    expect(batch.isEmpty, isTrue);
  });
}
