import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:md_codebar_scanner/models/product_model.dart';
import 'package:md_codebar_scanner/services/zebra_print_service.dart';

Product _product({
  String name = 'COCA COLA 600ML',
  String code = '7501055300075',
}) {
  return Product.empty().copyWith(
    itemCode: 'A001',
    itemName: name,
    codeBar: code,
    priceWithTax: 18.5,
  );
}

void main() {
  final now = DateTime(2026, 9, 24);

  group('normalizeBaseUrl', () {
    test('agrega esquema y puerto por defecto', () {
      expect(
        ZebraPrintService.normalizeBaseUrl('192.168.0.10'),
        'http://192.168.0.10:8100',
      );
    });

    test('respeta el puerto y quita la ruta', () {
      expect(
        ZebraPrintService.normalizeBaseUrl(
          ' http://192.168.0.10:9000/print/zebra/ ',
        ),
        'http://192.168.0.10:9000',
      );
    });
  });

  group('validateUrl', () {
    test('rechaza vacío y localhost', () {
      expect(ZebraPrintService.validateUrl(''), isNotNull);
      expect(ZebraPrintService.validateUrl('localhost:8100'), isNotNull);
      expect(ZebraPrintService.validateUrl('127.0.0.1'), isNotNull);
    });

    test('acepta IP de la red', () {
      expect(ZebraPrintService.validateUrl('192.168.0.10:8100'), isNull);
    });
  });

  group('buildProductLabelZpl', () {
    test('genera etiqueta de 75 mm a 203 dpi con los datos del producto', () {
      final zpl = ZebraPrintService.buildProductLabelZpl(
        _product(),
        3,
        2,
        now: now,
      );

      expect(zpl.startsWith('^XA'), isTrue);
      expect(zpl.endsWith('^XZ'), isTrue);
      expect(zpl, contains('^PW600'));
      expect(zpl, contains('^LL240'));
      expect(zpl, contains('^FD\$ 18.50^FS'));
      expect(zpl, contains('^FDCOCA COLA 600ML^FS'));
      // EAN-13: 123 módulos x 3 = 369 dots, centrado en el área de 390
      expect(
        zpl,
        contains('^FO206,98^BY3^BCN,50,N,N,N,A^FH^FD7501055300075^FS'),
      );
      expect(zpl, contains('^FB390,1,0,C^A0N,26,22^FH^FD7501055300075^FS'));
      expect(zpl, contains('^FDF3  f 24/09/2026^FS'));
      expect(zpl, contains('^PQ2'));
    });

    test('divide la descripción en dos líneas respetando palabras', () {
      final zpl = ZebraPrintService.buildTestLabelZpl(now: now);

      expect(
        zpl,
        contains('^FO195,28^A0N,32,24^FH^FDdolor sit amet, consectetur^FS'),
      );
      expect(zpl, contains('^FO195,60^A0N,32,24^FH^FDadipiscing elit^FS'));
    });

    test('corta palabras sin espacios y agrega puntos suspensivos', () {
      final zpl = ZebraPrintService.buildProductLabelZpl(
        _product(name: 'A' * 30 + 'B' * 30 + 'C' * 10),
        1,
        1,
        now: now,
      );

      expect(zpl, contains('^FD${'A' * 30}^FS'));
      expect(zpl, contains('^FD${'B' * 27}...^FS'));
    });

    test('escapa caracteres de control ZPL', () {
      final zpl = ZebraPrintService.buildProductLabelZpl(
        _product(name: 'JUGO^LIMON~_2'),
        1,
        1,
        now: now,
      );

      expect(zpl, contains('^FDJUGO_5ELIMON_7E_5F2^FS'));
    });

    test('reduce el ancho de barra si el código es largo', () {
      final zpl = ZebraPrintService.buildProductLabelZpl(
        _product(code: 'ABC-1234567890-XYZ'),
        1,
        1,
        now: now,
      );
      expect(zpl, contains('^BY1^BCN'));
    });

    test('copias mínimas en 1', () {
      final zpl = ZebraPrintService.buildProductLabelZpl(
        _product(),
        1,
        0,
        now: now,
      );
      expect(zpl, contains('^PQ1'));
    });
  });

  group('sendZpl', () {
    test('envía JSON con el zpl y reporta éxito', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'ok': true,
            'mode': 'windows',
            'printer_name': 'ZDesigner ZD421-203dpi ZPL',
            'bytes_sent': 47,
          }),
          200,
        );
      });

      final result = await ZebraPrintService.sendZpl(
        '192.168.0.10',
        '^XA^XZ',
        client: client,
      );

      expect(captured.method, 'POST');
      expect(captured.url.toString(), 'http://192.168.0.10:8100/print/zebra');
      expect(captured.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(captured.body), {'zpl': '^XA^XZ'});
      expect(result['success'], isTrue);
      expect(result['printerName'], 'ZDesigner ZD421-203dpi ZPL');
    });

    test('propaga el mensaje de error del agente', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'ok': false,
            'error': {
              'code': 'PRINTER_OFFLINE',
              'message': 'Impresora apagada',
            },
          }),
          500,
        );
      });

      final result = await ZebraPrintService.sendZpl(
        '192.168.0.10',
        '^XA^XZ',
        client: client,
      );

      expect(result['success'], isFalse);
      expect(result['message'], 'Impresora apagada (PRINTER_OFFLINE)');
    });

    test('mensaje claro cuando la PC no responde', () async {
      final client = MockClient((_) async {
        throw const SocketException('Connection refused');
      });

      final result = await ZebraPrintService.sendZpl(
        '192.168.0.10',
        '^XA^XZ',
        client: client,
      );

      expect(result['success'], isFalse);
      expect(result['message'], contains('No se pudo contactar'));
    });
  });

  group('checkStatus', () {
    test('devuelve impresora y versión cuando agent_role es all', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'http://192.168.0.10:8100/status');
        return http.Response(
          jsonEncode({
            'ok': true,
            'version': '1.3.11',
            'agent_role': 'all',
            'config': {'zebra_default_printer_name': 'ZDesigner ZD421'},
          }),
          200,
        );
      });

      final result = await ZebraPrintService.checkStatus(
        '192.168.0.10',
        client: client,
      );

      expect(result['success'], isTrue);
      expect(result['printerName'], 'ZDesigner ZD421');
      expect(result['version'], '1.3.11');
    });

    test('falla si el agente no tiene rol zebra', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({'ok': true, 'agent_role': 'scanner'}),
          200,
        );
      });

      final result = await ZebraPrintService.checkStatus(
        '192.168.0.10',
        client: client,
      );

      expect(result['success'], isFalse);
      expect(result['message'], contains('agent_role: scanner'));
    });
  });
}
