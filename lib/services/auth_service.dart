import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:md_codebar_scanner/utils/storage_helper.dart';
import '../models/login_model.dart';
import '../utils/constants.dart';

class AuthService {
  /// Realiza el login con el API
  /// Retorna un mapa con 'success' (bool) y 'message' o 'data' (LoginResponse)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    String baseApiUrl = await StorageHelper.getServidor();
    try {
      final url = Uri.parse('${baseApiUrl}${AppConstants.loginEndpoint}');

      log('🔵 Intentando login a: $url');
      log('📧 Email: $email');

      final headers = {
        'accept': 'text/plain',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({'Email': email, 'Password': password});

      log('📤 Enviando petición...');

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Tiempo de espera agotado');
            },
          );

      log('📥 Respuesta recibida - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        log('✅ Login exitoso');

        final jsonResponse = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(jsonResponse);

        log('👤 Usuario: ${loginResponse.appLogin.name}');
        log('🏪 Sucursal: ${loginResponse.warehouseCode}');
        log('🔑 Token recibido');

        return {
          'success': true,
          'data': loginResponse,
          'message': 'Login exitoso',
        };
      } else if (response.statusCode == 401) {
        log('❌ Credenciales inválidas');
        return {
          'success': false,
          'message': 'Usuario o contraseña incorrectos',
        };
      } else if (response.statusCode == 400) {
        log('❌ Petición inválida');

        try {
          final errorResponse = response.body;

          'Datos de login inválidos';
          return {'success': false, 'message': errorResponse};
        } catch (e) {
          return {'success': false, 'message': 'Datos de login inválidos'};
        }
      } else {
        log('❌ Error del servidor: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Error del servidor (${response.statusCode})',
        };
      }
    } catch (e) {
      log('❌ Error en login: $e');

      String errorMessage = 'Error de conexión';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage = 'No se puede conectar al servidor';
      } else if (e.toString().contains('Tiempo de espera')) {
        errorMessage = 'Tiempo de espera agotado';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Respuesta inválida del servidor';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  /// Verifica si un token es válido (puedes implementar validación adicional)
  static bool isTokenValid(String? token) {
    if (token == null || token.isEmpty) {
      return false;
    }

    // Aquí podrías agregar validación JWT si lo necesitas
    // Por ahora, solo verificamos que exista
    return true;
  }

  /// Decodifica información básica del token JWT (sin validar firma)
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decodificar el payload (segunda parte)
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));

      return jsonDecode(decoded);
    } catch (e) {
      log('Error decodificando token: $e');
      return null;
    }
  }
}
