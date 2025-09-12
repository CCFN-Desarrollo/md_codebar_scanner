import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

class PrinterService {
  static BluetoothDevice? _connectedDevice;
  static BluetoothCharacteristic? _characteristic;
  static bool _isConnected = false;
  static String _connectionStatus = '';

  /// Verifica y solicita permisos de Bluetooth
  static Future<bool> requestBluetoothPermissions() async {
    try {
      // Verificar si Bluetooth está disponible
      if (await FlutterBluePlus.isAvailable == false) {
        return false;
      }

      // Solicitar permisos
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();

      return statuses.values.every(
        (status) => status.isGranted || status.isPermanentlyDenied == false,
      );
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Escanea dispositivos Bluetooth disponibles
  static Future<List<BluetoothDevice>> scanForDevices() async {
    try {
      if (!await requestBluetoothPermissions()) {
        throw Exception('Permisos de Bluetooth denegados');
      }

      // Verificar si Bluetooth está encendido
      BluetoothAdapterState adapterState =
          await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth está apagado');
      }

      List<BluetoothDevice> devices = [];

      // Obtener dispositivos conectados
      List<BluetoothDevice> connectedDevices =
          await FlutterBluePlus.connectedDevices;
      devices.addAll(connectedDevices);

      // Escanear nuevos dispositivos
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

      // Escuchar resultados del escaneo
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (!devices.any((device) => device.id == result.device.id)) {
            devices.add(result.device);
          }
        }
      });

      await Future.delayed(Duration(seconds: 4));
      await FlutterBluePlus.stopScan();

      // Filtrar dispositivos que podrían ser impresoras
      return devices.where((device) {
        final name = device.name.toLowerCase();
        return name.isNotEmpty &&
            (name.contains('tsc') ||
                name.contains('alpha') ||
                name.contains('print') ||
                name.contains('thermal') ||
                device.name.length >
                    3 // Mostrar dispositivos con nombre
                    );
      }).toList();
    } catch (e) {
      print('Error scanning devices: $e');
      return [];
    }
  }

  /// Conecta a la impresora TSC Alpha-3RB
  static Future<Map<String, dynamic>> connectToPrinter(
    BluetoothDevice device,
  ) async {
    try {
      _connectionStatus = 'Conectando...';

      if (_isConnected) {
        await disconnect();
      }

      // Conectar al dispositivo
      await device.connect(timeout: Duration(seconds: 10));
      _connectedDevice = device;

      _connectionStatus = 'Descubriendo servicios...';

      // Descubrir servicios
      List<BluetoothService> services = await device.discoverServices();

      // Buscar característica para escribir datos (SPP - Serial Port Profile)
      BluetoothCharacteristic? writeCharacteristic;

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            break;
          }
        }
        if (writeCharacteristic != null) break;
      }

      if (writeCharacteristic == null) {
        await device.disconnect();
        return {
          'success': false,
          'message': 'No se encontró característica de escritura',
        };
      }

      _characteristic = writeCharacteristic;
      _isConnected = true;
      _connectionStatus = 'Conectado';

      // Enviar comando de inicialización
      await _sendRawData(_getTSCInitCommands());

      return {
        'success': true,
        'message': 'Conectado a ${device.name}',
        'device': device.name,
      };
    } catch (e) {
      _isConnected = false;
      _connectedDevice = null;
      _characteristic = null;
      _connectionStatus = 'Error de conexión';

      return {
        'success': false,
        'message': 'Error al conectar: ${e.toString()}',
      };
    }
  }

  /// Desconecta de la impresora
  static Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      print('Error al desconectar: $e');
    } finally {
      _connectedDevice = null;
      _characteristic = null;
      _isConnected = false;
      _connectionStatus = '';
    }
  }

  /// Verifica si está conectado a una impresora
  static bool get isConnected => _isConnected && _connectedDevice != null;

  /// Obtiene el dispositivo conectado
  static BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Obtiene el estado de conexión
  static String get connectionStatus => _connectionStatus;

  /// Imprime una etiqueta de producto usando comandos TSC
  static Future<Map<String, dynamic>> printProductLabel(Product product) async {
    try {
      if (!isConnected) {
        return {
          'success': false,
          'message': 'No hay conexión con la impresora',
        };
      }

      // Verificar que el dispositivo sigue conectado
      if (_connectedDevice?.isConnected != true) {
        _isConnected = false;
        return {'success': false, 'message': 'La impresora se ha desconectado'};
      }

      // Generar comandos TSC para la etiqueta
      String tscCommands = _generateTSCLabel(product);

      // Enviar comandos a la impresora
      await _sendRawData(tscCommands);

      return {'success': true, 'message': 'Etiqueta impresa correctamente'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al imprimir: ${e.toString()}',
      };
    }
  }

  /// Genera comandos TSC para crear la etiqueta del producto
  static String _generateTSCLabel(Product product) {
    final StringBuffer commands = StringBuffer();

    // Configuración de etiqueta de 58mm
    commands.writeln('CLS');
    commands.writeln(
      'SIZE ${AppConstants.labelWidth} mm, ${AppConstants.labelHeight} mm',
    );
    commands.writeln('GAP ${AppConstants.labelGap} mm, 0 mm');
    commands.writeln('DIRECTION 1,0');
    commands.writeln('REFERENCE 0,0');
    commands.writeln('OFFSET 0 mm');
    commands.writeln('SET PEEL OFF');
    commands.writeln('SET CUTTER OFF');
    commands.writeln('SET PARTIAL_CUTTER OFF');
    commands.writeln('SET TEAR ON');

    // Contenido de la etiqueta
    int yPos = 30;

    // Título del producto (fuente más grande)
    commands.writeln(
      'TEXT 20,$yPos,"TSS24.BF2",0,1,1,"${_truncateText(product.itemName, 20)}"',
    );
    yPos += 40;

    // Línea separadora
    commands.writeln('BAR 20,$yPos,350,2');
    yPos += 20;

    // Código de barras
    commands.writeln('BARCODE 20,$yPos,"128",60,1,0,2,2,"${product.codeBar}"');
    yPos += 80;

    // SKU debajo del código de barras
    commands.writeln(
      'TEXT 20,$yPos,"TSS24.BF2",0,1,1,"SKU: ${product.codeBar}"',
    );
    yPos += 30;

    // Precio base
    commands.writeln(
      'TEXT 20,$yPos,"TSS24.BF2",0,2,2,"\$${product.priceWithTax.toStringAsFixed(2)}"',
    );
    yPos += 40;

    // Información adicional
    /* if (product.discount > 0) {
      commands.writeln('TEXT 20,$yPos,"TSS24.BF2",0,1,1,"Descuento: ${product.discount}%"');
      yPos += 25;
      commands.writeln('TEXT 20,$yPos,"TSS24.BF2",0,1,1,"Total: \$${product.finalPrice.toStringAsFixed(2)}"');
      yPos += 25;
    }*/

    commands.writeln(
      'TEXT 20,$yPos,"TSS24.BF2",0,1,1,"Impuesto: ${product.taxRate}%"',
    );
    yPos += 25;

    // Footer
    commands.writeln(
      'TEXT 20,$yPos,"TSS24.BF2",0,1,1,"${AppConstants.printCompanyName}"',
    );

    // Imprimir etiqueta
    commands.writeln('PRINT 1,1');

    return commands.toString();
  }

  /// Trunca texto para que quepa en la etiqueta
  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Comandos de inicialización para impresora TSC
  static String _getTSCInitCommands() {
    return '''
SETUP
CLS
''';
  }

  /// Envía datos raw a la impresora
  static Future<void> _sendRawData(String data) async {
    if (_characteristic == null) {
      throw Exception('No hay característica de escritura disponible');
    }

    try {
      // Convertir string a bytes
      List<int> bytes = utf8.encode(data);

      // Enviar datos en chunks si es muy largo (máximo 20 bytes por chunk para compatibilidad)
      const int chunkSize = 20;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        List<int> chunk = bytes.sublist(i, end);

        await _characteristic!.write(chunk, withoutResponse: true);

        // Pequeño delay entre chunks para evitar overflow
        await Future.delayed(Duration(milliseconds: 10));
      }

      // Delay final para asegurar que se envíen todos los datos
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
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

      String testCommands =
          '''
CLS
SIZE ${AppConstants.labelWidth} mm, 30 mm
GAP ${AppConstants.labelGap} mm, 0 mm
TEXT 20,30,"TSS24.BF2",0,1,1,"PRUEBA DE IMPRESION"
TEXT 20,60,"TSS24.BF2",0,1,1,"TSC Alpha-3RB"
TEXT 20,90,"TSS24.BF2",0,1,1,"Conexion exitosa"
BARCODE 20,120,"128",40,1,0,2,2,"123456789"
TEXT 20,170,"TSS24.BF2",0,1,1,"SKU: 123456789"
TEXT 20,200,"TSS24.BF2",0,1,1,"flutter_blue_plus"
PRINT 1,1
''';

      await _sendRawData(testCommands);

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

      // Verificar si el dispositivo sigue conectado
      bool deviceConnected = _connectedDevice!.isConnected;

      if (!deviceConnected) {
        _isConnected = false;
        return {
          'connected': false,
          'device': _connectedDevice!.name,
          'status': 'Dispositivo desconectado',
          'connectionStatus': 'Desconectado',
        };
      }

      return {
        'connected': true,
        'device': _connectedDevice!.name,
        'deviceId': _connectedDevice!.id.toString(),
        'status': 'Conectada y lista',
        'connectionStatus': _connectionStatus,
        'hasWriteCharacteristic': _characteristic != null,
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

  /// Verifica si Bluetooth está disponible y encendido
  static Future<Map<String, dynamic>> checkBluetoothStatus() async {
    try {
      bool available = await FlutterBluePlus.isAvailable;
      if (!available) {
        return {
          'available': false,
          'enabled': false,
          'message': 'Bluetooth no está disponible en este dispositivo',
        };
      }

      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      bool enabled = state == BluetoothAdapterState.on;

      return {
        'available': true,
        'enabled': enabled,
        'state': state.toString(),
        'message': enabled ? 'Bluetooth disponible' : 'Bluetooth apagado',
      };
    } catch (e) {
      return {
        'available': false,
        'enabled': false,
        'message': 'Error verificando Bluetooth: $e',
      };
    }
  }
}
