import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class AppUpdateService {
  final String _apkDownloadUrl =
      'http://crm.ccfnweb.com.mx/sap10/md_codebar_scanner.apk'; // Replace with your actual APK download URL
  final String _versionCheckUrl =
      'http://crm.ccfnweb.com.mx/sap10/MD_CODEBAR_SCANNER_VERSION.text'; // Replace with your actual version check URL

  Future<bool> checkForUpdate() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(_versionCheckUrl));
      if (response.statusCode == 200) {
        String latestVersion = response.body.trim();
        return _isNewVersionAvailable(currentVersion, latestVersion);
      }
    } catch (e) {
      print('Error checking for update: $e');
    }
    return false;
  }

  bool _isNewVersionAvailable(String currentVersion, String latestVersion) {
    List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
    List<int> latestParts = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i < currentParts.length) {
        if (latestParts[i] > currentParts[i]) {
          return true;
        }
        if (latestParts[i] < currentParts[i]) {
          return false;
        }
      } else {
        // If latest version has more parts, and they are not zero, then it's a newer version
        if (latestParts[i] > 0) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> downloadAndInstallApk(BuildContext context) async {
    try {
      // Request permission to install unknown apps (Android 8.0+)
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          _showPermissionDeniedDialog(context);
          return;
        }
      }

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _showErrorDialog(
          context,
          'No se pudo acceder al almacenamiento externo.',
        );
        return;
      }

      final filePath = '${directory.path}/app_update.apk';
      final response = await http.get(Uri.parse(_apkDownloadUrl));

      if (response.statusCode == 200) {
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        await OpenFilex.open(filePath);
      } else {
        _showErrorDialog(
          context,
          'Error al descargar el APK: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showErrorDialog(context, 'Error al descargar e instalar el APK: $e');
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permiso Denegado'),
          content: const Text(
            'Por favor, concede permiso para instalar aplicaciones de fuentes desconocidas para actualizar la aplicación.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Configuración'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
