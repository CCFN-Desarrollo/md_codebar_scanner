import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/models/product_model.dart';
import 'package:md_codebar_scanner/services/api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'product_detail_screen.dart';
import '../services/product_service.dart';
import '../utils/colors.dart';

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
  bool _showCamera = false;
  bool _hasPermission = false;

  MobileScannerController? _scannerController;
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

    if (widget.showManualEntry) {
      _showCamera = false;
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _scanAnimationController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.camera.request();
    }
    return status == PermissionStatus.granted;
  }

  Future<void> _startCamera() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasPermission = await _requestCameraPermission();

      if (!hasPermission) {
        if (mounted) {
          _showSnackBar('Permiso de cámara denegado', AppColors.error);
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      if (mounted) {
        setState(() {
          _hasPermission = true;
          _showCamera = true;
          _isLoading = false;
          _isScanning = true;
        });

        _scanAnimationController.repeat();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error al iniciar la cámara: $e', AppColors.error);
      }
    }
  }

  void _stopCamera() {
    if (_scannerController != null) {
      _scannerController!.dispose();
      _scannerController = null;
    }

    setState(() {
      _showCamera = false;
      _isScanning = false;
    });

    _scanAnimationController.stop();
    _scanAnimationController.reset();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty && !_isLoading) {
      final barcode = barcodes.first;
      final code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        _stopCamera();
        _barcodeController.text = code;
        _searchProduct();
      }
    }
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

        if (result.type == ApiResponseType.success) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailScreen(product: result.data as Product),
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

  void _toggleFlashlight() {
    if (_scannerController != null) {
      _scannerController!.toggleTorch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear Producto'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_showCamera) ...[
            IconButton(
              icon: Icon(Icons.flash_on),
              onPressed: _toggleFlashlight,
              tooltip: 'Flash',
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _stopCamera,
              tooltip: 'Cerrar cámara',
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearInput,
              tooltip: 'Limpiar',
            ),
          ],
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
              child: _showCamera ? _buildCameraView() : _buildManualView(),
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

  Widget _buildCameraView() {
    return Column(
      children: [
        // Vista de la cámara
        Expanded(
          flex: 3,
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                children: [
                  if (_scannerController != null)
                    MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onBarcodeDetected,
                    ),

                  // Overlay de escaneo
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanAnimation.value * 200,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 3,
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

                  // Instrucciones
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Apunta la cámara hacia el código de barras',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Código detectado
        if (_barcodeController.text.isNotEmpty) ...[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Código detectado:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _barcodeController.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],

        // Botón para cambiar a entrada manual
        Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _stopCamera,
              icon: Icon(Icons.keyboard),
              label: Text('Entrada Manual'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualView() {
    return Padding(
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
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: 80,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Entrada Manual',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
                enabled: !_isLoading,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Código de Barras',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.qr_code, color: AppColors.primary),
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
                style: TextStyle(fontSize: 16, fontFamily: 'monospace'),
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
                      onPressed: _isLoading ? null : _startCamera,
                      icon: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(Icons.camera_alt),
                      label: Text(_isLoading ? 'Iniciando...' : 'Usar Cámara'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppColors.primary.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: (_isLoading) ? null : _searchProduct,
                      icon: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : Icon(Icons.search),
                      label: Text(_isLoading ? 'Buscando...' : 'Buscar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledForegroundColor: AppColors.primary.withOpacity(
                          0.6,
                        ),
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
    );
  }
}
