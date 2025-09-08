import 'package:flutter/material.dart';
import 'dart:async';
import 'product_detail_screen.dart';
import 'package:md_codebar_scanner/models/product_model.dart';
import 'package:md_codebar_scanner/services/product_service.dart';
import 'package:md_codebar_scanner/utils/colors.dart';

class ScannerScreen extends StatefulWidget {
  final bool showManualEntry;

  const ScannerScreen({Key? key, this.showManualEntry = false})
    : super(key: key);

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  final TextEditingController _barcodeController = TextEditingController();
  bool _isLoading = false;
  bool _showNotFound = false;
  bool _isScanning = false;
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  void _simulateScan() {
    setState(() {
      _isScanning = true;
    });

    _scanAnimationController.repeat();

    // Simula el proceso de escaneo
    Timer(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _scanAnimationController.stop();
        _scanAnimationController.reset();

        // Genera un código aleatorio para demostración
        final codes = ['12345', '67890', '11111', '22222', '33333', '99999'];
        final randomCode = codes[DateTime.now().millisecond % codes.length];
        _barcodeController.text = randomCode;

        // Busca automáticamente después del escaneo
        _searchProduct();
      }
    });
  }

  void _searchProduct() async {
    if (_barcodeController.text.isEmpty) {
      _showSnackBar('Por favor ingresa un código de barras', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _showNotFound = false;
    });

    try {
      final result = await ProductService.getCode(_barcodeController.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['status'] == 'success') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailScreen(product: result['data'] as Product),
            ),
          );
        } else {
          _showProductNotFound();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error al buscar el producto', AppColors.error);
      }
    }
  }

  void _showProductNotFound() {
    setState(() {
      _showNotFound = true;
    });

    Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showNotFound = false;
        });
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _clearInput() {
    _barcodeController.clear();
    setState(() {
      _showNotFound = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear Producto'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearInput,
            tooltip: 'Limpiar',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey[50]!, Colors.white],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (!_showNotFound) ...[
                      // Área de escaneo visual
                      Expanded(
                        flex: 2,
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isScanning
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isScanning
                                          ? Icons.qr_code_scanner
                                          : Icons.qr_code_2,
                                      size: 80,
                                      color: _isScanning
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      _isScanning
                                          ? 'Escaneando...'
                                          : 'Área de Escaneo',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _isScanning
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isScanning)
                                AnimatedBuilder(
                                  animation: _scanAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: _scanAnimation.value * 200,
                                      left: 20,
                                      right: 20,
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              AppColors.primary,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Campo de entrada manual
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _barcodeController,
                          enabled: !_isLoading && !_isScanning,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            labelText: 'Código de Barras',
                            labelStyle: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.qr_code,
                              color: AppColors.primary,
                            ),
                            suffixIcon: _barcodeController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: _clearInput,
                                  )
                                : null,
                            hintText: 'Ingresa el código manualmente',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onSubmitted: (_) => _searchProduct(),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: (_isLoading || _isScanning)
                                    ? null
                                    : _simulateScan,
                                icon: _isScanning
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Icon(Icons.camera_alt),
                                label: Text(
                                  _isScanning ? 'Escaneando...' : 'Escanear',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: AppColors.primary
                                      .withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: (_isLoading || _isScanning)
                                    ? null
                                    : _searchProduct,
                                icon: _isLoading
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.primary,
                                              ),
                                        ),
                                      )
                                    : Icon(Icons.search),
                                label: Text(
                                  _isLoading ? 'Buscando...' : 'Buscar',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledForegroundColor: AppColors.primary
                                      .withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Información de códigos de prueba
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.info,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Códigos de prueba:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '12345, 67890, 11111, 22222, 33333',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.info,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Overlay de producto no encontrado
          if (_showNotFound)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: EdgeInsets.all(40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.error,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Producto no encontrado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'El código "${_barcodeController.text}" no existe en el sistema',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        LinearProgressIndicator(
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Este mensaje se cerrará automáticamente',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
