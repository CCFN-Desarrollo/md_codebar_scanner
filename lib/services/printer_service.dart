import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:md_codebar_scanner/screens/config_printer_screen.dart';
import 'package:md_codebar_scanner/utils/colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

class PrinterService {
  static BluetoothConnection? _connection;
  static bool _isConnected = false;
  static BluetoothDevice? _connectedDevice;
  static String _connectionStatus = '';

  static Future<bool> requestBluetoothPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();

      return statuses.values.any((status) => status.isGranted);
    } catch (e) {
      return true; // En versiones antiguas de Android, los permisos no son necesarios
    }
  }

  static Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      await requestBluetoothPermissions();

      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled != true) {
        throw Exception('Bluetooth está desactivado');
      }

      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance
          .getBondedDevices();

      final filteredDevices = devices.where((device) {
        final name = device.name?.toLowerCase() ?? '';
        final address = device.address.toLowerCase();

        // Buscar específicamente nuestro dispositivo TSC
        if (address.contains('00:19:0e:a6:04:5d') ||
            name.contains('bt-spp') ||
            name.contains('btspp')) {
          return true;
        }

        // Otros filtros para impresoras
        if (name.isNotEmpty &&
            (
            // Nombres específicos de TSC
            name.contains('tsc') ||
                name.contains('alpha') ||
                name.contains('3rb') ||
                name.contains('alpha-3rb') ||
                name.contains('alpha3rb') ||
                // SPP y otros protocolos de impresoras
                name.contains('spp') ||
                name.contains('serial') ||
                // Otros nombres comunes de impresoras
                name.contains('thermal') ||
                name.contains('printer') ||
                name.contains('print') ||
                name.contains('label') ||
                name.contains('pos') ||
                // Nombres genéricos de impresoras
                name.contains('bt') ||
                // Dispositivos con números (posibles modelos)
                RegExp(r'[0-9]').hasMatch(name) ||
                // Mostrar dispositivos con nombres válidos
                (name.length >= 2 && !name.contains('unknown')))) {
          log(' DISPOSITIVO INCLUIDO: $name - $address');
          return true;
        }

        log('DISPOSITIVO FILTRADO: $name - $address');
        return false;
      }).toList();

      // Ordenar: nuestro TSC primero, luego otros
      filteredDevices.sort((a, b) {
        final aName = a.name?.toLowerCase() ?? '';
        final bName = b.name?.toLowerCase() ?? '';
        final aAddress = a.address.toLowerCase();
        final bAddress = b.address.toLowerCase();

        final aIsOurTSC =
            aAddress.contains('00:19:0e:a6:04:5d') || aName.contains('bt-spp');
        final bIsOurTSC =
            bAddress.contains('00:19:0e:a6:04:5d') || bName.contains('bt-spp');

        if (aIsOurTSC && !bIsOurTSC) return -1;
        if (!aIsOurTSC && bIsOurTSC) return 1;

        final aIsTSC =
            aName.contains('tsc') ||
            aName.contains('alpha') ||
            aName.contains('3rb');
        final bIsTSC =
            bName.contains('tsc') ||
            bName.contains('alpha') ||
            bName.contains('3rb');

        if (aIsTSC && !bIsTSC) return -1;
        if (!aIsTSC && bIsTSC) return 1;

        // Ordenar alfabéticamente
        return aName.compareTo(bName);
      });

      log('DISPOSITIVOS FINALES FILTRADOS: ${filteredDevices.length}');
      return filteredDevices;
    } catch (e) {
      log('Error obteniendo dispositivos: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> connectToPrinter(
    BluetoothDevice device,
  ) async {
    try {
      _connectionStatus = 'Conectando...';

      if (_isConnected) {
        await disconnect();
      }

      log('Conectando a: ${device.name} (${device.address})');

      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      _isConnected = true;
      _connectionStatus = 'Conectado';

      log('Conexión establecida con ${device.name}');

      await _sendRawData(_getTSCInitCommands());

      return {
        'success': true,
        'message': 'Conectado a ${device.name}',
        'device': device.name,
      };
    } catch (e) {
      _isConnected = false;
      _connection = null;
      _connectedDevice = null;
      _connectionStatus = 'Error de conexión';

      return {
        'success': false,
        'message': 'Error al conectar: ${e.toString()}',
      };
    }
  }

  static Future<void> disconnect() async {
    try {
      if (_connection != null) {
        await _connection!.close();
        log('🔌 Desconectado de la impresora');
      }
    } catch (e) {
      log('Error al desconectar: $e');
    } finally {
      _connection = null;
      _isConnected = false;
      _connectedDevice = null;
      _connectionStatus = '';
    }
  }

  static Future<void> forceDisconnect() async {
    log('🚨 Forzando desconexión...');
    _connection = null;
    _isConnected = false;
    _connectedDevice = null;
    _connectionStatus = 'Desconectado (forzado)';
    log('✅ Desconexión forzada completada');
  }

  static bool get isConnected => _isConnected && _connection != null;

  static BluetoothDevice? get connectedDevice => _connectedDevice;

  static String get connectionStatus => _connectionStatus;

  static Future<Map<String, dynamic>> printProductLabel(
    Product product,
    int front,
    int copies,
  ) async {
    try {
      if (!isConnected) {
        return {
          'success': false,
          'message': 'No hay conexión con la impresora',
        };
      }

      String tscCommands = _generateTscLabel(product, front, copies);

      await _sendRawData(tscCommands);

      return {'success': true, 'message': 'Etiqueta impresa correctamente'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al imprimir: ${e.toString()}',
      };
    }
  }

  static String _generateTscLabel(Product product, int front, int copies) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final String date = DateFormat('dd/MM/yyyy').format(now);

    buffer.writeln(
      'SIZE 75 mm,25 mm',
    ); // Tamaño etiqueta (ajustar si tu etiqueta es distinta)
    buffer.writeln('GAP 2 mm,0'); // Separación entre etiquetas
    buffer.writeln('CLS'); // Limpia buffer
    buffer.writeln('DIRECTION 1,0');
    buffer.writeln('REFERENCE 0,0');
    buffer.writeln('OFFSET 0 mm');
    buffer.writeln('SET TEAR ON');
    buffer.writeln(
      'TEXT 0,15,"3",0,1,3,"\$ ${product.priceWithTax.toStringAsFixed(2)}"',
    );
    _addTwoLines(buffer, product.itemName, 140, 15, "3", 26);

    buffer.writeln('BARCODE 220,88,"128",45,4,0,2,3,"${product.codeBar}"');
    String temp = "F$front  f $date";
    buffer.writeln('TEXT 388,168,"1",0,1,1,"$temp"');

    buffer.writeln('PRINT 1,$copies');
    return buffer.toString();
  }

  static void _addTwoLines(
    StringBuffer commands,
    String text,
    int x,
    int startY,
    String font,
    int maxCharsPerLine,
  ) {
    if (text.length <= maxCharsPerLine) {
      commands.writeln('TEXT $x,$startY,"$font",0,1,1,"$text"');
      return;
    }

    final firstLine = text.substring(0, maxCharsPerLine);
    commands.writeln('TEXT $x,$startY,"$font",0,1,1,"$firstLine"');

    final secondLine = text.length > maxCharsPerLine * 2
        ? text.substring(maxCharsPerLine, maxCharsPerLine * 2 - 3) + '...'
        : text.substring(maxCharsPerLine);

    commands.writeln('TEXT $x,${startY + 35},"$font",0,1,1,"$secondLine"');
  }

  /// Comandos de inicialización para impresora TSC
  static String _getTSCInitCommands() {
    return '''
SETUP
CLS
''';
  }

  static Future<void> _sendRawData(String data) async {
    if (_connection == null) {
      throw Exception('No hay conexión establecida');
    }

    try {
      log('Enviando datos: ${data.length} caracteres');

      Uint8List bytes = Uint8List.fromList(utf8.encode(data));

      _connection!.output.add(bytes);
      await _connection!.output.allSent;

      log('Datos enviados correctamente');
    } catch (e) {
      log('Error enviando datos: $e');
      throw Exception('Error al enviar datos: $e');
    }
  }

  /// Imprime una etiqueta de prueba
  static Future<Map<String, dynamic>> printTestLabel() async {
    try {
      if (!isConnected) {
        return {
          'success': false,
          'message': 'No hay conexión con la impresora',
        };
      }

      final buffer = StringBuffer();

      buffer.writeln(
        'SIZE 75 mm,25 mm',
      ); // Tamaño etiqueta (ajustar si tu etiqueta es distinta)
      buffer.writeln('GAP 2 mm,0'); // Separación entre etiquetas
      buffer.writeln('CLS'); // Limpia buffer
      buffer.writeln('DIRECTION 1,0');
      buffer.writeln('REFERENCE 0,0');
      buffer.writeln('OFFSET 0 mm');
      buffer.writeln('SET TEAR ON');
      buffer.writeln('TEXT 0,20,"3",0,1,3,"\$ 0.0"');
      _addTwoLines(
        buffer,
        "dolor sit amet, consectetur adipiscing elit",
        140,
        20,
        "3",
        26,
      );

      buffer.writeln('BARCODE 220,80,"128",45,4,0,2,3,"1234567890"');
      buffer.writeln('TEXT 320,160,"1",0,1,1,"F1  f.15/09/2025"');

      buffer.writeln('PRINT 1,1');
      await _sendRawData(buffer.toString());

      return {'success': true, 'message': 'Etiqueta de prueba enviada'};
    } catch (e) {
      return {'success': false, 'message': 'Error en prueba: ${e.toString()}'};
    }
  }

  /// Obtiene el estado detallado de la impresora
  static Future<Map<String, dynamic>> getPrinterStatus() async {
    try {
      if (!isConnected || _connectedDevice == null) {
        return {
          'connected': false,
          'device': null,
          'status': 'Desconectada',
          'connectionStatus': _connectionStatus,
        };
      }

      return {
        'connected': true,
        'device': _connectedDevice!.name,
        'deviceAddress': _connectedDevice!.address,
        'status': 'Conectada y lista',
        'connectionStatus': _connectionStatus,
      };
    } catch (e) {
      return {
        'connected': false,
        'device': null,
        'status': 'Error: ${e.toString()}',
        'connectionStatus': 'Error',
      };
    }
  }

  static Future<bool> hasPrinterConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedPrinterAddress =
        prefs.getString(AppConstants.prefsSelectedPrinter) ?? '';
    return selectedPrinterAddress.isNotEmpty;
  }

  static Future<Map<String, dynamic>> checkBluetoothStatus() async {
    try {
      bool? isAvailable = await FlutterBluetoothSerial.instance.isAvailable;
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;

      return {
        'available': isAvailable ?? false,
        'enabled': isEnabled ?? false,
        'message': (isEnabled ?? false)
            ? 'Bluetooth disponible'
            : 'Bluetooth apagado',
      };
    } catch (e) {
      return {
        'available': false,
        'enabled': false,
        'message': 'Error verificando Bluetooth: $e',
      };
    }
  }

  static Future<void> showPrinterNotConfiguredMessage(
    BuildContext context,
    String message,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Configurar',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (builder) => ConfigPrinterScreen()),
            );
          },
        ),
      ),
    );
  }

  static Future<Map<String, dynamic>> connectAndlog(
    BluetoothDevice printerDevice,
    Product product,
    int front,
    int copies,
  ) async {
    final connectResult = await PrinterService.connectToPrinter(printerDevice);

    if (!connectResult['success']) {
      return {
        'success': false,
        'message': 'Error conectando: ${connectResult['message']}',
      };
    }

    final result = await PrinterService.printProductLabel(
      product,
      front,
      copies,
    );

    await disconnect();

    return result;
  }

  static Future<Map<String, String>> getPrinterInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      'address': prefs.getString(AppConstants.prefsSelectedPrinter) ?? '',
      'name': prefs.getString(AppConstants.prefsSelectedPrinterName) ?? '',
    };
  }

  static Future<BluetoothDevice?> getConfiguredPrinter() async {
    final printerInfo = await getPrinterInfo();
    final selectedPrinterAddress = printerInfo['address']!;
    final selectedPrinterName = printerInfo['name']!;

    if (selectedPrinterAddress.isEmpty) {
      return null;
    }

    return BluetoothDevice(
      name: selectedPrinterName,
      address: selectedPrinterAddress,
    );
  }
}
