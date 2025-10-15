import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../utils/colors.dart';

class AppUpdateService {
  static const String _versionUrl =
      'http://crm.ccfnweb.com.mx/sap10/MD_CODEBAR_SCANNER_VERSION.text';
  static const String _apkUrl =
      'http://crm.ccfnweb.com.mx/sap10/md_codebar_scanner.apk';

  /// Verifica si hay actualización disponible
  static Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      log('🔵 Verificando actualizaciones...');

      // Obtener versión actual
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      log('📱 Versión actual: $currentVersion');

      // Consultar versión en servidor
      log('📡 Consultando: $_versionUrl');
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout');
            },
          );

      if (response.statusCode == 200) {
        final serverVersion = response.body.trim();
        log('✅ Versión en servidor: $serverVersion');

        // Comparar versiones
        final needsUpdate = _isNewVersionAvailable(
          currentVersion,
          serverVersion,
        );

        if (needsUpdate) {
          log('🎉 Actualización disponible: $currentVersion → $serverVersion');
          return {
            'success': true,
            'hasUpdate': true,
            'currentVersion': currentVersion,
            'serverVersion': serverVersion,
          };
        } else {
          log('✅ Versión actualizada');
          return {
            'success': true,
            'hasUpdate': false,
            'currentVersion': currentVersion,
            'serverVersion': serverVersion,
          };
        }
      } else {
        log('❌ Error del servidor: ${response.statusCode}');
        return {
          'success': false,
          'hasUpdate': false,
          'error': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      log('❌ Error verificando actualización: $e');
      return {'success': false, 'hasUpdate': false, 'error': e.toString()};
    }
  }

  /// Compara dos versiones en formato semántico (MAJOR.MINOR.PATCH)
  static bool _isNewVersionAvailable(String current, String server) {
    try {
      log('🔍 Comparando versiones: "$current" vs "$server"');

      // Limpiar espacios y caracteres extraños
      current = current.trim();
      server = server.trim();

      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> serverParts = server.split('.').map(int.parse).toList();

      log('🔍 Current parts: $currentParts');
      log('🔍 Server parts: $serverParts');

      // Asegurar que ambas listas tengan la misma longitud
      while (currentParts.length < serverParts.length) {
        currentParts.add(0);
      }
      while (serverParts.length < currentParts.length) {
        serverParts.add(0);
      }

      // Comparar cada parte
      for (int i = 0; i < serverParts.length; i++) {
        log('🔍 Posición $i: ${serverParts[i]} vs ${currentParts[i]}');

        if (serverParts[i] > currentParts[i]) {
          log(
            '✅ ${serverParts[i]} > ${currentParts[i]} = ACTUALIZACIÓN DISPONIBLE',
          );
          return true;
        } else if (serverParts[i] < currentParts[i]) {
          log('❌ ${serverParts[i]} < ${currentParts[i]} = VERSIÓN MENOR');
          return false;
        }
        // Si son iguales, continuar con la siguiente parte
        log('➡️ ${serverParts[i]} == ${currentParts[i]} = CONTINUAR');
      }

      log('✅ Todas las partes son iguales = MISMA VERSIÓN');
      return false;
    } catch (e) {
      log('❌ Error comparando versiones: $e');
      return false;
    }
  }

  /// Muestra el diálogo de actualización
  static Future<void> showUpdateDialog(
    BuildContext context,
    String currentVersion,
    String serverVersion,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.system_update, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Text('Actualización Disponible'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hay una nueva versión de la aplicación disponible.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          currentVersion,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Actual',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.primary,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          serverVersion,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Nueva',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se descargará e instalará la nueva versión',
                        style: TextStyle(fontSize: 12, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: Text('Más Tarde'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _downloadAndInstallApk(context);
              },
              icon: Icon(Icons.download),
              label: Text('Actualizar Ahora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Descarga e instala el APK
  static Future<void> _downloadAndInstallApk(BuildContext context) async {
    try {
      log('📥 Iniciando descarga del APK...');

      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Descargando actualización...'),
                SizedBox(height: 8),
                Text(
                  'Por favor espera',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      );

      // Obtener directorio temporal
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('No se pudo acceder al almacenamiento');
      }

      // Ruta donde se guardará el APK
      final filePath = '${directory.path}/md_codebar_scanner_update.apk';
      log('💾 Guardando en: $filePath');

      // Descargar el APK
      final response = await http.get(Uri.parse(_apkUrl));

      if (response.statusCode == 200) {
        // Guardar el archivo
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        log('✅ APK descargado: ${response.bodyBytes.length} bytes');

        // Cerrar diálogo de progreso
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Abrir el APK para instalación
        log('📦 Abriendo APK para instalación...');
        final result = await OpenFilex.open(filePath);

        log('✅ Resultado: ${result.type} - ${result.message}');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'APK descargado. Por favor, instálalo para actualizar.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error descargando APK: $e');

      // Cerrar diálogo si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
