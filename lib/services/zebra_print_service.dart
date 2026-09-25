import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

/// Impresión de etiquetas ZPL por medio del Scanner Agent
/// (`POST <url>/print/zebra`), instalado en la PC de cada tienda.
class ZebraPrintService {
  // Etiqueta de 75 mm de ancho a 203 dpi (8 dots/mm). El alto se deja en
  // 30 mm para no recortar la fecha, que va justo arriba de la franja azul.
  static const int labelWidthDots = 600;
  static const int labelHeightDots = 240;
  static const int maxCharsPerLine = 30;

  // Área blanca a la derecha del precio / logo preimpreso
  static const int rightAreaX = 195;
  static const int rightAreaWidth = 390;

  /// Normaliza lo que captura el usuario a `http://host:puerto`.
  /// Acepta "192.168.0.10", "192.168.0.10:8100" o la URL completa de /print/zebra.
  static String normalizeBaseUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return '';

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;

    final port = uri.hasPort ? uri.port : AppConstants.defaultPrintServicePort;
    return '${uri.scheme}://${uri.host}:$port';
  }

  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La URL del servicio es requerida';
    }
    final uri = Uri.tryParse(normalizeBaseUrl(value));
    if (uri == null || uri.host.isEmpty) {
      return 'URL inválida. Ej: 192.168.0.10:8100';
    }
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return 'Use la IP de la PC en la red, no localhost';
    }
    return null;
  }

  static String buildProductLabelZpl(
    Product product,
    int front,
    int copies, {
    DateTime? now,
  }) {
    final date = DateFormat('dd/MM/yyyy').format(now ?? DateTime.now());
    final price = '\$ ${product.priceWithTax.toStringAsFixed(2)}';

    return _buildLabel(
      price: price,
      description: product.itemName,
      barcode: product.codeBar,
      footer: 'F$front  f $date',
      copies: copies,
    );
  }

  static String buildTestLabelZpl({DateTime? now}) {
    final date = DateFormat('dd/MM/yyyy').format(now ?? DateTime.now());
    return _buildLabel(
      price: '\$ 0.00',
      description: 'dolor sit amet, consectetur adipiscing elit',
      barcode: '1234567890',
      footer: 'F1  f $date',
      copies: 1,
    );
  }

  static String _buildLabel({
    required String price,
    required String description,
    required String barcode,
    required String footer,
    required int copies,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('^XA');
    buffer.writeln('^CI28'); // UTF-8 (acentos, ñ)
    buffer.writeln('^PW$labelWidthDots');
    buffer.writeln('^LL$labelHeightDots');
    buffer.writeln('^LH0,0');

    // Precio grande; arriba del logo preimpreso "Precio SuperChivas"
    buffer.writeln('^FO10,30^A0N,90,40^FH^FD${_escape(price)}^FS');

    // Descripción en máximo dos líneas
    final lines = _splitTwoLines(description, maxCharsPerLine);
    for (var i = 0; i < lines.length; i++) {
      buffer.writeln(
        '^FO$rightAreaX,${28 + i * 32}^A0N,32,24^FH^FD${_escape(lines[i])}^FS',
      );
    }

    // Código de barras Code128 lo más ancho posible, centrado en el área blanca
    final module = _barcodeModule(barcode);
    final barcodeWidth = _code128Modules(barcode) * module;
    final barcodeX =
        rightAreaX +
        ((rightAreaWidth - barcodeWidth) / 2).round().clamp(0, 999);
    buffer.writeln(
      '^FO$barcodeX,98^BY$module^BCN,50,N,N,N,A^FH^FD${_escape(barcode)}^FS',
    );

    // Número del código legible, centrado bajo las barras
    buffer.writeln(
      '^FO$rightAreaX,152^FB$rightAreaWidth,1,0,C^A0N,26,22^FH^FD${_escape(barcode)}^FS',
    );

    // Frente y fecha alineados a la derecha
    buffer.writeln(
      '^FO$rightAreaX,185^FB$rightAreaWidth,1,0,R^A0N,24,20^FH^FD${_escape(footer)}^FS',
    );

    buffer.writeln('^PQ${copies < 1 ? 1 : copies}');
    buffer.write('^XZ');
    return buffer.toString();
  }

  /// Módulos aproximados de un Code128 en modo automático
  /// (subset C para dígitos: 2 dígitos por símbolo).
  static int _code128Modules(String data) {
    final digitsOnly = RegExp(r'^\d+$').hasMatch(data);
    final symbols = digitsOnly
        ? data.length ~/ 2 + (data.length.isOdd ? 2 : 0)
        : data.length;
    // start + datos + dígito verificador (11 c/u) + stop (13)
    return 11 * (symbols + 2) + 13;
  }

  /// Ancho de barra (dots) más grande con el que el código cabe en el área.
  static int _barcodeModule(String data) {
    final modules = _code128Modules(data);
    for (final module in [3, 2]) {
      if (modules * module <= rightAreaWidth) return module;
    }
    return 1;
  }

  /// Divide en dos líneas cortando en el último espacio que quepa;
  /// si no hay espacio razonable, corta la palabra.
  static List<String> _splitTwoLines(String text, int maxChars) {
    text = text.trim();
    if (text.length <= maxChars) return [text];

    var cut = text.lastIndexOf(' ', maxChars);
    if (cut < maxChars ~/ 2) cut = maxChars;

    final firstLine = text.substring(0, cut).trimRight();
    var secondLine = text.substring(cut).trimLeft();
    if (secondLine.length > maxChars) {
      secondLine = '${secondLine.substring(0, maxChars - 3).trimRight()}...';
    }
    return [firstLine, secondLine];
  }

  /// Escapa los caracteres de control de ZPL usando ^FH (indicador '_').
  static String _escape(String text) {
    return text
        .replaceAll('_', '_5F')
        .replaceAll('^', '_5E')
        .replaceAll('~', '_7E');
  }

  static Future<Map<String, dynamic>> sendZpl(
    String baseUrl,
    String zpl, {
    http.Client? client,
  }) async {
    final url =
        '${normalizeBaseUrl(baseUrl)}${AppConstants.printZebraEndpoint}';
    final httpClient = client ?? http.Client();

    try {
      log('Enviando ZPL a $url (${zpl.length} caracteres)');

      final response = await httpClient
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'zpl': zpl}),
          )
          .timeout(Duration(seconds: AppConstants.printServiceTimeout));

      final data = _decodeJson(response.body);

      if (data != null && data['ok'] == true) {
        final printerName = data['printer_name']?.toString() ?? 'Zebra';
        return {
          'success': true,
          'message': 'Etiqueta enviada a $printerName',
          'printerName': printerName,
          'bytesSent': data['bytes_sent'],
        };
      }

      return {
        'success': false,
        'message': _errorMessage(data, response.statusCode),
      };
    } on TimeoutException {
      return {'success': false, 'message': _unreachableMessage(baseUrl)};
    } on SocketException {
      return {'success': false, 'message': _unreachableMessage(baseUrl)};
    } on http.ClientException catch (e) {
      log('Error HTTP imprimiendo: $e');
      return {'success': false, 'message': _unreachableMessage(baseUrl)};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al imprimir: ${e.toString()}',
      };
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Consulta GET /status y valida que el agente tenga habilitada la impresión Zebra.
  static Future<Map<String, dynamic>> checkStatus(
    String baseUrl, {
    http.Client? client,
  }) async {
    final url =
        '${normalizeBaseUrl(baseUrl)}${AppConstants.printStatusEndpoint}';
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient
          .get(Uri.parse(url), headers: {'accept': '*/*'})
          .timeout(Duration(seconds: AppConstants.printServiceTimeout));

      final data = _decodeJson(response.body);

      if (data == null || data['ok'] != true) {
        return {
          'success': false,
          'message': _errorMessage(data, response.statusCode),
        };
      }

      final role = data['agent_role']?.toString() ?? '';
      if (role != 'zebra' && role != 'all') {
        return {
          'success': false,
          'message':
              'El agente no tiene habilitada la impresión Zebra (agent_role: $role)',
        };
      }

      final config = data['config'];
      final printerName = config is Map
          ? config['zebra_default_printer_name']?.toString() ?? ''
          : '';

      return {
        'success': true,
        'message': 'Servicio disponible',
        'version': data['version']?.toString() ?? '',
        'printerName': printerName,
      };
    } on TimeoutException {
      return {'success': false, 'message': _unreachableMessage(baseUrl)};
    } on SocketException {
      return {'success': false, 'message': _unreachableMessage(baseUrl)};
    } on http.ClientException catch (e) {
      log('Error HTTP verificando servicio: $e');
      return {'success': false, 'message': _unreachableMessage(baseUrl)};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error verificando servicio: ${e.toString()}',
      };
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Map<String, dynamic>? _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String _errorMessage(Map<String, dynamic>? data, int statusCode) {
    final error = data?['error'];
    if (error is Map && error['message'] != null) {
      final code = error['code'] != null ? ' (${error['code']})' : '';
      return '${error['message']}$code';
    }
    return 'El servicio de impresión respondió con error (HTTP $statusCode)';
  }

  static String _unreachableMessage(String baseUrl) {
    return 'No se pudo contactar el servicio de impresión en '
        '${normalizeBaseUrl(baseUrl)}. Verifique que la PC esté encendida '
        'y en la misma red WiFi.';
  }
}
