import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/models/product_model.dart';
import 'package:md_codebar_scanner/screens/bluetooth_printer_screen.dart';
import 'package:md_codebar_scanner/services/printer_service.dart';
import 'package:md_codebar_scanner/utils/colors.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Producto'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado del producto
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Producto Encontrado',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        product.itemName,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Información del producto
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información del Producto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildDetailRow(
                              'UPC:',
                              product.codeBar.toString(),
                              Icons.qr_code_2,
                            ),
                            _buildDetailRow(
                              'SKU:',
                              product.itemCode.toString(),
                              Icons.qr_code_2,
                            ),
                            _buildDetailRow(
                              'Precio:',
                              '\$${product.price.toStringAsFixed(2)}',
                              Icons.attach_money,
                            ),
                            _buildDetailRow(
                              'Impuesto:',
                              '${product.taxRate.toString()}%',
                              Icons.receipt_long,
                            ),

                            ...[..._buildDiscountLabel()],
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Cálculos de precio
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cálculo de Precio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildPriceCalculation(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back),
                          label: Text('Regresar'),
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
                    SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _showPrintPreview(context),
                          icon: Icon(Icons.print),
                          label: Text('Reimprimir Recibo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppColors.primary.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCalculation() {
    final double basePrice = product.price;

    //product.discount;
    final double tax = product.taxRate;

    double discountAmount = 0;
    double newPrice = product.promotion?.price ?? 0;

    if (product.promotion?.price != null && product.promotion!.price > 0) {
      discountAmount = product.price - product.promotion!.price;
    }
    //final double priceAfterDiscount = basePrice - discountAmount;
    final double priceAfterDiscount = basePrice - discountAmount;
    final double taxAmount = priceAfterDiscount * (tax / 100);
    final double finalPrice = priceAfterDiscount + taxAmount;

    double discount = 0;
    String tipoPromocion = product.promotion?.promotionType ?? 'NA';
    if (tipoPromocion == 'PU' || tipoPromocion == 'PV') {
      discount = 100 - (newPrice / basePrice * 100);
    }
    return Column(
      children: [
        _buildCalculationRow(
          'Precio base:',
          '\$${basePrice.toStringAsFixed(2)}',
        ),
        if (discount > 0.0) ...[
          _buildCalculationRow(
            'Descuento (${discount.toStringAsFixed(2)}%):',
            '-\$${discountAmount.toStringAsFixed(2)}',
            isDiscount: true,
          ),
          _buildCalculationRow(
            'Subtotal:',
            '\$${priceAfterDiscount.toStringAsFixed(2)}',
          ),
        ],
        _buildCalculationRow(
          'Impuesto ($tax%):',
          '\$${taxAmount.toStringAsFixed(2)}',
        ),
        Divider(thickness: 1, color: AppColors.border),
        _buildCalculationRow(
          'Precio final:',
          '\$${finalPrice.toStringAsFixed(2)}',
          isFinal: true,
        ),
      ],
    );
  }

  Widget _buildCalculationRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isFinal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isFinal ? 16 : 14,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w500,
              color: isFinal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isFinal ? 16 : 14,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w600,
              color: isDiscount
                  ? AppColors.success
                  : isFinal
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.print, color: AppColors.primary, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Imprimir Etiqueta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Estado de la impresora
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PrinterService.isConnected
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: PrinterService.isConnected
                          ? AppColors.success
                          : AppColors.warning,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PrinterService.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: PrinterService.isConnected
                            ? AppColors.success
                            : AppColors.warning,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          PrinterService.isConnected
                              ? 'Conectado: ${PrinterService.connectedDevice?.name}'
                              : 'Sin conexión a impresora',
                          style: TextStyle(
                            fontSize: 14,
                            color: PrinterService.isConnected
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Vista previa de la etiqueta
                Container(
                  width: 250,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título del recibo
                      Text(
                        product.itemName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Código de barras simulado
                      Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '|||  ||  ||  |||  ||  |  ||  |||',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          product.codeBar,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Precio
                      Center(
                        child: Text(
                          '\$${product.priceWithTax.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Información adicional
                      Text(
                        'Impuesto: ${product.taxRate}%',
                        style: TextStyle(fontSize: 10),
                      ),
                      if (0 > 0)
                        Text(
                          'Descuento: ${0}%',
                          style: TextStyle(fontSize: 10),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    if (!PrinterService.isConnected) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showBluetoothSettings(context);
                          },
                          icon: Icon(Icons.bluetooth),
                          label: Text('Configurar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                    ],
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cerrar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: PrinterService.isConnected
                            ? () => _showPrintLabel(context)
                            : null,
                        child: Text('Imprimir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBluetoothSettings(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BluetoothPrinterScreen()),
    );

    // Si se conectó exitosamente, mostrar el dialog de impresión nuevamente
    if (result == true) {
      _showPrintPreview(context);
    }
  }

  void _showPrintLabel(BuildContext context) async {
    Navigator.of(context).pop(); // Cerrar el dialog de vista previa

    // Mostrar indicador de impresión consistente con el resto de la app
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Imprimiendo etiqueta...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Verificar conexión antes de imprimir
      if (!PrinterService.isConnected) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La impresora se ha desconectado'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      // Imprimir la etiqueta del producto
      final result = await PrinterService.printProductLabel(product);

      Navigator.of(context).pop(); // Cerrar dialog de progreso

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Etiqueta impresa correctamente'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(result['message'] ?? 'Error al imprimir')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar dialog de progreso

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error al imprimir: $e')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  List<Widget> _buildDiscountLabel() {
    final double priceWithTax = product.priceWithTax;
    var promotionType = product.promotion?.promotionType ?? 'NA';

    switch (promotionType) {
      case 'DV':
        int qty = product.promotion?.discountQty ?? 0;
        double finalPrice = qty * priceWithTax;
        double discountRate = product.promotion?.discountRate ?? 0;
        double precioDV = finalPrice - (finalPrice * discountRate / 100);
        return [
          _buildDetailRow(
            'Descuento por volumen:',
            '${qty} X \$${precioDV.toStringAsFixed(2)}',
            Icons.local_offer,
          ),
        ];
      case 'AB':
        return [
          _buildDetailRow(
            'Promoción:',
            '${product.promotion!.itemsToGetCount.toInt()} X ${product.promotion!.itemsToPayCount.toInt()}',
            Icons.local_offer,
          ),
        ];
      case 'PU':
        return [_buildRow('Descuento por Precio Único', Icons.local_offer)];
      case 'PV':
        return [
          _buildRow('Descuento por Politica de Venta', Icons.local_offer),
        ];
      default:
        return [Container()];
    }
  }
}
