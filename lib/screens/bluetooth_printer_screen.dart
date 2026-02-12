import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/printer_service.dart';
import '../utils/colors.dart';

class BluetoothPrinterScreen extends StatefulWidget {
  const BluetoothPrinterScreen({super.key});

  @override
  State<BluetoothPrinterScreen> createState() => _BluetoothPrinterScreenState();
}

class _BluetoothPrinterScreenState extends State<BluetoothPrinterScreen> {
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String _connectionStatus = '';
  bool _bluetoothAvailable = true;
  bool _bluetoothEnabled = false;
  bool _showAllDevices = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothAndLoadDevices();
  }

  Future<void> _checkBluetoothAndLoadDevices() async {
    // Verificar estado de Bluetooth
    final bluetoothStatus = await PrinterService.checkBluetoothStatus();

    if (mounted) {
      setState(() {
        _bluetoothAvailable = bluetoothStatus['available'];
        _bluetoothEnabled = bluetoothStatus['enabled'];
      });

      if (_bluetoothAvailable && _bluetoothEnabled) {
        await _loadPairedDevices();
      } else {
        _showSnackBar(bluetoothStatus['message'], AppColors.warning);
      }
    }
  }

  Future<void> _loadPairedDevices() async {
    if (!_bluetoothAvailable || !_bluetoothEnabled) {
      _showSnackBar(
        'Bluetooth no está disponible o está apagado',
        AppColors.warning,
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      List<BluetoothDevice> devices;

      if (_showAllDevices) {
        devices = await _getAllPairedDevices();
      } else {
        devices = await PrinterService.getPairedDevices();
      }

      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });

        if (devices.isEmpty) {
          _showSnackBar(
            'No se encontraron dispositivos emparejados',
            AppColors.info,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _showSnackBar('Error al cargar dispositivos: $e', AppColors.error);
      }
    }
  }

  Future<List<BluetoothDevice>> _getAllPairedDevices() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance
          .getBondedDevices();

      log('🔍 TODOS LOS DISPOSITIVOS EMPAREJADOS:');
      for (var device in devices) {
        log('📱 "${device.name}" | ${device.address} | Tipo: ${device.type}');
      }

      return devices.where((device) {
        return (device.name?.isNotEmpty ?? false);
      }).toList()..sort(
        (a, b) => (a.name ?? '').toLowerCase().compareTo(
          (b.name ?? '').toLowerCase(),
        ),
      );
    } catch (e) {
      log('❌ Error obteniendo todos los dispositivos: $e');
      return [];
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Conectando a ${device.name}...';
    });

    try {
      final result = await PrinterService.connectToPrinter(device);

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectionStatus = result['message'];
        });

        if (result['success']) {
          _showSnackBar('Conectado exitosamente', AppColors.success);
          await Future.delayed(Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          _showSnackBar(result['message'], AppColors.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectionStatus = '';
        });
        _showSnackBar('Error de conexión: $e', AppColors.error);
      }
    }
  }

  Future<void> _testPrint() async {
    try {
      final result = await PrinterService.printTestLabel();

      if (result['success']) {
        _showSnackBar('Prueba de impresión enviada', AppColors.success);
      } else {
        _showSnackBar(result['message'], AppColors.error);
      }
    } catch (e) {
      _showSnackBar('Error en prueba: $e', AppColors.error);
    }
  }

  Future<void> _disconnect() async {
    try {
      await PrinterService.disconnect();
      if (mounted) {
        setState(() {});
        _showSnackBar('Desconectado de la impresora', AppColors.info);
      }
    } catch (e) {
      _showSnackBar('Error al desconectar: $e', AppColors.error);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurar Impresora'),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'show_all') {
                setState(() {
                  _showAllDevices = !_showAllDevices;
                });
                _loadPairedDevices();
              } else if (value == 'refresh') {
                _checkBluetoothAndLoadDevices();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'show_all',
                child: Row(
                  children: [
                    Icon(
                      _showAllDevices
                          ? Icons.filter_list_off
                          : Icons.filter_list,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _showAllDevices
                          ? 'Solo impresoras'
                          : 'Todos los dispositivos',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Actualizar lista'),
                  ],
                ),
              ),
            ],
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
        child: Column(
          children: [
            // Estado de Bluetooth
            if (!_bluetoothAvailable || !_bluetoothEnabled) ...[
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning, width: 1),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      color: AppColors.warning,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      !_bluetoothAvailable
                          ? 'Bluetooth no disponible'
                          : 'Bluetooth está apagado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      !_bluetoothAvailable
                          ? 'Este dispositivo no soporta Bluetooth'
                          : 'Por favor activa el Bluetooth en configuración',
                      style: TextStyle(fontSize: 14, color: AppColors.warning),
                      textAlign: TextAlign.center,
                    ),
                    if (!_bluetoothEnabled) ...[
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _checkBluetoothAndLoadDevices,
                        icon: Icon(Icons.refresh),
                        label: Text('Verificar de nuevo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Estado de conexión actual
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PrinterService.isConnected
                    ? AppColors.successLight
                    : AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PrinterService.isConnected
                      ? AppColors.success
                      : AppColors.info,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        PrinterService.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: PrinterService.isConnected
                            ? AppColors.success
                            : AppColors.info,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        PrinterService.isConnected
                            ? 'Impresora Conectada'
                            : 'Sin Conexión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PrinterService.isConnected
                              ? AppColors.success
                              : AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  if (PrinterService.isConnected) ...[
                    SizedBox(height: 8),
                    Text(
                      'Dispositivo: ${PrinterService.connectedDevice?.name ?? 'Desconocido'}',
                      style: TextStyle(fontSize: 14, color: AppColors.success),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testPrint,
                            icon: Icon(Icons.print),
                            label: Text('Imprimir Prueba'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _disconnect,
                            icon: Icon(Icons.bluetooth_disabled),
                            label: Text('Desconectar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_connectionStatus.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Lista de dispositivos
            Expanded(
              child: _isScanning
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
                            'Cargando dispositivos emparejados...',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Esto puede tomar unos segundos',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _devices.isEmpty && _bluetoothEnabled
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_searching,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay dispositivos emparejados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Empareja tu TSC Alpha-3RB desde\nla configuración de Bluetooth de Android',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadPairedDevices,
                            icon: Icon(Icons.refresh),
                            label: Text('Actualizar lista'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isConnected =
                            PrinterService.connectedDevice?.address ==
                            device.address;
                        final deviceName = device.name?.isNotEmpty == true
                            ? device.name!
                            : 'Dispositivo sin nombre';

                        // Detectar si podría ser una impresora TSC
                        final nameL = deviceName.toLowerCase();
                        final addressL = device.address.toLowerCase();
                        final isPossibleTSC =
                            addressL.contains('00:19:0e:a6:04:5d') ||
                            nameL.contains('bt-spp') ||
                            nameL.contains('tsc') ||
                            nameL.contains('alpha') ||
                            nameL.contains('3rb') ||
                            nameL.contains('thermal') ||
                            nameL.contains('print');

                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: isPossibleTSC ? 4 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isPossibleTSC
                                ? BorderSide(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1,
                                  )
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? AppColors.successLight
                                    : isPossibleTSC
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isConnected
                                    ? Icons.bluetooth_connected
                                    : isPossibleTSC
                                    ? Icons.print
                                    : Icons.bluetooth,
                                color: isConnected
                                    ? AppColors.success
                                    : isPossibleTSC
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 24,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    deviceName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isPossibleTSC)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      addressL.contains('00:19:0e:a6:04:5d')
                                          ? 'TU TSC'
                                          : 'POSIBLE TSC',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  'MAC: ${device.address}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      size: 12,
                                      color: AppColors.success,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Emparejado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isConnected) ...[
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'IMPRESORA ACTIVA',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: _isConnecting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                    ),
                                  )
                                : isConnected
                                ? Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                  )
                                : Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: isConnected || _isConnecting
                                ? null
                                : () => _connectToDevice(device),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
