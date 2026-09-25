import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/printer_service.dart';
import '../services/zebra_print_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

/// Tarjeta de configuración de impresora: Bluetooth (TSC) o servicio de
/// impresión Zebra por endpoint. Debe ir dentro de un [Form]; la pantalla
/// padre llama a [PrinterSettingsCardState.save] al guardar.
class PrinterSettingsCard extends StatefulWidget {
  final bool enabled;

  const PrinterSettingsCard({super.key, this.enabled = true});

  @override
  State<PrinterSettingsCard> createState() => PrinterSettingsCardState();
}

class PrinterSettingsCardState extends State<PrinterSettingsCard> {
  final TextEditingController _urlController = TextEditingController();

  PrinterType _printerType = PrinterType.bluetooth;
  String _selectedPrinterAddress = '';
  String _selectedPrinterName = '';
  bool _isLoadingPrinters = false;
  bool _isTesting = false;
  bool _isChecking = false;
  String _serviceStatus = '';
  bool? _serviceOk;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _printerType = PrinterType.fromString(
        prefs.getString(AppConstants.prefsPrinterType),
      );
      _selectedPrinterAddress =
          prefs.getString(AppConstants.prefsSelectedPrinter) ?? '';
      _selectedPrinterName =
          prefs.getString(AppConstants.prefsSelectedPrinterName) ?? '';
      _urlController.text =
          prefs.getString(AppConstants.prefsPrintServiceUrl) ?? '';
    });
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString(AppConstants.prefsPrinterType, _printerType.name);
    await prefs.setString(
      AppConstants.prefsSelectedPrinter,
      _selectedPrinterAddress,
    );
    await prefs.setString(
      AppConstants.prefsSelectedPrinterName,
      _selectedPrinterName,
    );
    await prefs.setString(
      AppConstants.prefsPrintServiceUrl,
      _urlController.text.trim().isEmpty
          ? ''
          : ZebraPrintService.normalizeBaseUrl(_urlController.text),
    );
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

      if (!mounted) return;
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

  /// Ejecuta una prueba mostrando un diálogo de progreso.
  Future<void> _runTest(
    String label,
    Future<Map<String, dynamic>> Function() test,
    String successMessage,
  ) async {
    setState(() {
      _isTesting = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(label),
          ],
        ),
      ),
    );

    Map<String, dynamic> result;
    try {
      result = await test();
    } catch (e) {
      result = {'success': false, 'message': 'Error probando impresora: $e'};
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    setState(() {
      _isTesting = false;
    });

    _showSnackBar(
      result['success'] ? successMessage : '${result['message']}',
      result['success'] ? AppColors.success : AppColors.error,
    );
  }

  Future<void> _testBluetoothPrinter() async {
    if (_selectedPrinterAddress.isEmpty) {
      _showSnackBar('No hay impresora seleccionada', AppColors.warning);
      return;
    }

    await _runTest(
      'Probando impresora...',
      () => PrinterService.printTestBluetooth(
        BluetoothDevice(
          name: _selectedPrinterName,
          address: _selectedPrinterAddress,
        ),
      ),
      '¡Prueba de impresión exitosa!',
    );
  }

  bool _validateServiceUrl() {
    final error = ZebraPrintService.validateUrl(_urlController.text);
    if (error != null) {
      _showSnackBar(error, AppColors.warning);
      return false;
    }
    return true;
  }

  Future<void> _checkService() async {
    if (!_validateServiceUrl()) return;

    setState(() {
      _isChecking = true;
      _serviceOk = null;
      _serviceStatus = '';
    });

    final result = await ZebraPrintService.checkStatus(_urlController.text);
    if (!mounted) return;

    setState(() {
      _isChecking = false;
      _serviceOk = result['success'];
      _serviceStatus = result['success']
          ? '${result['printerName']} · Agente v${result['version']}'
          : result['message'];
    });
  }

  Future<void> _testServicePrinter() async {
    if (!_validateServiceUrl()) return;

    await _runTest(
      'Enviando etiqueta de prueba...',
      () => ZebraPrintService.sendZpl(
        _urlController.text,
        ZebraPrintService.buildTestLabelZpl(),
      ),
      '¡Prueba de impresión exitosa!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = !widget.enabled || _isTesting || _isChecking;

    return Container(
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
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<PrinterType>(
              segments: const [
                ButtonSegment(
                  value: PrinterType.bluetooth,
                  label: Text('Bluetooth'),
                  icon: Icon(Icons.bluetooth),
                ),
                ButtonSegment(
                  value: PrinterType.endpoint,
                  label: Text('Servicio'),
                  icon: Icon(Icons.lan),
                ),
              ],
              selected: {_printerType},
              onSelectionChanged: busy
                  ? null
                  : (selection) {
                      setState(() {
                        _printerType = selection.first;
                      });
                    },
            ),
          ),
          SizedBox(height: 16),
          if (_printerType == PrinterType.bluetooth)
            ..._buildBluetoothSection(busy)
          else
            ..._buildServiceSection(busy),
        ],
      ),
    );
  }

  List<Widget> _buildBluetoothSection(bool busy) {
    return [
      if (_selectedPrinterAddress.isEmpty)
        _buildEmptyState()
      else
        _buildSelectedPrinter(_selectedPrinterName, _selectedPrinterAddress),
      SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildPrimaryButton(
              onPressed: _isLoadingPrinters || busy ? null : _selectPrinter,
              icon: Icons.bluetooth_searching,
              label: _isLoadingPrinters ? 'Buscando...' : 'Seleccionar',
              loading: _isLoadingPrinters,
            ),
          ),
          if (_selectedPrinterAddress.isNotEmpty) ...[
            SizedBox(width: 12),
            Expanded(
              child: _buildOutlinedButton(
                onPressed: busy ? null : _testBluetoothPrinter,
                icon: Icons.print,
                label: 'Probar',
              ),
            ),
          ],
        ],
      ),
      SizedBox(height: 12),
      _buildHelpText(
        'La impresora debe estar encendida y emparejada por Bluetooth previamente.',
      ),
    ];
  }

  List<Widget> _buildServiceSection(bool busy) {
    return [
      TextFormField(
        controller: _urlController,
        enabled: !busy,
        keyboardType: TextInputType.url,
        autocorrect: false,
        validator: (value) => _printerType == PrinterType.endpoint
            ? ZebraPrintService.validateUrl(value)
            : null,
        onChanged: (_) {
          if (_serviceOk != null) {
            setState(() {
              _serviceOk = null;
              _serviceStatus = '';
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'URL del servicio de impresión',
          hintText: '192.168.0.10:${AppConstants.defaultPrintServicePort}',
          prefixIcon: Icon(Icons.lan, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
      if (_serviceOk != null) ...[
        SizedBox(height: 12),
        Row(
          children: [
            Icon(
              _serviceOk! ? Icons.check_circle : Icons.error_outline,
              color: _serviceOk! ? AppColors.success : AppColors.error,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _serviceStatus,
                style: TextStyle(
                  fontSize: 13,
                  color: _serviceOk! ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ],
      SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildPrimaryButton(
              onPressed: busy ? null : _checkService,
              icon: Icons.wifi_find,
              label: _isChecking ? 'Verificando...' : 'Verificar',
              loading: _isChecking,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildOutlinedButton(
              onPressed: busy ? null : _testServicePrinter,
              icon: Icons.print,
              label: 'Probar',
            ),
          ),
        ],
      ),
      SizedBox(height: 12),
      _buildHelpText(
        'Use la IP de la PC de la tienda donde corre el Scanner Agent '
        '(no localhost). El celular debe estar en la misma red WiFi.',
      ),
    ];
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.print_disabled, size: 48, color: Colors.grey[400]),
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
    );
  }

  Widget _buildSelectedPrinter(String name, String address) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.print, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool loading = false,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(label, style: TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: TextStyle(fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildHelpText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
