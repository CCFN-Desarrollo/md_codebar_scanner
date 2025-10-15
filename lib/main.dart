import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/screens/login_screen.dart';
import 'package:md_codebar_scanner/screens/main_screen.dart';
import 'package:md_codebar_scanner/services/app_update_service.dart';
import 'package:md_codebar_scanner/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escáner de Código de Barras..',
      theme: AppTheme.lightTheme,
      home: SplashScreen(), // Pantalla de carga inicial
      debugShowCheckedModeBanner: false,
    );
  }
}

// Pantalla de splash que verifica el estado de login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Pequeña pausa para mostrar el splash
    await Future.delayed(Duration(milliseconds: 500));

    // PRIMERO: Verificar si hay actualizaciones
    final updateResult = await AppUpdateService.checkForUpdate();

    if (updateResult['success'] && updateResult['hasUpdate']) {
      // HAY ACTUALIZACIÓN DISPONIBLE
      if (mounted) {
        await AppUpdateService.showUpdateDialog(
          context,
          updateResult['currentVersion'],
          updateResult['serverVersion'],
        );
      }
    }

    // SEGUNDO: Verificar login (solo si no se está actualizando)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      if (isLoggedIn) {
        // Usuario ya logueado, ir a MainScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        // Usuario no logueado, ir a LoginScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o icono
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      spreadRadius: 5,
                      blurRadius: 20,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: Color(0xFF1976D2),
                ),
              ),
              SizedBox(height: 32),
              // Indicador de carga
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
