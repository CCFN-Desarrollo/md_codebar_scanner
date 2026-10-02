import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/models/batch_label_item.dart';
import 'package:md_codebar_scanner/services/batch_label_controller.dart';
import 'package:md_codebar_scanner/services/printer_service.dart';
import 'package:md_codebar_scanner/utils/colors.dart';
import 'package:md_codebar_scanner/utils/constants.dart';
import 'package:md_codebar_scanner/utils/messages.dart';
import 'package:md_codebar_scanner/utils/print_progress_dialog.dart';
import 'package:md_codebar_scanner/widgets/quantity_stepper.dart';

/// Listado del lote: frente e impresiones editables (1 por defecto) y un solo
/// CTA para imprimir todo. Regresa `true` si se imprimieron todos los productos
/// listos.
class BatchPrintScreen extends StatefulWidget {
  final BatchLabelController batch;

  const BatchPrintScreen({super.key, required this.batch});

  @override
  State<BatchPrintScreen> createState() => _BatchPrintScreenState();
}

class _BatchPrintScreenState extends State<BatchPrintScreen> {
  int _allFront = BatchLabelItem.defaultFront;
  int _allCopies = BatchLabelItem.defaultCopies;
  bool _isPrinting = false;

  BatchLabelController get _batch => widget.batch;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _batch,
      builder: (context, _) {
        final items = _batch.items;

        return Scaffold(
          appBar: AppBar(
            title: Text('Revisar Lote'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        _buildSummary(),
                        SizedBox(height: 12),
                        _buildApplyToAll(),
                        SizedBox(height: 12),
                        ...items.map(_buildItem),
                      ],
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_batch.totalLabels} etiquetas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_batch.readyItems.length} productos',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyToAll() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valores para todos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              QuantityStepper(
                label: 'FRENTE',
                value: _allFront,
                max: AppConstants.batchMaxFront,
                onChanged: (v) => setState(() => _allFront = v),
              ),
              SizedBox(width: 12),
              QuantityStepper(
                label: 'IMPRESIONES',
                icon: Icons.print,
                value: _allCopies,
                max: AppConstants.batchMaxCopies,
                onChanged: (v) => setState(() => _allCopies = v),
              ),
              Spacer(),
              TextButton(
                onPressed: _batch.isEmpty
                    ? null
                    : () => _batch.applyToAll(
                        front: _allFront,
                        copies: _allCopies,
                      ),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: Text('Aplicar\na todos', textAlign: TextAlign.center),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BatchLabelItem item) {
    final product = item.product;
    final isError = item.status == BatchItemStatus.error;

    return Container(
      key: ObjectKey(item),
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.fromLTRB(14, 10, 4, 12),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isError ? AppColors.error : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.isReady
                          ? product!.itemName
                          : isError
                          ? item.errorMessage ?? 'Error'
                          : 'Buscando...',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isError ? AppColors.error : AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      item.isReady
                          ? 'UPC ${item.code} · SKU ${product!.itemCode}'
                          : item.code,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isReady)
                Padding(
                  padding: EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    '\$${product!.priceWithTax.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: _isPrinting ? null : () => _batch.remove(item),
                tooltip: 'Quitar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (item.isReady) ...[
            SizedBox(height: 8),
            Row(
              children: [
                QuantityStepper(
                  label: 'FRENTE',
                  value: item.front,
                  max: AppConstants.batchMaxFront,
                  onChanged: (v) => _batch.setFront(item, v),
                ),
                SizedBox(width: 16),
                QuantityStepper(
                  label: 'IMPRESIONES',
                  icon: Icons.print,
                  value: item.copies,
                  max: AppConstants.batchMaxCopies,
                  onChanged: (v) => _batch.setCopies(item, v),
                ),
                if (product!.promotion != null) ...[
                  Spacer(),
                  Tooltip(
                    message: 'Con promoción: se imprime precio de lista',
                    child: Icon(Icons.local_offer, color: AppColors.warning),
                  ),
                  SizedBox(width: 12),
                ],
              ],
            ),
          ] else if (isError)
            TextButton.icon(
              onPressed: () => _batch.retry(item),
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Reintentar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final totalLabels = _batch.totalLabels;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isPrinting ? null : () => Navigator.pop(context),
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Escanear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.border, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: totalLabels > 0 && !_isPrinting ? _print : null,
                icon: Icon(Icons.print),
                label: Text('Imprimir $totalLabels'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.4,
                  ),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmPendingItems() async {
    if (!_batch.hasPending &&
        !_batch.items.any((i) => i.status == BatchItemStatus.error)) {
      return true;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
            SizedBox(width: 12),
            Text('Productos pendientes'),
          ],
        ),
        content: Text(
          'Hay productos que aún se están consultando o con error. '
          'Solo se imprimirán los productos listos.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Imprimir'),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _print() async {
    if (!await _confirmPendingItems() || !mounted) return;

    final printerInfo = await PrinterService.getPrinterInfo();
    final printerName = printerInfo['name'] ?? '';
    if (!mounted) return;

    if (printerInfo['address']!.isEmpty || printerName.isEmpty) {
      await PrinterService.showPrinterNotConfiguredMessage(
        context,
        'No hay impresora configurada',
      );
      return;
    }

    final items = _batch.readyItems;
    final progress = ValueNotifier('0 de ${items.length} productos');

    setState(() => _isPrinting = true);
    PrintProgressDialog.show(
      context,
      printerName,
      title: 'Imprimiendo lote...',
      progress: progress,
    );

    try {
      final result = await PrinterService.printLabels(
        items,
        onProgress: (printed, total) =>
            progress.value = '$printed de $total productos',
      );

      // Lo impreso sale de la lista; lo pendiente queda para reintentar
      final printedCount = (result['printedCount'] as int?) ?? 0;
      _batch.removeAll(items.take(printedCount));

      if (!mounted) return;
      PrintProgressDialog.close();

      if (result['success'] == true) {
        Navigator.pop(context, true);
      } else if (result['canConfigure'] == true) {
        await PrinterService.showPrinterNotConfiguredMessage(
          context,
          result['message'] ?? 'Error al imprimir',
        );
      } else {
        MessageUtils.showErrorMessage(
          context,
          printedCount > 0
              ? 'Se imprimieron $printedCount de ${items.length} productos. '
                    '${result['message'] ?? ''}'
              : result['message'] ?? 'Error al imprimir',
        );
      }
    } catch (e) {
      PrintProgressDialog.close();
      if (mounted) {
        MessageUtils.showErrorMessage(context, 'Error al imprimir: $e');
      }
    } finally {
      PrintProgressDialog.close();
      if (mounted) setState(() => _isPrinting = false);
    }
  }
}
