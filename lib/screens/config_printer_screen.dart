import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/printer_settings_card.dart';

class ConfigPrinterScreen extends StatefulWidget {
  final VoidCallback? onConfigSaved;

  const ConfigPrinterScreen({super.key, this.onConfigSaved});

  @override
  State<ConfigPrinterScreen> createState() => _ConfigPrinterScreenState();
}

class _ConfigPrinterScreenState extends State<ConfigPrinterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _printerSettingsKey = GlobalKey<PrinterSettingsCardState>();
  bool _isSaving = false;

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Guardar configuración de impresora
      await _printerSettingsKey.currentState?.save(prefs);

      setState(() {
        _isSaving = false;
      });

      _showSnackBar(AppConstants.successConfigSaved, AppColors.success);

      /*if (widget.onConfigSaved != null) {
        widget.onConfigSaved!(); // ← Ejecuta inmediatamente al guardar
      }*/

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
        centerTitle: true,
        elevation: 0,
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
        child: SafeArea(
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
                          'Configuración de Impresora',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Selecciona la impresora y haz tu prueba',
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

                  // Botones de acción
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveConfig,
                      icon: _isSaving
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(Icons.save),
                      label: Text(
                        _isSaving ? 'Guardando...' : 'Guardar Configuración',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
