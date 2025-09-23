import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/printer_service.dart';

class ConfigScreen extends StatefulWidget {
  final VoidCallback? onConfigSaved;

  const ConfigScreen({super.key, this.onConfigSaved});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _sucursalController = TextEditingController();
  final TextEditingController _servidorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  // Variables para la impresora que faltaban
  bool _isLoadingPrinters = false;
  String _selectedPrinterAddress = '';
  String _selectedPrinterName = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _sucursalController.dispose();
    _servidorController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _sucursalController.text =
              prefs.getString(AppConstants.prefsSucursal) ?? '';
          _servidorController.text =
              prefs.getString(AppConstants.prefsServidor) ?? '';

          // Cargar configuración de impresora guardada
          _selectedPrinterAddress =
              prefs.getString(AppConstants.prefsSelectedPrinter) ?? '';
          _selectedPrinterName =
              prefs.getString(AppConstants.prefsSelectedPrinterName) ?? '';

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error al cargar la configuración', AppColors.error);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.prefsSucursal,
        _sucursalController.text.trim(),
      );
      await prefs.setString(
        AppConstants.prefsServidor,
        _servidorController.text.trim(),
      );

      // Guardar configuración de impresora
      await prefs.setString(
        AppConstants.prefsSelectedPrinter,
        _selectedPrinterAddress,
      );
      await prefs.setString(
        AppConstants.prefsSelectedPrinterName,
        _selectedPrinterName,
      );

      setState(() {
        _isSaving = false;
      });

      _showSnackBar(AppConstants.successConfigSaved, AppColors.success);

      if (widget.onConfigSaved != null) {
        widget.onConfigSaved!(); // ← Ejecuta inmediatamente al guardar
      }

      // Regresar a la pantalla anterior después de guardar
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showSnackBar('Error al guardar la configuración', AppColors.error);
    }
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

  Future<void> _selectPrinter() async {
    setState(() {
      _isLoadingPrinters = true;
    });

    try {
      // Obtener dispositivos disponibles
      final devices = await PrinterService.getPairedDevices();

      setState(() {
        _isLoadingPrinters = false;
      });

      if (devices.isEmpty) {
        _showSnackBar(
          'No se encontraron impresoras emparejadas',
          AppColors.warning,
        );
        return;
      }

      // Mostrar dialog de selección
      final selectedDevice = await showDialog<BluetoothDevice>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Seleccionar Impresora'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final isCurrentlySelected =
                      device.address == _selectedPrinterAddress;

                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    elevation: isCurrentlySelected ? 2 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: isCurrentlySelected
                          ? BorderSide(color: AppColors.primary, width: 1)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCurrentlySelected
                              ? AppColors.primaryLight
                              : AppColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.print,
                          color: isCurrentlySelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        device.name?.isNotEmpty == true
                            ? device.name!
                            : 'Dispositivo sin nombre',
                        style: TextStyle(
                          fontWeight: isCurrentlySelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.address,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (isCurrentlySelected)
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SELECCIONADA',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () => Navigator.of(context).pop(device),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancelar'),
              ),
            ],
          );
        },
      );

      // Si se seleccionó un dispositivo, guardarlo
      if (selectedDevice != null) {
        setState(() {
          _selectedPrinterAddress = selectedDevice.address;
          _selectedPrinterName = selectedDevice.name?.isNotEmpty == true
              ? selectedDevice.name!
              : 'Dispositivo sin nombre';
        });

        _showSnackBar(
          'Impresora seleccionada: $_selectedPrinterName',
          AppColors.success,
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingPrinters = false;
      });
      _showSnackBar('Error al buscar impresoras: $e', AppColors.error);
    }
  }

  Future<void> _testSelectedPrinter() async {
    if (_selectedPrinterAddress.isEmpty) {
      _showSnackBar('No hay impresora seleccionada', AppColors.warning);
      return;
    }

    // Mostrar dialog de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Probando impresora...'),
          ],
        ),
      ),
    );

    bool dialogClosed = false;

    void closeDialog() {
      if (!dialogClosed && mounted) {
        dialogClosed = true;
        Navigator.of(context).pop();
      }
    }

    try {
      log('🔵 Iniciando prueba de impresora...');

      // Crear dispositivo temporal para la prueba
      final testDevice = BluetoothDevice(
        name: _selectedPrinterName,
        address: _selectedPrinterAddress,
      );

      log('🔵 Conectando a la impresora...');
      final connectResult = await PrinterService.connectToPrinter(testDevice);

      if (connectResult['success']) {
        log('✅ Conexión exitosa, enviando etiqueta de prueba...');

        final printResult = await PrinterService.printTestLabel();
        log('✅ Etiqueta enviada, resultado: ${printResult['success']}');

        // Intentar desconectar con timeout y manejo de errores específico para flutter_bluetooth_serial
        log('🔵 Desconectando impresora...');
        try {
          await PrinterService.disconnect().timeout(
            Duration(seconds: 2), // Timeout total para el método disconnect
            onTimeout: () {
              log('⚠️ Timeout total en disconnect, usando forceDisconnect...');
              PrinterService.forceDisconnect(); // Método de respaldo
            },
          );
          log('✅ Desconexión completada');
        } catch (disconnectError) {
          log('⚠️ Error al desconectar: $disconnectError');
          // Usar desconexión forzada como respaldo
          try {
            await PrinterService.forceDisconnect();
          } catch (e) {
            log('❌ Error en forceDisconnect: $e');
          }
        }

        // Cerrar dialog
        closeDialog();

        // Mostrar resultado
        if (printResult['success']) {
          _showSnackBar('¡Prueba de impresión exitosa!', AppColors.success);
        } else {
          _showSnackBar(
            'Error en la impresión: ${printResult['message']}',
            AppColors.error,
          );
        }
      } else {
        log('❌ Error de conexión: ${connectResult['message']}');
        closeDialog();
        _showSnackBar(
          'Error de conexión: ${connectResult['message']}',
          AppColors.error,
        );
      }
    } catch (e) {
      log('❌ Error general probando impresora: $e');
      closeDialog();
      _showSnackBar('Error probando impresora: $e', AppColors.error);
    }
  }

  void _resetForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning),
              SizedBox(width: 12),
              Text('Confirmar'),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres limpiar todos los campos?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _sucursalController.clear();
                  _servidorController.clear();
                  _selectedPrinterAddress = '';
                  _selectedPrinterName = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: Text('Limpiar'),
            ),
          ],
        );
      },
    );
  }

  String? _validateSucursal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La sucursal es requerida';
    }
    if (value.trim().length < 2) {
      return 'La sucursal debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateServidor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El servidor API es requerido';
    }

    // Validación básica de URL
    // Validación básica de URL
    final urlPattern = RegExp(
      r'^(https?:\/\/)?'
      r'((([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})'
      r'|((\d{1,3}\.){3}\d{1,3}))'
      r'(:\d+)?'
      r'(\/[^\s]*)?$',
      caseSensitive: false,
    );

    if (!urlPattern.hasMatch(value.trim())) {
      return 'Ingresa una URL válida (ej: https://api.ejemplo.com)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading || _isSaving ? null : _loadConfig,
            tooltip: 'Recargar',
          ),
        ],
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
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando configuración...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.settings,
                                size: 48,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Configuración del Sistema',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Configura los parámetros necesarios para el funcionamiento de la aplicación',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),

                        // Campo Sucursal
                        Text(
                          'Información de Sucursal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _sucursalController,
                            enabled: !_isSaving,
                            validator: _validateSucursal,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Nombre de la Sucursal',
                              hintText: 'Ej: Sucursal Centro',
                              prefixIcon: Icon(
                                Icons.store,
                                color: AppColors.primary,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: TextStyle(fontSize: 16),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),

                        SizedBox(height: 24),

                        // Campo Servidor
                        Text(
                          'Configuración de Red',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _servidorController,
                            enabled: !_isSaving,
                            validator: _validateServidor,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Servidor API',
                              hintText: 'https://api.ejemplo.com',
                              prefixIcon: Icon(
                                Icons.cloud,
                                color: AppColors.primary,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'monospace',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                        ),

                        SizedBox(height: 32),

                        // NUEVA SECCIÓN: Configuración de Impresora
                        Text(
                          'Configuración de Impresora',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
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
                              if (_selectedPrinterAddress.isEmpty) ...[
                                // No hay impresora seleccionada
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.print_disabled,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'No hay impresora seleccionada',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                // Impresora seleccionada
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.print,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedPrinterName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _selectedPrinterAddress,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'ACTIVA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              SizedBox(height: 16),

                              // Botones de impresora
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isLoadingPrinters || _isSaving
                                            ? null
                                            : _selectPrinter,
                                        icon: _isLoadingPrinters
                                            ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Icon(
                                                Icons.bluetooth_searching,
                                                size: 18,
                                              ),
                                        label: Text(
                                          _isLoadingPrinters
                                              ? 'Buscando...'
                                              : 'Seleccionar',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_selectedPrinterAddress.isNotEmpty) ...[
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox(
                                        height: 44,
                                        child: OutlinedButton.icon(
                                          onPressed: _isSaving
                                              ? null
                                              : _testSelectedPrinter,
                                          icon: Icon(Icons.print, size: 18),
                                          label: Text(
                                            'Probar',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: BorderSide(
                                              color: AppColors.primary,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),

                        // Información de ayuda
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.info,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Información Importante',
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
                                '• La configuración se guardará automáticamente en el dispositivo\n'
                                '• El servidor API debe ser accesible desde esta red\n'
                                '• La impresora debe estar emparejada por Bluetooth previamente\n'
                                '• Estos datos se utilizarán para conectar con el sistema central',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.info,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40),

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: _isSaving ? null : _resetForm,
                                  icon: Icon(Icons.clear_all),
                                  label: Text('Limpiar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.warning,
                                    side: BorderSide(
                                      color: AppColors.warning,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _saveConfig,
                                  icon: _isSaving
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
                                      : Icon(Icons.save),
                                  label: Text(
                                    _isSaving
                                        ? 'Guardando...'
                                        : 'Guardar Configuración',
                                  ),
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
                                    disabledBackgroundColor: AppColors.primary
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Estado de configuración actual
                        if (_sucursalController.text.isNotEmpty ||
                            _servidorController.text.isNotEmpty ||
                            _selectedPrinterAddress.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Configuración Actual',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                if (_sucursalController.text.isNotEmpty)
                                  Text(
                                    'Sucursal: ${_sucursalController.text}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.success,
                                    ),
                                  ),
                                if (_servidorController.text.isNotEmpty)
                                  Text(
                                    'Servidor: ${_servidorController.text}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.success,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                if (_selectedPrinterAddress.isNotEmpty)
                                  Text(
                                    'Impresora: $_selectedPrinterName',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.success,
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
      ),
    );
  }
}
