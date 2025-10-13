import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/screens/main_screen.dart';
import 'package:md_codebar_scanner/services/app_update_service.dart';
import 'package:md_codebar_scanner/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkAppUpdate();
  }

  Future<void> _checkAppUpdate() async {
    final appUpdateService = AppUpdateService();
    bool updateAvailable = await appUpdateService.checkForUpdate();
    if (updateAvailable) {
      // Show a dialog to the user to inform about the update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateDialog();
      });
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Actualización Disponible'),
          content: const Text(
            'Hay una nueva versión de la aplicación disponible. ¿Deseas actualizar ahora?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Actualizar'),
              onPressed: () {
                Navigator.of(context).pop();
                AppUpdateService().downloadAndInstallApk(context);
              },
            ),
            TextButton(
              child: const Text('Más tarde'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escanner de Código de Barras',
      theme: AppTheme.lightTheme,
      home: MainScreen(),
    );
  }
}
