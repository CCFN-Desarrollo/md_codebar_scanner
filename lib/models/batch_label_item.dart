import 'product_model.dart';

enum BatchItemStatus { loading, ready, error }

/// Renglón de la impresión en lote: el código escaneado, el producto
/// (cuando ya se consultó) y los valores con los que se imprimirá.
class BatchLabelItem {
  static const int defaultFront = 1;
  static const int defaultCopies = 1;

  final String code;
  Product? product;
  BatchItemStatus status;
  String? errorMessage;
  int front;
  int copies;

  BatchLabelItem({
    required this.code,
    this.product,
    this.status = BatchItemStatus.loading,
    this.errorMessage,
    this.front = defaultFront,
    this.copies = defaultCopies,
  });

  bool get isReady => status == BatchItemStatus.ready && product != null;

  /// Total de etiquetas a imprimir (solo renglones listos).
  static int totalLabels(Iterable<BatchLabelItem> items) =>
      items.where((i) => i.isReady).fold(0, (sum, i) => sum + i.copies);

  /// Los renglones que no alcanzaron a resolverse se guardan como `loading`
  /// para volver a consultarlos al cargar la lista.
  Map<String, dynamic> toJson() => {
    'code': code,
    'product': isReady ? product!.toJson() : null,
    'error': status == BatchItemStatus.error ? errorMessage : null,
    'front': front,
    'copies': copies,
  };

  factory BatchLabelItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    final error = json['error']?.toString();
    final product = productJson is Map<String, dynamic>
        ? Product.fromJson(productJson)
        : null;

    return BatchLabelItem(
      code: json['code']?.toString() ?? '',
      product: product,
      status: product != null
          ? BatchItemStatus.ready
          : error != null
          ? BatchItemStatus.error
          : BatchItemStatus.loading,
      errorMessage: error,
      front: (json['front'] as num?)?.toInt() ?? defaultFront,
      copies: (json['copies'] as num?)?.toInt() ?? defaultCopies,
    );
  }
}
