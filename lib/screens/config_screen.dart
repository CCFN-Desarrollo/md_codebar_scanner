import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/printer_settings_card.dart';

class ConfigScreen extends StatefulWidget {
  final VoidCallback? onConfigSaved;

  const ConfigScreen({super.key, this.onConfigSaved});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _sucursalController =
      TextEditingController(); // Cambiado de dropdown a TextField
  bool _isSucursalFromLogin = false; // Indica si la sucursal viene del login
  // El servidor API ya no se configura aquí, se usa el de constants
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  final _printerSettingsKey = GlobalKey<PrinterSettingsCardState>();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _sucursalController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          // Cargar sucursal guardada
          String? savedSucursal = prefs.getString(AppConstants.prefsSucursal);

          // Verificar si la sucursal viene del login (warehouseCode)
          String? warehouseCode = prefs.getString('warehouseCode');
          warehouseCode = warehouseCode == 'S00' ? '' : warehouseCode;

          if (warehouseCode != null && warehouseCode.isNotEmpty) {
            // Sucursal viene del login - no es modificable
            _sucursalController.text = warehouseCode;
            _isSucursalFromLogin = true;
          } else if (savedSucursal != null && savedSucursal.isNotEmpty) {
            // Sucursal guardada previamente - es modificable
            _sucursalController.text = savedSucursal;
            _isSucursalFromLogin = false;
          }

          // El servidor API se toma de constants, no se carga de prefs

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error al cargar la configuración', AppColors.error);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que haya una sucursal ingresada
    if (_sucursalController.text.trim().isEmpty) {
      _showSnackBar('Por favor ingresa la sucursal', AppColors.warning);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Guardar sucursal ingresada
      await prefs.setString(
        AppConstants.prefsSucursal,
        _sucursalController.text.trim(),
      );

      // Guardar el servidor API por defecto de constants
      await prefs.setString(
        AppConstants.prefsServidor,
        AppConstants.defaultServerApi,
      );

      // Guardar configuración de impresora
      await _printerSettingsKey.currentState?.save(prefs);

      setState(() {
        _isSaving = false;
      });

      _showSnackBar(AppConstants.successConfigSaved, AppColors.success);

      if (widget.onConfigSaved != null) {
        widget.onConfigSaved!(); // ← Ejecuta inmediatamente al guardar
      }

      // Regresar a la pantalla anterior después de guardar
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showSnackBar('Error al guardar la configuración', AppColors.error);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String? _validateSucursal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La sucursal es requerida';
    }
    if (value.trim().length < 2) {
      return 'La sucursal debe tener al menos 2 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading || _isSaving ? null : _loadConfig,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando configuración...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.settings,
                                size: 48,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Configuración del Sistema',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Configura los parámetros necesarios para el funcionamiento de la aplicación',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),

                        // Campo Sucursal (TextField)
                        Text(
                          'Información de Sucursal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12),

                        Container(
                          decoration: BoxDecoration(
                            color: _isSucursalFromLogin
                                ? Colors.grey[100]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _sucursalController,
                            enabled: !_isSaving && !_isSucursalFromLogin,
                            validator: _validateSucursal,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: _isSucursalFromLogin
                                  ? Colors.grey[100]
                                  : Colors.white,
                              labelText: 'Sucursal',
                              hintText: _isSucursalFromLogin
                                  ? 'Sucursal del login'
                                  : 'Ej: S11, S16, S06',
                              prefixIcon: Icon(
                                _isSucursalFromLogin ? Icons.lock : Icons.store,
                                color: _isSucursalFromLogin
                                    ? Colors.grey[600]
                                    : AppColors.primary,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: _isSucursalFromLogin
                                  ? Colors.grey[700]
                                  : AppColors.textPrimary,
                              fontWeight: _isSucursalFromLogin
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),

                        SizedBox(height: 32),

                        // NUEVA SECCIÓN: Configuración de Impresora
                        Text(
                          'Configuración de Impresora',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12),
                        PrinterSettingsCard(
                          key: _printerSettingsKey,
                          enabled: !_isSaving,
                        ),

                        SizedBox(height: 32),

                        // Información de ayuda
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.info,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Información Importante',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• La sucursal asignada en CRM es con la que se utilizará para revisar precios\n'
                                '• La impresora debe estar emparejada por Bluetooth previamente\n'
                                '• URL servidor API : ${AppConstants.defaultServerApi}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.info,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40),

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _saveConfig,
                                  icon: _isSaving
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Icon(Icons.save),
                                  label: Text(
                                    _isSaving
                                        ? 'Guardando...'
                                        : 'Guardar Configuración',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    disabledBackgroundColor: AppColors.primary
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Estado de configuración actual
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
