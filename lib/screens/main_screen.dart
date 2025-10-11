import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'password_screen.dart';
import 'scanner_screen.dart';
import '../utils/colors.dart';
import 'package:material_symbols_icons/symbols.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isCheckingConfig = true;
  bool _hasValidConfig = false;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration({bool showDialogIfNeeded = true}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      final sucursal = prefs.getString(AppConstants.prefsSucursal) ?? '';
      final servidor = prefs.getString(AppConstants.prefsServidor) ?? '';

      final hasValidConfig =
          sucursal.trim().isNotEmpty && servidor.trim().isNotEmpty;

      if (mounted) {
        setState(() {
          _hasValidConfig = hasValidConfig;
          _isCheckingConfig = false; // Termina la verificación
        });

        /*if (hasValidConfig) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToScanner();
          });
        }*/
      }
    } catch (e) {
      // Manejo de errores
      if (mounted) {
        setState(() {
          _hasValidConfig = false;
          _isCheckingConfig = false;
        });

        // También mostrar dialog en caso de error
        await Future.delayed(Duration(milliseconds: 1500));
        if (mounted) {
          _showConfigurationRequired();
        }
      }
    }
  }

  Future<void> _recheckConfigurationSilently() async {
    await _checkConfiguration(showDialogIfNeeded: false);
  }

  // Dialog que se muestra cuando falta configuración
  void _showConfigurationRequired() {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.settings, color: AppColors.warning, size: 24),
              SizedBox(width: 12),
              Text('Configuración Requerida'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para usar la aplicación es necesario configurar:',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              SizedBox(height: 12),

              // Lista de elementos requeridos
              Row(
                children: [
                  Icon(Icons.store, color: AppColors.primary, size: 16),
                  SizedBox(width: 8),
                  Text('Sucursal'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.cloud, color: AppColors.primary, size: 16),
                  SizedBox(width: 8),
                  Text('Servidor API'),
                ],
              ),
              SizedBox(height: 16),

              // Información adicional
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Serás redirigido a la pantalla de configuración.',
                        style: TextStyle(fontSize: 12, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar dialog
                // Navegar a configuración
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PasswordScreen(
                      onConfigSaved: () {
                        _checkConfiguration(); // ← Actualiza MainScreen inmediatamente
                      },
                    ),
                  ),
                ).then((_) {
                  // ← Al regresar, verificar configuración nuevamente
                  _recheckConfigurationSilently();
                });
              },
              icon: Icon(Icons.arrow_forward),
              label: Text('Configurar'),
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

  // Widget build que usa los estados
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanner de código de barras'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PasswordScreen(
                    onConfigSaved: () {
                      _checkConfiguration(); // ← Actualiza MainScreen inmediatamente
                    },
                  ),
                ),
              ).then((_) {
                // ← Verificar configuración al regresar del settings manual
                _checkConfiguration();
              });
            },
          ),
        ],
      ),
      body: _isCheckingConfig ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  // Pantalla de carga mientras verifica
  Widget _buildLoadingScreen() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.white],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono con animación
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 30),

          // Indicador de progreso
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 20),

          // Mensaje de estado
          Text(
            'Verificando configuración...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.white],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo/Icono principal
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: _hasValidConfig
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hasValidConfig
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.warning.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              _hasValidConfig ? Icons.qr_code_scanner : Icons.warning_amber,
              size: 80,
              color: _hasValidConfig ? AppColors.primary : AppColors.warning,
            ),
          ),

          SizedBox(height: 30),

          // Título principal
          Text(
            _hasValidConfig
                ? 'Escáner de Código de Barras'
                : 'Configuración Pendiente',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _hasValidConfig ? AppColors.primary : AppColors.warning,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 10),

          // Subtítulo
          Text(
            _hasValidConfig
                ? ''
                : 'Configura la sucursal y servidor API\npara continuar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 50),

          // Botones principales
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                if (_hasValidConfig) ...[
                  // Botón principal de escanear
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScannerScreen(),
                          ),
                        );
                      },
                      icon: Icon(Symbols.atr, size: 24),
                      label: Text(
                        'Escanear Producto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Botón para ir a configuración
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PasswordScreen(
                              onConfigSaved: () {
                                _checkConfiguration(); // Actualiza MainScreen inmediatamente
                              },
                            ),
                          ),
                        ).then((_) {
                          _checkConfiguration();
                        });
                      },
                      icon: Icon(Icons.settings, size: 24),
                      label: Text(
                        'Ir a Configuración',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: AppColors.warning.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 60),

          // Información adicional
          if (!_hasValidConfig)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 40),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _hasValidConfig
                    ? Colors.grey[50]
                    : AppColors.warningLight,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _hasValidConfig
                      ? Colors.grey[200]!
                      : AppColors.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasValidConfig
                        ? Icons.info_outline
                        : Icons.warning_amber_outlined,
                    color: _hasValidConfig
                        ? Colors.grey[600]
                        : AppColors.warning,
                    size: 24,
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasValidConfig
                              ? '¿Cómo usar?'
                              : 'Configuración requerida',
                          style: TextStyle(
                            fontSize: AppConstants.titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: _hasValidConfig
                                ? Colors.grey[800]
                                : AppColors.warning,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          _hasValidConfig
                              ? 'Presiona "Escanear" para usar la cámara o "Entrada Manual" para escribir el código'
                              : 'Es necesario configurar la sucursal y servidor API antes de usar la aplicación',
                          style: TextStyle(
                            fontSize: AppConstants.subtitleFontSize,
                            color: _hasValidConfig
                                ? Colors.grey[600]
                                : AppColors.warning,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
