import 'dart:developer';

import 'package:package_info_plus/package_info_plus.dart';

/// Version instalada de la app, leida una sola vez al arrancar (ver main()).
///
/// En los builds de CD la version sale del tag (v2.0.3 -> 2.0.3) y el build
/// number es 100 + numero de ejecucion del workflow.
class AppInfo {
  AppInfo._();

  static String _version = '';
  static String _buildNumber = '';

  static String get version => _version;
  static String get buildNumber => _buildNumber;

  /// Texto para el header: "v2.0.3 (105)". Vacio si no se pudo leer.
  static String get label {
    if (_version.isEmpty) return '';
    return _buildNumber.isEmpty ? 'v$_version' : 'v$_version ($_buildNumber)';
  }

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      set(version: info.version, buildNumber: info.buildNumber);
    } catch (e) {
      log('No se pudo leer la version de la app: $e');
    }
  }

  /// Asigna los valores directamente (lo usa load() y las pruebas).
  static void set({required String version, String buildNumber = ''}) {
    _version = version.trim();
    _buildNumber = buildNumber.trim();
  }
}
