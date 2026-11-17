import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/batch_label_item.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'product_service.dart';

enum BatchScanResult { added, incremented, maxReached }

typedef ProductLookup = Future<ApiResponse<Product>> Function(String code);

/// Estado de la impresión en lote, compartido por la pantalla de escaneo y la
/// de listado. Cada cambio se guarda en el dispositivo para no perder la lista.
class BatchLabelController extends ChangeNotifier {
  final ProductLookup _lookup;
  final List<BatchLabelItem> _items = [];

  /// Se llama cuando un código no se encuentra o falla la consulta.
  void Function(BatchLabelItem item)? onLookupFailed;

  BatchLabelController({ProductLookup? lookup})
    : _lookup = lookup ?? ProductService.getCode;

  List<BatchLabelItem> get items => List.unmodifiable(_items);
  List<BatchLabelItem> get readyItems =>
      _items.where((i) => i.isReady).toList();
  bool get isEmpty => _items.isEmpty;
  bool get hasPending => _items.any((i) => i.status == BatchItemStatus.loading);
  int get totalLabels => BatchLabelItem.totalLabels(_items);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.prefsBatchLabels);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _items
        ..clear()
        ..addAll(
          decoded.whereType<Map<String, dynamic>>().map(
            BatchLabelItem.fromJson,
          ),
        );
      notifyListeners();

      for (final item in _items.where(
        (i) => i.status == BatchItemStatus.loading,
      )) {
        _resolve(item);
      }
    } catch (e) {
      log('Error cargando lista de lote: $e');
    }
  }

  /// Agrega un código escaneado. Si ya está en la lista suma una impresión.
  BatchScanResult addScan(String rawCode) {
    final code = rawCode.trim();
    final existing = _findByCode(code);

    if (existing != null) {
      if (existing.copies >= AppConstants.batchMaxCopies) {
        return BatchScanResult.maxReached;
      }
      existing.copies++;
      _changed();
      return BatchScanResult.incremented;
    }

    final item = BatchLabelItem(code: code);
    _items.insert(0, item);
    _changed();
    _resolve(item);
    return BatchScanResult.added;
  }

  void retry(BatchLabelItem item) {
    if (!_items.contains(item)) return;
    item
      ..status = BatchItemStatus.loading
      ..errorMessage = null;
    _changed();
    _resolve(item);
  }

  void setFront(BatchLabelItem item, int value) {
    item.front = value.clamp(1, AppConstants.batchMaxFront);
    _changed();
  }

  void setCopies(BatchLabelItem item, int value) {
    item.copies = value.clamp(1, AppConstants.batchMaxCopies);
    _changed();
  }

  void applyToAll({required int front, required int copies}) {
    for (final item in _items) {
      item.front = front.clamp(1, AppConstants.batchMaxFront);
      item.copies = copies.clamp(1, AppConstants.batchMaxCopies);
    }
    _changed();
  }

  void remove(BatchLabelItem item) {
    _items.remove(item);
    _changed();
  }

  void removeAll(Iterable<BatchLabelItem> items) {
    final toRemove = items.toSet();
    _items.removeWhere(toRemove.contains);
    _changed();
  }

  void clear() {
    _items.clear();
    _changed();
  }

  BatchLabelItem? _findByCode(String code) {
    for (final item in _items) {
      if (item.code == code || item.product?.codeBar == code) return item;
    }
    return null;
  }

  Future<void> _resolve(BatchLabelItem item) async {
    try {
      final result = await _lookup(item.code);
      if (!_items.contains(item)) return; // se eliminó mientras se consultaba

      if (result.type == ApiResponseType.success && result.data != null) {
        final product = result.data!;
        final duplicate = _items.where(
          (i) =>
              !identical(i, item) &&
              i.isReady &&
              i.product!.itemCode == product.itemCode,
        );

        // Otro código de barras del mismo artículo: se suman las impresiones
        if (duplicate.isNotEmpty) {
          final target = duplicate.first;
          target.copies = (target.copies + item.copies).clamp(
            1,
            AppConstants.batchMaxCopies,
          );
          _items.remove(item);
        } else {
          item
            ..product = product
            ..status = BatchItemStatus.ready;
        }
      } else {
        item
          ..status = BatchItemStatus.error
          ..errorMessage =
              result.type == ApiResponseType.timeout ||
                  result.type == ApiResponseType.networkError
              ? AppConstants.errorNetworkConnection
              : AppConstants.errorProductNotFound;
      }
    } catch (e) {
      if (!_items.contains(item)) return;
      item
        ..status = BatchItemStatus.error
        ..errorMessage = AppConstants.errorNetworkConnection;
    }
    if (item.status == BatchItemStatus.error && !_disposed) {
      onLookupFailed?.call(item);
    }
    _changed();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _changed() {
    // Una consulta puede terminar después de salir de la pantalla: no se
    // guarda para no pisar la lista de otra instancia; el renglón quedó
    // guardado como pendiente y se vuelve a consultar al cargar.
    if (_disposed) return;
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_items.isEmpty) {
        await prefs.remove(AppConstants.prefsBatchLabels);
      } else {
        await prefs.setString(
          AppConstants.prefsBatchLabels,
          jsonEncode(_items.map((i) => i.toJson()).toList()),
        );
      }
    } catch (e) {
      log('Error guardando lista de lote: $e');
    }
  }
}
