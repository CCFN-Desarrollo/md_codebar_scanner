import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/models/product_model.dart';
import 'package:md_codebar_scanner/services/printer_service.dart';
import 'package:md_codebar_scanner/utils/colors.dart';
import 'package:md_codebar_scanner/utils/messages.dart';
import 'package:md_codebar_scanner/utils/print_progress_dialog.dart';
import 'package:md_codebar_scanner/widgets/custom_slider.dart';
import 'package:md_codebar_scanner/widgets/info_messages.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  double frontNumber = 1; // Mover la variable al estado
  double copies = 1;
  @override
  void initState() {
    super.initState();
    frontNumber = 1.0; // Valor inicial
    copies = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    var promotionType = widget.product.promotion?.promotionType ?? 'NA';
    Product product = widget.product;

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
                              color: Colors.grey.withValues(alpha: 0.1),
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
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
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
                                        product.itemName,
                                        style: TextStyle(
                                          fontSize: 18,
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

                      SizedBox(height: 18),

                      // Información e
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
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

                            CompactCustomSlider(
                              value: frontNumber,
                              onChanged: (value) {
                                setState(() {
                                  frontNumber = value;
                                });
                              },
                              label: 'FRENTE:',
                            ),
                            CompactCustomSlider(
                              value: copies,
                              onChanged: (value) {
                                setState(() {
                                  copies = value;
                                });
                              },
                              label: 'IMPRESIONES:',
                              icon: Icons.print,
                              max: 5,
                              divisions: 4,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Información de descuento
                      if (promotionType != 'NA')
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
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
                                'Información de Descuento',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 16),
                              ...[..._buildDiscountLabel()],
                              SizedBox(height: 12),
                              _buildPriceWithDiscountCalculation(),
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
                              'Precio de Lista',
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

                      if (promotionType != 'NA')
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Expanded(
                            child: InfoMessageBox(
                              message: "Impresión en base a precio de lista",
                              type: InfoMessageType.warning,
                            ),
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
                          onPressed: () => _showPrintLabel(context),
                          icon: Icon(Icons.print),
                          label: Text('Imprimir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppColors.primary.withValues(
                              alpha: 0.3,
                            ),
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
      padding: EdgeInsets.symmetric(vertical: 4),
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
    Product product = widget.product;
    final double basePrice = product.price;

    //product.discount;
    final double tax = product.taxRate;

    //final double priceAfterDiscount = basePrice - discountAmount;
    final double priceAfterDiscount = basePrice;
    final double taxAmount = priceAfterDiscount * (tax / 100);
    final double finalPrice = priceAfterDiscount + taxAmount;

    return Column(
      children: [
        _buildCalculationRow(
          'Precio de lista:',
          '\$${basePrice.toStringAsFixed(2)}',
        ),

        _buildCalculationRow(
          'Impuesto ($tax%):',
          '\$${taxAmount.toStringAsFixed(2)}',
        ),
        Divider(thickness: 1, color: AppColors.border),
        _buildCalculationRow(
          'Precio a Imprimir:',
          '\$${finalPrice.toStringAsFixed(2)}',
          isFinal: true,
        ),
      ],
    );
  }

  Widget _buildPriceWithDiscountCalculation() {
    Product product = widget.product;
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
          'Precio de lista:',
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
          'Precio con Descuento:',
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

  void _showPrintLabel(BuildContext context) async {
    Product product = widget.product;
    if (!context.mounted) return;
    final hasPrinterConfigured = await PrinterService.hasPrinterConfigured();

    if (!hasPrinterConfigured) {
      await PrinterService.showPrinterNotConfiguredMessage(
        context,
        'No hay impresora configurada!',
      );
      return;
    }

    final printerInfo = await PrinterService.getPrinterInfo();
    final printerName = printerInfo['name'] ?? '';

    if (printerName.isEmpty) {
      await PrinterService.showPrinterNotConfiguredMessage(
        context,
        'No hay impresora configurada',
      );
      return;
    }

    PrintProgressDialog.show(context, printerName);

    try {
      final printerDevice = await PrinterService.getConfiguredPrinter();

      if (printerDevice == null) {
        await PrinterService.showPrinterNotConfiguredMessage(
          context,
          'No hay impresora configurada',
        );
        PrintProgressDialog.close();
        return;
      }

      final connectedDevice = await PrinterService.connectToPrinter(
        printerDevice,
      );

      if (!connectedDevice['success']) {
        if (!mounted) return;

        await PrinterService.showPrinterNotConfiguredMessage(
          context,
          'No fue posible conectarse con la impresora. Verifique que esté encendida y disponible.',
        );
        PrintProgressDialog.close();
        return;
      }

      final result = await PrinterService.printProductLabel(
        product,
        frontNumber.round(),
        copies.round(),
      );

      if (result['success']) {
        MessageUtils.showSuccessMessage(
          context,
          'Etiqueta impresa correctamente',
        );
      } else {
        MessageUtils.showErrorMessage(
          context,
          result['message'] ?? 'Error al imprimir',
        );
      }
      if (PrinterService.isConnected) {
        try {
          await PrinterService.disconnect().timeout(
            Duration(seconds: 2),
            onTimeout: () {
              log('⚠️ Timeout en disconnect, usando forceDisconnect...');
              PrinterService.forceDisconnect();
            },
          );
          log('✅ Desconexión completada');
        } catch (disconnectError) {
          log('⚠️ Error al desconectar: $disconnectError');
          try {
            await PrinterService.forceDisconnect();
          } catch (e) {
            log('❌ Error en forceDisconnect: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        MessageUtils.showErrorMessage(context, 'Error al imprimir: $e');
      }
    } finally {
      PrintProgressDialog.close();
    }
  }

  void showMessage(
    BuildContext context,
    String message,
    Color color, {
    bool isError = false,
  }) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error al imprimir: $message')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      log('Error mostrando mensaje: $e');
    }
  }

  List<Widget> _buildDiscountLabel() {
    Product product = widget.product;
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
            '$qty X \$${precioDV.toStringAsFixed(2)}',
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
